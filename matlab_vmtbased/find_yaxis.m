function [V,A,fig_contour_handle,fig_extrap_handle] =  find_yaxis(V,A,z)
% Input variables
horizontal_grid_node_spacing_orig = A(1).hgns;
vertical_grid_node_spacing_orig = A(1).vgns;
horizontal_grid_node_spacing = 0.25;
vertical_grid_node_spacing = 0.10;
wse = 0;
horizontal_smoothing_window = 2;
vertical_smoothing_window = 1;
contour = 'streamwise';
vertical_exaggeration = 2;
english_units = 0;
allow_vmt_flip_flux = 0;
start_bank = 'auto';
set_cross_section_endpoints = 0;
unit_discharge_correction = 0;
bed_elevation = 0;

% Preprocess the data:
% --------------------
A(1).hgns = horizontal_grid_node_spacing;
A(1).vgns = vertical_grid_node_spacing;
A = VMT_PreProcess(z,A);

% Process the transects:
% ----------------------
[A,V,~] = VMT_ProcessTransects(z,A,...
    set_cross_section_endpoints,unit_discharge_correction,bed_elevation,start_bank);
V = VMT_SmoothVar(V, ...
    ...contour, ...
    horizontal_smoothing_window, ...
    vertical_smoothing_window);
[V] = VMT_Vorticity(V);

% Plot Cross-Section:
% ----------------------
[z,A,V,zmin,zmax,~,fig_contour_handle] = VMT_PlotXSCont(z,A,V, ...
    contour, ...
    vertical_exaggeration, ...
    english_units, ...
    allow_vmt_flip_flux,...
    start_bank); %#ok<ASGLU> % PLOT3

% Find the local maxima, h
% ---------
% The absolute maximum and index is easy to determine:
[umax,ind] = nanmax(V.uSmooth(:));
[row,col] = ind2sub(size(V.uSmooth),ind);
figure(fig_contour_handle)
hold on
scatter(V.mcsDist(row,col),V.mcsDepth(row,col),'kx','Linewidth',2)
VMTStylePrint()

% The issue is: if the max is found at the surface-most value, then do we
% presume that the high velocity core is NOT submerged? In absence of
% surface velocity measurements, that's hard to determine. My idea of one
% aproach is to take 1 stdev of channel width worth of velocity data, and
% produce an extrap on it. Let's see what that yields...

% Subsample velocities by 1 stdev of channel width, centered on umax column
% (i.e., 34.1% either side)
sigmas = 0.341;
width = nanmax(V.mcsDist(:));
yaxis_dist = V.mcsDist(1,col);
sample_dist = sigmas*width;
min_dist = yaxis_dist - sample_dist;
max_dist = yaxis_dist + sample_dist;

figure(fig_contour_handle);
ylims = ylim;
hold on
plot([min_dist min_dist],[0 max(ylims)],'--k','LineWidth',1.5)
plot([max_dist max_dist],[0 max(ylims)],'--k','LineWidth',1.5)

sample_mask = V.mcsDist >= min_dist &...
    V.mcsDist <= max_dist;

% Use extrap to compute the velocity profile of the sample
u = V.uSmooth; z = V.mcsDepth;
zdim = nan(size(u)); udim = nan(size(u));
for i = 1:size(u,2)
    H(i) = V.mcsBed(i);
    U(i) = VMT_LayerAveMean(z(:,i),u(:,i));
    zdim(:,i) = (H(i) - z(:,i))./H(i);
    udim(:,i) = u(:,i)./U(i);
end
zdim(zdim<=0) = nan;
zdim(~sample_mask) = nan; udim(~sample_mask) = nan;
zdim(isnan(udim)) = nan;
zdim = zdim(:,sample_mask(1,:));
udim = udim(:,sample_mask(1,:));
H = H(:,sample_mask(1,:));
U = U(:,sample_mask(1,:));


