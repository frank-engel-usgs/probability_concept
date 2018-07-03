% (meas,fullName,NavReference,OutTable,displayUnits)

% Get a list of files to work with
dname = uigetdir(pwd,'Select directory containing QRev files (will search recursively):');
[~,~,QRevFiles] = dirr([dname filesep '*QRev*'],'name');
[~, ~, ext] = cellfun(@fileparts, QRevFiles, 'UniformOutput', 0);
idx = find(cellfun(@(x)strcmp(x,'.mat'),ext));
QRevFiles = QRevFiles(idx);
numFiles = numel(QRevFiles);

hwait = waitbar(0,['Processing 1 of ' num2str(numFiles) ' measurements'] );
wstep = floor(numFiles/(numFiles)); wcount = 0;

% Store bulk results in a table
displayUnits = 'SI';
% displayUnits = 'English';
checkedOnly = true;
OK = {};
[unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=unitsMultiplier(displayUnits);


% Load each QRev result, create obj, process
for zi = 1:numFiles
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
        
        
        % Time
        % Compute total dureation
        temp=meas.transects(checked);
        temp=[temp(:).dateTime];
        totalDuration=nansum([temp(:).transectDuration_sec]);
        startDate=datestr(meas.transects(first).dateTime.startSerialTime,'mm/dd/yyyy HH:MM:ss');
        endDate=datestr(meas.transects(last).dateTime.endSerialTime,'mm/dd/yyyy HH:MM:ss');
        
        % Characteristics
        [width,widthCOV,area,areaCOV,avgBoatSpeed,avgBoatCourse,avgWaterSpeed,...
            avgWaterDir,meanDepth,maxDepth,maxWaterSpeed]=...
            clsTransectData.computeCharacteristics(meas.transects,discharge);
        
        
        % Discharges
        top=(clsQAData.meanQ(discharge(checked),'top'));
        middle=(clsQAData.meanQ(discharge(checked),'middle'));
        left=(clsQAData.meanQ(discharge(checked),'left'));
        right=(clsQAData.meanQ(discharge(checked),'right'));
        bottom=(clsQAData.meanQ(discharge(checked),'bottom'));
        total=(clsQAData.meanQ(discharge(checked),'total'));
        mbc_percent=(((clsQAData.meanQ(discharge(checked),'total')./...
            clsQAData.meanQ(discharge(checked),'totalUncorrected'))-1).*100);
        
        % Extrapolation
        topMethod = meas.extrapFit.selFit(1,end).topMethod;
        botMethod = meas.extrapFit.selFit(1,end).botMethod;
        exponent  = meas.extrapFit.selFit(1,end).exponent;
        
        % Uncertainties
        % Compute mean total discharge
        meanQ=clsQAData.meanQ(discharge(checked),'total');
        perInvalidCells=(clsQAData.meanQ(discharge(checked),'intCells')./meanQ).*100;
        perInvalidEns=(clsQAData.meanQ(discharge(checked),'intEns')./meanQ).*100;
        cov=(uncertainty.cov);
        cov95=(uncertainty.cov95);
        invalid95=(uncertainty.invalid95);
        edges95=(uncertainty.edges95);
        extrapolation95=(uncertainty.extrapolation95);
        movingBed95=(uncertainty.movingBed95);
        systematic=(uncertainty.systematic);
        total95=(uncertainty.total95);
        
       
        wcount = wcount + 1;
        if ~mod(wcount, wstep) || wcount == numFiles
            waitbar(wcount/numFiles,hwait,['Processing ' num2str(wcount) ' of ' num2str(numFiles) ' measurements'])
        end
    catch
        OK = vertcat(OK,{QRevFiles{zi}, datestr(datetime('now'),'yyyymmddHHMMSS')});
    end
end

waitbar(1,hwait,'Processing Complete')
delete(hwait)
