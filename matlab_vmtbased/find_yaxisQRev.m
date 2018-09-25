function [fig_extrap_handle,fig_table_handle] =  find_yaxisQRev()


% % Get a list of files to work with
% dname = uigetdir(pwd,'Select directory containing QRev files (will search recursively):');
% [~,~,QRevFiles] = dirr([dname filesep '*QRev*'],'name');
% [~, ~, ext] = cellfun(@fileparts, QRevFiles, 'UniformOutput', 0);
% idx = find(cellfun(@(x)strcmp(x,'.mat'),ext));
% QRevFiles = QRevFiles(idx);
% numFiles = numel(QRevFiles);

%Prompt to load a QRev file
[filename,pathname] = ...
    uigetfile({'*.mat','MAT-files (*.mat)'}, ...
    'Select QRev MAT File', ...
    pwd, 'MultiSelect','off');

if ischar(filename) % Single MAT file loaded
    QRevFiles = {fullfile(pathname,filename)};
end

hwait = waitbar(0,['Processing 1 of ' num2str(1) ' measurements'] );
wstep = floor(1/(1)); wcount = 0;


% Load each QRev result, create obj, process
for zi = 1%:numFiles
    try
        load(QRevFiles{zi})
        meas=clsMeasurement();
        meas = loadQRev(meas,meas_struct);
        uncertainty=meas.uncertainty;
        discharge=meas.discharge;
        nTransects=length(meas.transects);
        checked=logical([meas.transects.checked]);
        first=find(checked==1,1,'first');
        last=find(checked==1,1,'last');
        settings=clsMeasurement.currentSettings(meas);
        
        % Reference
        switch settings.NavRef
            case 'btVel'; navRef = 'BT';
            case 'btVelmbc'; navRef = 'BT-mbc';  % Not used, the result should include mbc if valid
            case 'ggaVel'; navRef = 'GGA';
            case 'vtgVel'; navRef = 'VTG';
        end
        
        % Assign variables from normData
        q_rawnorm=meas.extrapFit.normData(1,end).unitNormalized;
        z_rawnorm=meas.extrapFit.normData(1,end).cellDepthNormalized; z_rawnorm=1-z_rawnorm;
        unitNormMed=meas.extrapFit.normData(1,end).unitNormalizedMed;
        avgz=meas.extrapFit.normData(1,end).unitNormalizedz;
        unitNormNo=meas.extrapFit.normData(1,end).unitNormalizedNo;
        unit25=meas.extrapFit.normData(1,end).unitNormalized25;
        unit75=meas.extrapFit.normData(1,end).unitNormalized75;
        datatype=meas.extrapFit.normData(1,end).dataType;
        validData=meas.extrapFit.normData(1,end).validData;
        
        % Characteristics
        [width,widthCOV,area,areaCOV,avgBoatSpeed,avgBoatCourse,avgWaterSpeed,...
            avgWaterDir,meanDepth,maxDepth,maxWaterSpeed]=...
            clsTransectData.computeCharacteristics(meas.transects,discharge);
        
        
        
        % Use extrap to compute the velocity profile of the sample
        udim = q_rawnorm(validData,:); udim=udim(:);
        zdim = z_rawnorm(validData,:); zdim=zdim(:);
        
        
        % Compute all the extrap fits
        [extrapPP] = extrapVMT(udim,zdim,1:size(udim,1),'PowerPower','default');
        [extrapCP] = extrapVMT(udim,zdim,1:size(udim,1),'ConstantPower','default');
        [extrapCPopt] = extrapVMT(udim,zdim,1:size(udim,1),'ConstantPower','optimize');
        [extrapCNS] = extrapVMT(udim,zdim,1:size(udim,1),'ConstantNo Slip','default');
        [extrapCNSopt] = extrapVMT(udim,zdim,1:size(udim,1),'ConstantNo Slip','optimize');
        [extrap3pNS] = extrapVMT(udim,zdim,1:size(udim,1),'3-PointNoSlip','default');
        [extrap3pNSopt] = extrapVMT(udim,zdim,1:size(udim,1),'3-PointNoSlip','optimize');
        [extrapPPopt] = extrapVMT(udim,zdim,1:size(udim,1),'PowerPower','optimize');
        [extrapCNS] = extrapVMT(udim,zdim,1:size(udim,1),'ConstantNo Slip','default');
        
        % Use DSM's QRev Logic to choose the best fit, then create an extrap figure
        % using the auto selected method
        [extrapAuto] = selectFit(extrapPPopt,extrapPP,extrapCNSopt);
        fig_extrap_handle = findobj(0,'name','Velocity Profile Extrapotation');
        if ~isempty(fig_extrap_handle) &&  ishandle(fig_extrap_handle)
            figure(fig_extrap_handle); clf
        else
            fig_extrap_handle = figure('name','Velocity Profile Extrapotation'); clf
        end
        plot(udim(:,:),zdim(:,:),'.','color', [0.8 0.8 0.8]); hold on
        plotScale (meas.extrapFit.normData, fig_extrap_handle)
        
        
        
        
        % Find total mean velocity using trapz (from VMT method) for each profile
        % type. As this represents the y-axis, use H at this location for
        % dimensioning
        U = avgWaterSpeed(end);  %m/s
        H = meanDepth(end);      %m
        uPP = abs(VMT_LayerAveMean(extrapPP.z.*mean(H),extrapPP.u.*mean(U)));
        kPP = (uPP./mean(U))/extrapPP.u(end);
        uPPopt = abs(VMT_LayerAveMean(extrapPPopt.z.*mean(H),extrapPPopt.u.*mean(U)));
        kPPopt = (uPPopt./mean(U))/extrapPPopt.u(end);
        
        % CPower
        botZ = extrapCP.z(extrapCP.z<=0.25).*mean(H);
        botU = extrapCP.u(extrapCP.z<=0.25).*mean(U);
        midZ = extrapCP.zmedian.*mean(H);
        midU = extrapCP.umedian.*mean(U);
        topZ = extrapCP.z(extrapCP.z>=0.5).*mean(H);
        topU = extrapCP.u(extrapCP.z>=0.5).*mean(U);
        toZ = [botZ; midZ; topZ];
        toU = [botU; midU; topU];
        [toZ,ind]=sort(toZ,'descend');
        toU=toU(ind);
        uCP = abs(VMT_LayerAveMean(toZ,toU));
        kCP = (uCP./mean(U))/extrapCP.u(end);
        
        % CPower Optimized
        botZ = extrapCPopt.z(extrapCPopt.z<=0.25).*mean(H);
        botU = extrapCPopt.u(extrapCPopt.z<=0.25).*mean(U);
        midZ = extrapCPopt.zmedian.*mean(H);
        midU = extrapCPopt.umedian.*mean(U);
        topZ = extrapCPopt.z(extrapCPopt.z>=0.5).*mean(H);
        topU = extrapCPopt.u(extrapCPopt.z>=0.5).*mean(U);
        toZ = [botZ; midZ; topZ];
        toU = [botU; midU; topU];
        [toZ,ind]=sort(toZ,'descend');
        toU=toU(ind);
        uCPopt = abs(VMT_LayerAveMean(toZ,toU));
        kCPopt = (uCPopt./mean(U))/extrapCPopt.u(end);
        
        % CNS
        botZ = extrapCNS.z(extrapCNS.z<=0.25).*mean(H);
        botU = extrapCNS.u(extrapCNS.z<=0.25).*mean(U);
        midZ = extrapCNS.zmedian.*mean(H);
        midU = extrapCNS.umedian.*mean(U);
        topZ = extrapCNS.z(extrapCNS.z>=0.5).*mean(H);
        topU = extrapCNS.u(extrapCNS.z>=0.5).*mean(U);
        toZ = [botZ; midZ; topZ];
        toU = [botU; midU; topU];
        [toZ,ind]=sort(toZ,'descend');
        toU=toU(ind);
        uCNS = abs(VMT_LayerAveMean(toZ,toU));
        kCNS = (uCNS./mean(U))/extrapCNS.u(end);
        
        % CNS optimized
        botZ = extrapCNSopt.z(extrapCNSopt.z<=0.25).*mean(H);
        botU = extrapCNSopt.u(extrapCNSopt.z<=0.25).*mean(U);
        midZ = extrapCNSopt.zmedian.*mean(H);
        midU = extrapCNSopt.umedian.*mean(U);
        topZ = extrapCNSopt.z(extrapCNSopt.z>=0.5).*mean(H);
        topU = extrapCNSopt.u(extrapCNSopt.z>=0.5).*mean(U);
        toZ = [botZ; midZ; topZ];
        toU = [botU; midU; topU];
        [toZ,ind]=sort(toZ,'descend');
        toU=toU(ind);
        uCNSopt = abs(VMT_LayerAveMean(toZ,toU));
        kCNSopt = (uCNSopt./mean(U))/extrapCNSopt.u(end);
        
        % 3-point No Slip
        botZ = extrap3pNS.z(extrap3pNS.z<=0.25).*mean(H);
        botU = extrap3pNS.u(extrap3pNS.z<=0.25).*mean(U);
        midZ = extrap3pNS.zmedian.*mean(H);
        midU = extrap3pNS.umedian.*mean(U);
        topZ = extrap3pNS.z(extrap3pNS.z>=0.5).*mean(H);
        topU = extrap3pNS.u(extrap3pNS.z>=0.5).*mean(U);
        toZ = [botZ; midZ; topZ];
        toU = [botU; midU; topU];
        [toZ,ind]=sort(toZ,'descend');
        toU=toU(ind);
        u3PNS = abs(VMT_LayerAveMean(toZ,toU));
        k3PNS = (u3PNS./mean(U))/extrap3pNS.u(end);
        
        % 3-point No Slip Optimized
        botZ = extrap3pNSopt.z(extrap3pNSopt.z<=0.25).*mean(H);
        botU = extrap3pNSopt.u(extrap3pNSopt.z<=0.25).*mean(U);
        midZ = extrap3pNSopt.zmedian.*mean(H);
        midU = extrap3pNSopt.umedian.*mean(U);
        topZ = extrap3pNSopt.z(extrap3pNSopt.z>=0.5).*mean(H);
        topU = extrap3pNSopt.u(extrap3pNSopt.z>=0.5).*mean(U);
        toZ = [botZ; midZ; topZ];
        toU = [botU; midU; topU];
        [toZ,ind]=sort(toZ,'descend');
        toU=toU(ind);
        u3PNSopt = abs(VMT_LayerAveMean(toZ,toU));
        k3PNSopt = (u3PNSopt./mean(U))/extrap3pNSopt.u(end);
        
        % Plot the probability concept fit with CI at 95%
        hold on
        plot(extrapPP.u_pc, extrapPP.z, '-', 'Color', [18 104 179]/255, 'LineWidth', 2)
        plot(extrapPP.u_predict_int95,extrapPP.z,'--','Color', [18 104 179]/255, 'LineWidth', 1.5)
        % Plot the probability concept fit with CI at 95%
        pc_h = extrapPP.h_predicted;
        pc_M = extrapPP.M;
        pc_phi = exp(pc_M)/(exp(pc_M)-1)-1/pc_M;

        % Determine all of the percent differences based on the
        % reference mean
        % Velocity
        autoMethod = [extrapAuto.topMethodAuto extrapAuto.botMethodAuto];
        autoExp = extrapAuto.exponentAuto;
        switch autoMethod
            case 'PowerPower'
                if isequal(autoExp,0.1667)
                    referenceMean = uPP;
                    referenceMeanAlpha = kPP;
                    for k=1:length(extrapPP.validData)
                        plot(...
                            [extrapPP.unit25(extrapPP.validData(k)) extrapPP.unit75(extrapPP.validData(k))],...
                            [extrapPP.zmedian(k) extrapPP.zmedian(k)],...
                            '-k','LineWidth',2)
                    end
                    plot(extrapPP.umedian,extrapPP.zmedian,'sk','MarkerFaceColor','k')
                    plot(extrapPP.u,extrapPP.z,'k-','linewidth',2)
                else
                    referenceMean = uPPopt;
                    referenceMeanAlpha = kPPopt;
                    for k=1:length(extrapPPopt.validData)
                        plot(...
                            [extrapPPopt.unit25(extrapPPopt.validData(k)) extrapPPopt.unit75(extrapPPopt.validData(k))],...
                            [extrapPPopt.zmedian(k) extrapPPopt.zmedian(k)],...
                            '-k','LineWidth',2)
                    end
                    plot(extrapPPopt.umedian,extrapPPopt.zmedian,'sk','MarkerFaceColor','k')
                    plot(extrapPPopt.u,extrapPPopt.z,'k-','linewidth',2)
                end
            case 'ConstantNo Slip'
                if isequal(autoExp,0.1667)
                    referenceMean = uCNS;
                    referenceMeanAlpha = kCNS;
                    for k=1:length(extrapCNS.validData)
                        plot(...
                            [extrapCNS.unit25(extrapCNS.validData(k)) extrapCNS.unit75(extrapCNS.validData(k))],...
                            [extrapCNS.zmedian(k) extrapCNS.zmedian(k)],...
                            '-k','LineWidth',2)
                    end
                    plot(extrapCNS.umedian,extrapCNS.zmedian,'sk','MarkerFaceColor','k')
                    plot(extrapCNS.u,extrapCNS.z,'k-','linewidth',2)
                else
                    referenceMean = uCNSopt;
                    referenceMeanAlpha = kCNSopt;
                    for k=1:length(extrapCNSopt.validData)
                        plot(...
                            [extrapCNSopt.unit25(extrapCNSopt.validData(k)) extrapCNSopt.unit75(extrapCNSopt.validData(k))],...
                            [extrapCNSopt.zmedian(k) extrapCNSopt.zmedian(k)],...
                            '-k','LineWidth',2)
                    end
                    plot(extrapCNSopt.umedian,extrapCNSopt.zmedian,'sk','MarkerFaceColor','k')
                    plot(extrapCNSopt.u,extrapCNSopt.z,'k-','linewidth',2)
                end
        end
        title (...
            {'Normalized Extrap'})
        xlabel('Velocity(z)/Avg Velocity')
        ylabel('Depth(z)/Vertical Beam Depth')
        
        uPPperdiff = ((uPP-referenceMean)./referenceMean).*100;
        uPPoptperdiff = ((uPPopt-referenceMean)./referenceMean).*100;
        uCNSperdiff = ((uCNS-referenceMean)./referenceMean).*100;
        uCNSoptperdiff = ((uCNSopt-referenceMean)./referenceMean).*100;
        u3PNSperdiff = ((u3PNS-referenceMean)./referenceMean).*100;
        u3PNSoptperdiff = ((u3PNSopt-referenceMean)./referenceMean).*100;
        kPPperdiff = ((kPP-referenceMeanAlpha)./referenceMeanAlpha).*100;
        kPPoptperdiff = ((kPPopt-referenceMeanAlpha)./referenceMeanAlpha).*100;
        kCNSperdiff = ((kCNS-referenceMeanAlpha)./referenceMeanAlpha).*100;
        kCNSoptperdiff = ((kCNSopt-referenceMeanAlpha)./referenceMeanAlpha).*100;
        k3PNSperdiff = ((k3PNS-referenceMeanAlpha)./referenceMeanAlpha).*100;
        k3PNSoptperdiff = ((k3PNSopt-referenceMeanAlpha)./referenceMeanAlpha).*100;
        
        % Create a uitable with values
        % See if Table figure exists already, if so clear the figure
        fig_table_handle = findobj(0,'name','Extrapolation Sensitivity Table');
        if ~isempty(fig_table_handle) &&  ishandle(fig_table_handle)
            figure(fig_table_handle); clf
            fPos = get(fig_table_handle,'Position'); fPos(3:4) = [525 200];
            fig_table_handle.Position = fPos;
        else
            fig_table_handle = figure('name','Extrapolation Sensitivity Table'); clf
            fPos = get(fig_table_handle,'Position'); fPos(3:4) = [525 200];
            fig_table_handle.Position = fPos;
        end
        uTable(1,1)={'Power'};
        uTable(1,2)={'Power'};
        uTable(1,3)={'0.1667'};
        uTable(1,4)={num2str(uPPperdiff,'%6.2f')};
        uTable(1,5)={num2str(kPP,'%6.3f')};
        uTable(1,6)={num2str(kPPperdiff,'%6.2f')};
        uTable(2,1)={'Power'};
        uTable(2,2)={'Power'};
        uTable(2,3)={num2str(extrapPPopt.exponent,'%6.4f')};
        uTable(2,4)={num2str(uPPoptperdiff,'%6.2f')};
        uTable(2,5)={num2str(kPPopt,'%6.3f')};
        uTable(2,6)={num2str(kPPoptperdiff,'%6.2f')};
        uTable(3,1)={'Constant'};
        uTable(3,2)={'No Slip'};
        uTable(3,3)={'0.1667'};
        uTable(3,4)={num2str(uCNSperdiff,'%6.2f')};
        uTable(3,5)={num2str(kCNS,'%6.3f')};
        uTable(3,6)={num2str(kCNSperdiff,'%6.2f')};
        uTable(4,1)={'Constant'};
        uTable(4,2)={'No Slip'};
        uTable(4,3)={num2str(extrapCNSopt.exponent,'%6.4f')};
        uTable(4,4)={num2str(uCNSoptperdiff,'%6.2f')};
        uTable(4,5)={num2str(kCNSopt,'%6.3f')};
        uTable(4,6)={num2str(kCNSoptperdiff,'%6.2f')};
        uTable(5,1)={'3-Point'};
        uTable(5,2)={'No Slip'};
        uTable(5,3)={'0.1667'};
        uTable(5,4)={num2str(u3PNSperdiff,'%6.2f')};
        uTable(5,5)={num2str(k3PNS,'%6.3f')};
        uTable(5,6)={num2str(k3PNSperdiff,'%6.2f')};
        uTable(6,1)={'3-Point'};
        uTable(6,2)={'No Slip'};
        uTable(6,3)={num2str(extrap3pNSopt.exponent,'%6.4f')};
        uTable(6,4)={num2str(u3PNSoptperdiff,'%6.2f')};
        uTable(6,5)={num2str(k3PNSopt,'%6.3f')};
        uTable(6,6)={num2str(k3PNSoptperdiff,'%6.2f')};
        
        uTable(7,1:6)={''};
        
        % PC vars M, h, phi, sensitivity
        uTable(8,1:6)={...
            '<html><b>Prob Concept</b></html>',...
            '<html><b>M</b></html>',...
            '<html><b>h</b></html>',...
            '',...
            '<html><b>phi</b></html>',...
            '<html><b>phi % Diff</b></html>'};
        uTable(9,2)={num2str(pc_M,'%6.2f')};
        uTable(9,3)={num2str(pc_h,'%6.2f')};
        uTable(9,5)={num2str(pc_phi,'%6.2f')};
        
        % for all table entries, check if selected method and label reference
        % if it is
        top = extrapAuto.topMethodAuto;
        bottom = extrapAuto.botMethodAuto;
        exp1 = extrapAuto.exponentAuto;
        for x = 1:6
            if strcmpi(uTable{x,1},top) & strcmpi(uTable{x,2},bottom) & abs(str2num(uTable{x,3})-exp1)<0.0001
                uTable(x,1) = {['<html><b>',uTable{x,1},'</b></html>']};
                uTable(x,2) = {['<html><b>',uTable{x,2},'</b></html>']};
                uTable(x,3) = {['<html><b>',uTable{x,3},'</b></html>']};
                uTable(x,4) = {'<html><b>Reference</b></html>'};
                uTable(x,5) = {['<html><b>',uTable{x,5},'</b></html>']};
                
                uTable(x,6) = {'<html><b>Reference</b></html>'};
                
            end
        end
        
        t = uitable(fig_table_handle);
        t.Data = uTable;
        t.ColumnName = {'Top Fit','Bottom Fit','Exponent','Velocity % Diff','Alpha','Alpha % Diff'};
        t.Position = [8 8 500 190];
        
        wcount = wcount + 1;
        if ~mod(wcount, wstep) || wcount == 1
            waitbar(wcount/1,hwait,['Processing ' num2str(wcount) ' of ' num2str(1) ' measurements'])
        end
    catch
        OK = vertcat(OK,{QRevFiles{zi}, datestr(datetime('now'),'yyyymmddHHMMSS')});
    end
    delete(hwait)
end

function plotScale (normData,h)
% Sets the scale for the plot based on the data plotted.

% Compute the overall minimum value of the 25 percentile and
% the overall maximum value of the 75 percentile.
minavgall=nan(length(normData),1);
maxavgall=nan(length(normData),1);
for i=1:length(normData)
    minavgall(i)=nanmin(normData(i).unitNormalized25(normData(i).validData));
    maxavgall(i)=nanmax(normData(i).unitNormalized75(normData(i).validData));
end

% Use percentiles to set axes limits
minavg=min(minavgall);
maxavg=max(maxavgall);
if minavg>0 && maxavg>0
    minavg=0;
    lower=0;
else
    lower=minavg.*1.2;
end
if maxavg<0 && minavg<0
    upper=0;
else
    upper=maxavg.*1.2;
end

% Scale axes
figure(h)
ylim([0 1]);
xlim([lower upper]);
box ('on')
grid('On')