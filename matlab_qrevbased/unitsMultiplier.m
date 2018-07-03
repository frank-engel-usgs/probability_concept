function [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=unitsMultiplier(displayUnits)
% Computes the units conversion from SI units used internally to the
% desired display units

    % Get disply units
%     displayUnits=getappdata(handles.hMainGui,'Units');
    
    % Set labels and conversions for SI
    if strcmp(displayUnits,'SI')
        unitsL=1;
        unitsQ=1;
        unitsA=1;
        unitsV=1;
        uLabelL='(m)';
        uLabelQ='(m3/s)';
        uLabelA='(m2)';
        uLabelV='(m/s)';
    % Set labels and conversions for English
    else
        unitsL=1./0.3048;
        unitsQ=unitsL.^3;
        unitsA=unitsL.^2;
        unitsV=unitsL;
        uLabelL='(ft)';
        uLabelQ='(ft3/s)';
        uLabelA='(ft2)';
        uLabelV='(ft/s)';
    end  