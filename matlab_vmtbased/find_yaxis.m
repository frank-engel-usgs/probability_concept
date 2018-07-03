function [V,A,fig_contour_handle] =  find_yaxis(V,A,z)
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
plot(V.mcsDist(row,col),V.mcsDepth(row,col),'kx','MarkerSize',10)
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

sample_mask = V.mcsDist >= min_dist &...
    V.mcsDist <= max_dist;

% Use extrap to compute the velocity profile of the sample
u = V.uSmooth; z = V.mcsDepth;
zdim = nan(size(u)); udim = nan(size(u));
for i = 1:size(u,2)
    H = V.mcsBed(i);
    U = VMT_LayerAveMean(z(:,i),u(:,i));
    zdim(:,i) = (H - z(:,i))./H;
    udim(:,i) = u(:,i)./U;
end
zdim(zdim<=0) = nan;
zdim(~sample_mask) = nan; udim(~sample_mask) = nan;
zdim(isnan(udim)) = nan;
zdim = zdim(:,sample_mask(1,:));
udim = udim(:,sample_mask(1,:));



[exponent,alpha] = extrapVMT(udim,zdim,1:size(u,1),'PowerPower');