% Compute all the extrap fits
[extrapPP,~] = extrapVMT(udim,zdim,1:size(u,1),'PowerPower','default');
[extrapCP,~] = extrapVMT(udim,zdim,1:size(u,1),'ConstantPower','default');
[extrapCPopt,~] = extrapVMT(udim,zdim,1:size(u,1),'ConstantPower','optimize');
[extrapCNS,~] = extrapVMT(udim,zdim,1:size(u,1),'ConstantNoSlip','default');
[extrapCNSopt,~] = extrapVMT(udim,zdim,1:size(u,1),'ConstantNoSlip','optimize');
[extrap3pNS,~] = extrapVMT(udim,zdim,1:size(u,1),'3-PointNoSlip','default');
[extrap3pNSopt,~] = extrapVMT(udim,zdim,1:size(u,1),'3-PointNoSlip','optimize');
[extrapPPopt,~] = extrapVMT(udim,zdim,1:size(u,1),'PowerPower','optimize');
[extrapCNS,fig_extrap_handle] = extrapVMT(udim,zdim,1:size(u,1),'ConstantNoSlip','default');

% Find total mean velocity using trapz (from VMT method) for each profile
% type. As this represents the y-axis, use H at this location for
% dimensioning
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

% Determine all of the percent differences based on the
% reference mean
referenceMean = uPP;
uPPperdiff = ((uPP-referenceMean)./referenceMean).*100;
uPPoptperdiff = ((uPPopt-referenceMean)./referenceMean).*100;
uCNSperdiff = ((uCNS-referenceMean)./referenceMean).*100;
uCNSoptperdiff = ((uCNSopt-referenceMean)./referenceMean).*100;
u3PNSperdiff = ((u3PNS-referenceMean)./referenceMean).*100;
u3PNSoptperdiff = ((u3PNSopt-referenceMean)./referenceMean).*100;

% Create a uitable with values
% See if Table figure exists already, if so clear the figure
fig_table_handle = findobj(0,'name','Extrapolation Sensitivity Table');
if ~isempty(fig_table_handle) &&  ishandle(fig_table_handle)
    figure(fig_table_handle); clf
    fPos = get(fig_table_handle,'Position'); fPos(3:4) = [600 148];
    fig_table_handle.Position = fPos;
else
    fig_table_handle = figure('name','Extrapolation Sensitivity Table'); clf
    fPos = get(fig_table_handle,'Position'); fPos(3:4) = [600 148];
    fig_table_handle.Position = fPos;
end
uTable(1,1)={'Power'};
uTable(1,2)={'Power'};
uTable(1,3)={'0.1667'};
uTable(1,4)={num2str(uPPperdiff,'%6.2f')};
uTable(1,5)={num2str(kPP,'%6.3f')};
uTable(2,1)={'Power'};
uTable(2,2)={'Power'};
uTable(2,3)={num2str(extrapPPopt.exponent,'%6.4f')};
uTable(2,4)={num2str(uPPoptperdiff,'%6.2f')};
uTable(2,5)={num2str(kPPopt,'%6.3f')};
uTable(3,1)={'Constant'};
uTable(3,2)={'No Slip'};
uTable(3,3)={'0.1667'};
uTable(3,4)={num2str(uCNSperdiff,'%6.2f')};
uTable(3,5)={num2str(kCNS,'%6.3f')};
uTable(4,1)={'Constant'};
uTable(4,2)={'No Slip'};
uTable(4,3)={num2str(extrapCNSopt.exponent,'%6.4f')};
uTable(4,4)={num2str(uCNSoptperdiff,'%6.2f')};
uTable(4,5)={num2str(kCNSopt,'%6.3f')};
uTable(5,1)={'3-Point'};
uTable(5,2)={'No Slip'};
uTable(5,3)={'0.1667'};
uTable(5,4)={num2str(u3PNSperdiff,'%6.2f')};
uTable(5,5)={num2str(k3PNS,'%6.3f')};
uTable(6,1)={'3-Point'};
uTable(6,2)={'No Slip'};
uTable(6,3)={num2str(extrap3pNSopt.exponent,'%6.4f')};
uTable(6,4)={num2str(u3PNSoptperdiff,'%6.2f')};
uTable(6,5)={num2str(k3PNSopt,'%6.3f')};
t = uitable(fig_table_handle);
t.Data = uTable;
t.ColumnName = {'Top Fit','Bottom Fit','Exponent','Velocity % Diff','Alpha'};
t.Position = [8 8 416 133];