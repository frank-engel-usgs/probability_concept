function [V,A,z] = pc_loadVMT()
% Load a single VMT mat-file
[filename,pathname] = ...
    uigetfile({'*.mat','MAT-files (*.mat)'}, ...
    'Select VMT MAT File', ...
    '', 'MultiSelect','off');

% Load the data:
% --------------
vars = load(fullfile(pathname,filename)); %Use first file to get the HGNS and VGNS  

% Make sure the selected file is a valid file:
% --------------------------------------------
varnames = fieldnames(vars);
if isequal(sort(varnames),{'A' 'Map' 'V' 'z'}')
    guiparams.mat_path = pathname;
    guiparams.mat_file = filename;
    guiparams.z = vars.z;
    guiparams.A = vars.A;
    guiparams.V = vars.V;
    A = guiparams.A;
    V = guiparams.V;
    z = guiparams.z;
else % Not a valid file
    errordlg('The selected file is not a valid ADCP data MAT file.', ...
        'Invalid File...')
end