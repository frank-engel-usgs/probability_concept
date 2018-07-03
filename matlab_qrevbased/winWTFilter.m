function varargout = winWTFilter(varargin)
% WINWTFILTER MATLAB code for winWTFilter.fig
%      WINWTFILTER, by itself, creates a new WINWTFILTER or raises the existing
%      singleton*.
%
%      H = WINWTFILTER returns the handle to a new WINWTFILTER or the handle to
%      the existing singleton*.
%
%      WINWTFILTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WINWTFILTER.M with the given input arguments.
%
%      WINWTFILTER('Property','Value',...) creates a new WINWTFILTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before winWTFilter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to winWTFilter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help winWTFilter

% Last Modified by GUIDE v2.5 03-Mar-2016 14:41:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @winWTFilter_OpeningFcn, ...
                   'gui_OutputFcn',  @winWTFilter_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function winWTFilter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to winWTFilter (see VARARGIN)

% Choose default command line output for winWTFilter
handles.output = hObject;
    
% movegui('center')
    handles.pltShiptrack=1;
    
    % Get main gui handle
%     hInput=find(strcmp(varargin,'hMainGui'));
%     if ~isempty(hInput)
%         handles.hMainGui=varargin{hInput+1};
%     end
%     
%     setWindowPosition(hObject,handles);
%     
%     commentIcon(handles.pbComment);
    
    % Get data from hMainGui
    handles.meas = varargin{1};
    meas=handles.meas;
    oldDischarge=meas.discharge;
    handles.checkedIdx=find([meas.transects.checked]==1);
    
    % Set reference
    set(handles.txtNavRef,'String',meas.transects(handles.checkedIdx(1)).wVel.navRef);
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);
    
    % Set units for column names
    colNames=get(handles.tblWTFilters,'ColumnName');
    colNames{11}=[colNames{11},' ',uLabelQ];
    colNames{12}=[colNames{12},' ',uLabelQ];
    set(handles.tblWTFilters,'ColumnName',colNames);    
    
    % Get table from gui
    %tableData=get(handles.tblWTFilters,'Data');

    % Get data for table from each transect
    nTransects=length(handles.checkedIdx);
    for n=1:nTransects
        excludedDist(n)=meas.transects(handles.checkedIdx(n)).wVel.excludedDist;
        beamFilter(n)=meas.transects(handles.checkedIdx(n)).wVel.beamFilter;
        dFilter{n}=meas.transects(handles.checkedIdx(n)).wVel.dFilter;
        dFilterThreshold(n)=meas.transects(handles.checkedIdx(n)).wVel.dFilterThreshold;
        wFilter{n}=meas.transects(handles.checkedIdx(n)).wVel.wFilter;
        wFilterThreshold(n)=meas.transects(handles.checkedIdx(n)).wVel.wFilterThreshold;
        snrFilter{n}=meas.transects(handles.checkedIdx(n)).wVel.snrFilter;
        manufacturer{n}=meas.transects(handles.checkedIdx(n)).adcp.manufacturer;
        smoothFilter{n}=meas.transects(handles.checkedIdx(n)).wVel.smoothFilter;
        interpolateCells{n}=meas.transects(handles.checkedIdx(n)).wVel.interpolateCells;
        interpolateEns{n}=meas.transects(handles.checkedIdx(n)).wVel.interpolateEns;        
    end % for n
    
    % Populate table
    handles=updateTable(handles,meas,oldDischarge);
    tableData=get(handles.tblWTFilters,'Data');
    tableData=tableData(1:nTransects,:);    
    % Set plotting to 1st transect
    handles.plottedTransect=1;
    idxStop=findstr(tableData{handles.plottedTransect,1},'</');
    if isempty(idxStop)
        fileName=tableData{handles.plottedTransect,1};
    else
        idxStart=findstr(tableData{handles.plottedTransect,1}(1:idxStop),'>');
        fileName=tableData{handles.plottedTransect,1}(idxStart(end)+1:idxStop(1)-1);
    end
    set(handles.plottedtxt,'String',fileName);
    
    % Excluded Distance
    set(handles.edExcludedDist,'String',num2str(excludedDist(1).*unitsL,'% 5.2f'));
    
    % Beam filter settings 
    % ====================
    if nansum(beamFilter==beamFilter(1))~=nTransects
        warndlg('3 beam filter setting inconsistent, value from 1st transect will be used.');
    end
    switch beamFilter(1)
        case 3
            set(handles.pu3Beam,'Value',2);
        case 4
            set(handles.pu3Beam,'Value',3);
        otherwise
            set(handles.pu3Beam,'Value',1);
    end % switch
    
    % Difference velocity filter settings
    % ===================================
    if nansum(strcmp(dFilter,dFilter(1)))~=nTransects    
        warndlg('Error filter setting inconsistent, value from 1st transect will be used.');
    end

    switch dFilter{1}
        case 'Auto'
            set(handles.puDiffVel,'Value',1);
            set(handles.edDiffVelThreshold,'Enable','off')
            set(handles.edDiffVelThreshold,'String','Auto')
        case 'Manual'
            set(handles.puDiffVel,'Value',2);
            set(handles.edDiffVelThreshold,'Enable','on')
            set(handles.edDiffVelThreshold,'String',num2str(dFilterThreshold(1).*unitsV,'%6.3f'))
        case 'Off'
            set(handles.puDiffVel,'Value',3);
            set(handles.edDiffVelThreshold,'Enable','off')
            set(handles.edDiffVelThreshold,'String','None')
    end
        
    % Vertical velocity filter settings
    % =================================
    if nansum(strcmp(wFilter,wFilter(1)))~=nTransects    
        warndlg('Vertical velocity filter setting inconsistent, value from 1st transect will be used.');
    end

    switch wFilter{1}
        case 'Auto'
            set(handles.puVertVel,'Value',1);
            set(handles.edVertVelThreshold,'Enable','off')
            set(handles.edVertVelThreshold,'String','Auto')
        case 'Manual'
            set(handles.puVertVel,'Value',2);
            set(handles.edVertVelThreshold,'Enable','on')
            set(handles.edVertVelThreshold,'String',num2str(wFilterThreshold(1).*unitsV,'%6.3f'))
        case 'Off'
            set(handles.puVertVel,'Value',3);
            set(handles.edVertVelThreshold,'Enable','off')
            set(handles.edVertVelThreshold,'String','None')
    end
    
    % Other filter settings
    % =====================
    if nansum(strcmp(smoothFilter,smoothFilter(1)))~=nTransects    
        warndlg('Smooth filter setting inconsistent, value from 1st transect will be used.');
    end
    switch smoothFilter{1}
        case 'Auto'
            set(handles.puOtherFilter,'Value',2);
        case 'Off'
            set(handles.puOtherFilter,'Value',1);
    end
    
    % SNR filter settings
    % ===================
    if strcmpi(snrFilter{1},'Auto')
        set(handles.puSNRFilter,'Value',1);
    else
        set(handles.puSNRFilter,'Value',2);
    end % if Auto
    
    if strcmpi(manufacturer{1},'SonTek')
        set(handles.uipanelSNR,'Visible','On');
        set(handles.puSNRFilter,'Visible','On');
        set(handles.rbSNR,'Visible','On');
    else
        set(handles.puSNRFilter,'Value',2);
        set(handles.uipanelSNR,'Visible','Off');
        set(handles.puSNRFilter,'Visible','Off');
        set(handles.rbSNR,'Visible','Off');
    end % if SonTek
    
    % Compute number of 3 beam solutions
    temp=meas.transects(handles.checkedIdx);
    temp=wtFilters(temp,'Beam',4);
    for n=1:nTransects    
        % Compute the total number of depth cells
        numDepthCells(n)=nansum(nansum(meas.transects(handles.checkedIdx(n)).wVel.cellsAboveSL)); 
        tableData{n,3}=sprintf('% 12.1f',((numDepthCells(n)-nansum(nansum(temp(n).wVel.validData(:,:,6))))./numDepthCells(n)).*100);
    end % for n    
    
    % Update table
    set(handles.tblWTFilters,'Data',tableData);
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    drawnow
    
% Update handles structure
guidata(hObject, handles);

function varargout = winWTFilter_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function handles=updateTable(handles,meas,oldDischarge)
    % Get tableData
    tableData=get(handles.tblWTFilters,'Data');
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);
    
    % Loop through transects
    nTransects=length(handles.checkedIdx);
    for n=1:nTransects
        
        % Get valid data matrix
        validData=meas.transects(handles.checkedIdx(n)).wVel.validData;
        
        % Compute the total number of depth cells including an estimate of
        % the depth cells for invalid ensembles.
        numDepthCells(n)=nansum(nansum(meas.transects(handles.checkedIdx(n)).wVel.cellsAboveSL));     
        idx=find(meas.transects(handles.checkedIdx(n)).fileName=='\',1,'last');
        if isempty(idx)
            idx=0;
        end
        
        tableData{n,1}=meas.transects(handles.checkedIdx(n)).fileName(idx+1:end);
        tableData{n,2}=sprintf('% 10.0f',numDepthCells(n));
        % Correction to not count cells marked invalid by excluded distance
        % in count of invalid cells used to ID potential problems.
        usableDepthCells(n)=nansum(nansum(validData(:,:,7)));
        tableData{n,2}=sprintf('% 10.0f',usableDepthCells(n));
        tableData{n,4}=sprintf('% 8.1f',((usableDepthCells(n)-nansum(nansum(validData(:,:,1).*validData(:,:,7))))./usableDepthCells(n)).*100);
        tableData{n,5}=sprintf('% 8.1f',((usableDepthCells(n)-nansum(nansum(validData(:,:,2).*validData(:,:,7))))./usableDepthCells(n)).*100);
        tableData{n,6}=sprintf('% 8.1f',((usableDepthCells(n)-nansum(nansum(validData(:,:,6).*validData(:,:,7))))./usableDepthCells(n)).*100);
        tableData{n,7}=sprintf('% 8.1f',((usableDepthCells(n)-nansum(nansum(validData(:,:,3).*validData(:,:,7))))./usableDepthCells(n)).*100);
        tableData{n,8}=sprintf('% 8.1f',((usableDepthCells(n)-nansum(nansum(validData(:,:,4).*validData(:,:,7))))./usableDepthCells(n)).*100);
        tableData{n,9}=sprintf('% 8.1f',((usableDepthCells(n)-nansum(nansum(validData(:,:,5).*validData(:,:,7))))./usableDepthCells(n)).*100);
        tableData{n,10}=sprintf('% 8.1f',((usableDepthCells(n)-nansum(nansum(validData(:,:,8).*validData(:,:,7))))./usableDepthCells(n)).*100);
        tableData{n,11}=sprintf('% 12.2f',oldDischarge(handles.checkedIdx(n)).total.*unitsQ);
        tableData{n,12}=sprintf('% 12.2f',meas.discharge(handles.checkedIdx(n)).total.*unitsQ);
        tableData{n,13}=sprintf('% 12.2f',((meas.discharge(handles.checkedIdx(n)).total-oldDischarge(handles.checkedIdx(n)).total)./oldDischarge(handles.checkedIdx(n)).total).*100);
    end % for n
    
    % Apply QA formatting
    tableData=applyFormat(handles,tableData,meas);
    
    % Update table
    set(handles.tblWTFilters,'Data',tableData);

function tableData=applyFormat(handles,tableData,meas)
% Applys a format to the table that highlights values that have generated
% warnings or caution about the quality of the data and its affect on Q.
%
% INPUT:
%
% handles: handles data structure from figure
%
% tableData: data from table to be formatted
%
% meas: object of clsMeasurement
%
% OUTPUT:
%
% tableData: data for table that has been formatted.

    % Combine caution notices into single matrix
    %caution=meas.qa.wVel.ensInvalidCaution | meas.qa.wVel.qRunCaution;
    caution=meas.qa.wVel.qRunCaution(handles.checkedIdx,:) | meas.qa.wVel.qTotalCaution(handles.checkedIdx,:);
%     cautionEns=nansum(meas.qa.wVel.qTotalCaution(handles.checkedIdx,:),2);
    % Combine warning notices into single matrix
    warning=meas.qa.wVel.qRunWarning(handles.checkedIdx,:) | meas.qa.wVel.qTotalWarning(handles.checkedIdx,:);
    
    % Combine caution and warning into single matrix
    code=double(caution);
    code(warning)=2;
    
    
    % Rearrange matrix to match table
    if strcmp(meas.transects(1).adcp.manufacturer,'TRDI')
        applyCode=code(:,[1:2,6,3:5]);
    else
        applyCode=code(:,[1:2,6,3:5,8]);
    end
    
    % Creat idx of cells to apply caution and warning formats
    idxCaution=find(applyCode==1);
    idxWarning=find(applyCode==2);
%     idxCautionEns=find(cautionEns>0);
    
    % Get subset of table to be formatted
    tempData=tableData(:,4:10);
    
    % Apply caution format
    for n=1:length(idxCaution)
        tempData(idxCaution(n))={['<HTML><BODY bgColor="yellow" width="43px"><center>',num2str(tempData{idxCaution(n)}),'</center></BODY></HTML>']};
    end
    
    % Apply warning format
    for n=1:length(idxWarning)
        tempData(idxWarning(n))={['<HTML><BODY bgColor="red" width="43px"><strong><center>',num2str(tempData{idxWarning(n)}),'</center></strong></BODY></HTML>']};
    end
    
    % Put formatted cells back in table
    tableData(:,4:10)=tempData;
    
        % Apply caution ensembles format
%     for n=1:length(idxCautionEns)
%         tableData(idxCautionEns(n),1)={['<HTML><BODY bgColor="yellow" width="43px"><center>',tableData{idxCautionEns(n),1},'</center></BODY></HTML>']};
%     end
    
% Filter settings

function pu3Beam_Callback(hObject, eventdata, handles)

    handles.pltShiptrack=1;
    
    % Get measurement data
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas);
    
    % Get data from GUI
    setting=get(handles.pu3Beam,'Value');
    
    % Apply selected setting
    switch setting
        case 1 % Auto
            s.WTbeamFilter=-1;
                            
        case 2 % Allow 3 beam solutions
            s.WTbeamFilter=3;
            
        case 3 % 4-beam solutions only
            s.WTbeamFilter=4;
    end
    
    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);

    % Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);

function puDiffVel_Callback(hObject, eventdata, handles)
% Process difference velocity filter as selected by the user

    handles.pltShiptrack=1;

    % Get measurement data
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas);
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    
    
    % Get data from GUI
    setting=get(handles.puDiffVel,'Value');
    
    % Apply selected setting
    switch setting
        case 1 % Auto
            s.WTdFilter='Auto';
            set(handles.edDiffVelThreshold,'Enable','off')
            set(handles.edDiffVelThreshold,'String','Auto');
                            
        case 2 % Manual
            s.WTdFilter='Manual';
            set(handles.edDiffVelThreshold,'Enable','on');
            set(handles.edDiffVelThreshold,'String',num2str(s.WTdFilterThreshold.*unitsV,'%6.3f'));

        case 3 % No filter applies
            s.WTdFilter='Off';
            set(handles.edDiffVelThreshold,'Enable','off')
            set(handles.edDiffVelThreshold,'String','None');
    end
    
    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);
       
    % Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);
    
function edDiffVelThreshold_Callback(hObject, eventdata, handles)
% Process manually entered difference velocity filter

    handles.pltShiptrack=1;
    
    % Get measurement data
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas);
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    
    
    % Get data from GUI
    setting=str2num(get(handles.edDiffVelThreshold,'String'));
    
   % Set filter
    s.WTdFilterThreshold=setting./unitsV;
    
    % Update display
    set(handles.edDiffVelThreshold,'String',s.WTdFilterThreshold.*unitsV);
    
    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);
    
    % Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);
    
function puVertVel_Callback(hObject, eventdata, handles)
% Processes vertical velocity filter as selected by the user

    handles.pltShiptrack=1;

    % Get measurement data
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas);
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    
    
    % Get data from GUI
    setting=get(handles.puVertVel,'Value');
    
    % Apply selected setting
    switch setting
        case 1 % Auto
            s.WTwFilter='Auto';
            set(handles.edVertVelThreshold,'Enable','off');  
            set(handles.edVertVelThreshold,'String','Auto');
            
        case 2 % Manual
            s.WTwFilter='Manual';
            set(handles.edVertVelThreshold,'Enable','on');
            set(handles.edVertVelThreshold,'String',num2str(s.WTwFilterThreshold.*unitsV,'%6.3f'));

        case 3 % Off, no filtering
            s.WTwFilter='Off';
            set(handles.edVertVelThreshold,'Enable','off')
            set(handles.edVertVelThreshold,'String','None');
    end
    
    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);
    
    % Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);
    
function edVertVelThreshold_Callback(hObject, eventdata, handles)
% Applies manually set vertical velocity threshold

    handles.pltShiptrack=1;

    % Get measurement data
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas);

    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    

    % Get data from GUI
    setting=str2num(get(handles.edVertVelThreshold,'String'));  
    
    % Set filter
    s.WTwFilterThreshold=setting./unitsV;
    
    % Update display
    set(handles.edVertVelThreshold,'String',num2str(s.WTwFilterThreshold.*unitsV,'%6.3f'));

    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;

    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);
    
    % Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);
    
function puOtherFilter_Callback(hObject, eventdata, handles)
% Processes request for smooth or other filter
    % Get measurement data
    
    handles.pltShiptrack=1;    
    
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas); 
    
    % Get data from GUI
    setting=get(handles.puOtherFilter,'Value');
    
    % Apply filter requested
    switch setting
        case 1 % Off
            s.WTsmoothFilter='Off';            
                                     
        case 2 % On
            s.WTsmoothFilter='Auto';
    end
    
    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);
    
    % Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);
    
function edExcludedDist_Callback(hObject, eventdata, handles)
% Applies manually set excluded distance threshold

    handles.pltShiptrack=1;

    % Get measurement data
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas);
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    
    
    % Get data from GUI
    setting=str2double(get(handles.edExcludedDist,'String'));  
    
    % Set filter
    s.WTExcludedDistance=setting./unitsL;
    
    % Update display
    set(handles.edExcludedDist,'String',num2str(s.WTExcludedDistance.*unitsL,'%5.2f'));

    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);    
    setappdata(handles.hMainGui,'measurement',meas);
    set(gcf, 'pointer', oldpointer);     
    drawnow;
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);
    
    % Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);  

function puSNRFilter_Callback(hObject, eventdata, handles)

    handles.pltShiptrack=1;    
    
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas);
    
    % Get data from GUI
    setting=get(handles.puSNRFilter,'Value');
        
    % Set filter requested
    switch setting
        case 1 % Auto
            s.WTsnrFilter='Auto';            
                                     
        case 2 % Off
            s.WTsnrFilter='Off';
    end
    
    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;  
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);
    
    % Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);
    
% Interpolation settings

function puWTInterp_Callback(hObject, eventdata, handles)
% Processes the water track ensemble interplation selected by the user
    % Apply cell interpolation prior to ensemble interpolation

        handles.pltShiptrack=1;
    
    % Get measurement data
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas);
    
    % Get data from GUI
    setting=get(handles.puWTInterp,'Value');
    
    % Apply selected interpolation method
    switch setting
        case 1 % None
            % Sets invalid data to nan with no interpolation
            s.WTEnsInterpolation='None';
            
        case 2 % Expanded Ensemble Time
            % Applies a method similar to TRDI by using the next valid data
            % to back fill. If both BT and WT are set to expanded time it
            % should replicate TRDI's method
            s.WTEnsInterpolation='ExpandedT';
            
        case 3 % SonTek Method
            % Interpolates using SonTeks method of holding last valid for
            % up to 9 samples.
            s.WTEnsInterpolation='Hold9';
            
        case 4 % Hold Last Valid
            % Interpolates by holding last valid indefinitely
            s.WTEnsInterpolation='Hold';             
            
        case 5 % Linear
            % Interpolates using linear interpolation
            s.WTEnsInterpolation='Linear'; 
            
        case 6 % TRDI
            % TRDI interpolation done in discharge
            s.WTEnsInterpolation='TRDI'; 
    end
    
    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);

    %Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);

function puWTCellInterp_Callback(hObject, eventdata, handles)
% Processes the water track cell interplation selected by the user 
    
    handles.pltShiptrack=1;

    % Get measurement data
    meas=handles.meas;
    s=clsMeasurement.currentSettings(meas); 
    
    % Get data from GUI
    setting=get(handles.puWTCellInterp,'Value');
    
    % Apply selected interpolation method
    switch setting
        case 1 % None
            % Sets invalid data to nan with no interpolation
            s.WTCellInterpolation='None';
            
        case 2 % TRDI
            % Use TRDI method to interpolate invalid interior cells
            % clsQComp
            s.WTCellInterpolation='TRDI';            
            
        case 3 % Linear All
            % Uses linear interpolation to interpolate velocity for all
            % invalid bins including those in invalid ensembles.
            % up to 9 samples.
            s.WTCellInterpolation='Linear';
    end % switch

    % Recompute discharge
    oldDischarge=meas.discharge;
    oldpointer = get(gcf, 'pointer');      
    set(gcf, 'pointer', 'watch');     
    drawnow;     
    meas=applySettings(meas,s);     
    set(gcf, 'pointer', oldpointer);     
    drawnow;
    
    % Update table data
    handles=updateTable(handles,meas,oldDischarge);
    
    % Store data
    setappdata(handles.hMainGui,'measurement',meas);

    %Update graphics
    rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);
    
% Other user events

function pbComment_Callback(hObject, eventdata, handles)
% Add comment
    [handles]=commentButton(handles, 'WT');
    % Update handles structure
    guidata(hObject, handles);
    
function pbHelp_Callback(hObject, eventdata, handles)
% hObject    handle to pbHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%open('helpFiles\QRev_Users_Manual.pdf') 
web('QRev_Help_Files\HTML\wt_filters.htm')

function pbClose_Callback(hObject, eventdata, handles)
    delete (handles.output);    

function tblWTFilters_CellSelectionCallback(hObject, eventdata, handles)
% Handles file selection to be plotted. Allows the selection to work as
% radio buttons so that only one file can be selected

    % Determine row selected
    selection = eventdata.Indices(:,1);
    
    % If statement due to code executed twice. Not sure why but this fixes
    % the problem.
    if ~isempty(selection)
        % Get table data
        tableData=get(handles.tblWTFilters,'Data');
        handles.plottedTransect=selection;
        idxStop=findstr(tableData{handles.plottedTransect,1},'</');
        if isempty(idxStop)
            fileName=tableData{handles.plottedTransect,1};
        else
            idxStart=findstr(tableData{handles.plottedTransect,1}(1:idxStop),'>');
            fileName=tableData{handles.plottedTransect,1}(idxStart(end)+1:idxStop(1)-1);
        end
        set(handles.plottedtxt,'String',fileName);
        % Update graphics
        cla(handles.axTop);
        cla(handles.axBottom);
        cla(handles.axAll);
        cla(handles.axShipTrack);
        handles.pltShiptrack=1;
        rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
        guidata(hObject, handles);
    end
    


% Graphics Functions ******************************************************

function rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
% Processes selected graphics output      
    
    % Get measurement data
    meas=handles.meas;
    transect=meas.transects(handles.checkedIdx(handles.plottedTransect));
    validData=transect.wVel.validData;
    navRef=transect.boatVel.selected;
    depthRef=transect.depths.selected;
%     if nansum(nansum(validData(:,:,1)))>0
        radioTag=get(get(handles.rbGraphicsPanel,'SelectedObject'),'Tag');

        % Compute track
        boatU=transect.boatVel.(navRef).u_mps;
        boatV=transect.boatVel.(navRef).v_mps;
        ensDuration=transect.dateTime.ensDuration_sec;
        boatX=nancumsum(boatU.*ensDuration);
        boatY=nancumsum(boatV.*ensDuration);

        % Compute processed track
        boatUProcessed=transect.boatVel.(navRef).uProcessed_mps;
        boatVProcessed=transect.boatVel.(navRef).vProcessed_mps;    
        boatXProcessed=nancumsum(boatUProcessed.*ensDuration);
        boatYProcessed=nancumsum(boatVProcessed.*ensDuration);

        % Create ensemble numbers
        ensembles=1:length(boatUProcessed);

        % Compute water speed
        wSpeed=sqrt(transect.wVel.u_mps.^2+transect.wVel.v_mps.^2);
        wSpeed(~validData(:,:,1))=nan;
        wSpeedProcessed=sqrt(transect.wVel.uProcessed_mps.^2+transect.wVel.vProcessed_mps.^2);
        

        % Compute mean water velocity
        meanVelX=nanmean(transect.wVel.uProcessed_mps);
        meanVelY=nanmean(transect.wVel.vProcessed_mps);

        % Get depths
        depth=transect.depths.(depthRef).depthProcessed_m;
        depthCellSizeMatrix=transect.depths.(depthRef).depthCellSize_m;
        depthCellDepthMatrix=transect.depths.(depthRef).depthCellDepth_m;

        % Valid data
        rawValidData=validData(:,:,2);
        boatValidData=~isnan(boatUProcessed);
        depthValidData=~isnan(depth);
        ensValid=all([boatValidData; depthValidData]);
        rawValidData(:,~ensValid)=false;
        combValid=validData(:,:,1)+rawValidData;
        allValidData=combValid>1;

        % Generate selected plot
        switch radioTag
            case 'rbThreeBeam' % 3 beam filter
                pltBeams( hObject,handles,transect, ensembles )
                linkaxes([handles.axTop, handles.axBottom],'x');
            case 'rbDiffVel' % Difference velocity
                pltDiffVel(hObject,handles,transect,ensValid,ensembles)
                linkaxes([handles.axTop, handles.axBottom],'x');
            case 'rbVertVel' % Vertical velocity
                pltVertVel(hObject,handles,transect,ensValid,ensembles)
                linkaxes([handles.axTop, handles.axBottom],'x');
            case 'rbOther' % Smooth or other filter
                pltOther(hObject,handles,transect,wSpeed,ensembles)
                 
            case 'rbAll' % Plot results of all filters
                pltAll (hObject,handles,wSpeedProcessed,wSpeed,transect,ensembles)

            case 'rbSNR' % Plot SNR filter
                pltSNR(hObject,handles,transect,ensValid,ensembles)
                linkaxes([handles.axTop, handles.axBottom],'x');
            case 'rbInvalid' % Plot contour plot showing blanks for invalid data
                % Prep data
                wSpeedValid=wSpeedProcessed;
                wSpeedValid(~validData(:,:,1))=nan;
                if ~isempty(transect.boatVel.(transect.boatVel.selected))
                    navValid=transect.boatVel.(transect.boatVel.selected).validData;
                else
                    navValid=false(size(transect.boatVel.btVel.validData));
                end
                depthValidBeams=transect.depths.(transect.depths.selected).validData;
                depthValidData=nansum(depthValidBeams);
                depthValidData(depthValidData>0)=1;
                validEns=navValid(1,:) & depthValidData;
                wSpeedValid(:,~validEns)=nan;
                depthValid=depth;
                depthValid(~depthValidData)=nan;
                % Clear unused axes
                cla(handles.axAll);
                legend(handles.axAll,'off')
                cla(handles.axTop);
                % Set axes visibility
                set(handles.axTop,'Visible','on');
                set(handles.axBottom,'Visible','on');
                set(handles.axAll,'Visible','off');
                set(handles.axAll,'HandleVisibility','off');
                %Plot contour
                pltContour(hObject,handles,wSpeedValid,depthValid,depthCellDepthMatrix,depthCellSizeMatrix,ensembles,'Top')
                linkaxes([handles.axTop, handles.axBottom],'xy');
        end
        grid(handles.axAll,'On')
%          wSpeedProcessed=meas.discharge(handles.checkedIdx(handles.plottedTransect)).middleCells;
        pltContour(hObject,handles,wSpeedProcessed,depth,depthCellDepthMatrix,depthCellSizeMatrix,ensembles,'Bottom')
        
        if handles.pltShiptrack
            dataAboveSL=transect.wVel.cellsAboveSL;
            pltShiptrack(hObject,handles,boatX,boatY,boatXProcessed,boatYProcessed,meanVelX,meanVelY,validData,dataAboveSL)
            handles.pltShiptrack=0;
        end % if pltShipTrack

        % Reverse x axes if transect is collected right to left
        if strcmpi(transect.startEdge,'Right');
            set(handles.axTop,'XDir','reverse');
            set(handles.axBottom,'XDir','reverse');
            set(handles.axAll,'XDir','reverse');
        else
            set(handles.axTop,'XDir','normal');
            set(handles.axBottom,'XDir','normal');
            set(handles.axAll,'XDir','normal');
        end 
%     end
    
    % Update handles structure
    guidata(hObject, handles);
    
function [trackPlt,depthCellPlt,wVelPlt]=contourDataPrep(track,cellDepth,cellSize,vel)
    nMax=size(track,2);
    j=0;
    k=0;
    for n=1:nMax
        j=j+1;
        if n==1
            halfBack=abs(0.5.*(track(:,n+1)-track(:,n)));
            halfForward=abs(0.5.*(track(:,n+1)-track(:,n)));
        elseif n==nMax
            halfForward=abs(0.5.*(track(:,n)-track(:,n-1)));
            halfBack=abs(0.5.*(track(:,n)-track(:,n-1)));
        else
            halfBack=abs(0.5.*(track(:,n)-track(:,n-1)));
            halfForward=abs(0.5.*(track(:,n+1)-track(:,n)));
        end
        trackNew(:,j)=track(:,n)-halfBack;
        cellDepthNew(:,j)=cellDepth(:,n);
        velNew(:,j)=vel(:,n);
        cellSizeNew(:,j)=cellSize(:,n);
        j=j+1;
        trackNew(:,j)=track(:,n)+halfForward;
        cellDepthNew(:,j)=cellDepth(:,n);
        velNew(:,j)=vel(:,n);
        cellSizeNew(:,j)=cellSize(:,n);
    end

    nMax=size(cellSize,1);
    j=0;
    for n=1:nMax
        j=j+1;
        trackPlt(j,:)=trackNew(n,:);
        depthCellPlt(j,:)=cellDepthNew(n,:)-0.5.*cellSizeNew(n,:);
        wVelPlt(j,:)=velNew(n,:);
        j=j+1;
        trackPlt(j,:)=trackNew(n,:);
        depthCellPlt(j,:)=cellDepthNew(n,:)+0.5.*cellSizeNew(n,:);
        wVelPlt(j,:)=velNew(n,:);
    end        
    
function pltBeams(hObject,handles,transect,xVar)
% Plots number of beams time series on top axes

    % Clear unused axes
    cla(handles.axAll);
    legend(handles.axAll,'off')
    cla(handles.axTop);
    
    % Set axes visibility
    set(handles.axTop,'Visible','on');
    set(handles.axBottom,'Visible','on');
    set(handles.axAll,'Visible','off');
    set(handles.axAll,'HandleVisibility','off');

    % Compute variable containing number of beams for valid cells
    temp=transect.wVel;
    temp=applyFilter(temp,transect,'Beam',4);
    tempSelectedValidData=temp.validData(:,:,6)&temp.validData(:,:,7);
    topData=double(tempSelectedValidData);
    topData(tempSelectedValidData)=4;
    topData(~tempSelectedValidData)=3;
    topData(~transect.wVel.validData(:,:,2))=nan;

    % Get beam filter results
    filteredValidData=transect.wVel.validData(:,:,6)&transect.wVel.validData(:,:,7);

    % Compute x coordinates for plot
    xPlt=repmat(xVar,size(topData,1),1);

    % Plot top figure
    set(gcf,'CurrentAxes',handles.axTop);

    % Plot all valid data
    plot(handles.axTop,xPlt,topData,'.b');
    hold(handles.axTop,'on');
    
    markedInvalid=((~filteredValidData)&transect.wVel.validData(:,:,7)&transect.wVel.cellsAboveSL);
    % Circle data invalid based on beam filter
    plot(handles.axTop,xPlt(markedInvalid),topData(markedInvalid),'or');

    ylim(handles.axTop,[0,4]);

    xlabel(handles.axTop,'Ensembles');
    ylabel(handles.axTop,'Number of Beams');
    grid(handles.axTop,'On')
    hold(handles.axTop,'off');   
    
    % Update handles structure
    guidata(hObject, handles);
    
function pltDiffVel(hObject,handles,transect,ensValid,xVar)
    % Clear unused axes
    cla(handles.axAll);
    legend(handles.axAll,'off')
    cla(handles.axTop);
    
    % Set axes visibility
    set(handles.axTop,'Visible','on');
    set(handles.axBottom,'Visible','on');
    set(handles.axAll,'Visible','off');
    set(handles.axAll,'HandleVisibility','off');

    % Process data
    dVel=transect.wVel.d_mps;
    filteredValidData=transect.wVel.validData(:,:,3)&transect.wVel.validData(:,:,7);
    filteredValidData(:,~ensValid)=false;

    % Determine invalid difference velocity data
    rawValidData=transect.wVel.validData(:,:,2)&transect.wVel.validData(:,:,7);
    pltDiffInvalidData=(~filteredValidData)&rawValidData;
    
    % Compute x coordinates for plot
    xPlt=repmat(xVar,size(dVel,1),1);
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    

    % Plot top figure
    plot(handles.axTop,xPlt(rawValidData),dVel(rawValidData).*unitsV,'.b');
    hold(handles.axTop,'on');
    plot(handles.axTop,xPlt(pltDiffInvalidData),dVel(pltDiffInvalidData).*unitsV,'or');
    xlabel(handles.axTop,'Ensembles');
    ylabel(handles.axTop,['Error Velocity ',uLabelV]);
    grid(handles.axTop,'On')
    hold(handles.axTop,'off');
    
    % Update handles structure
    guidata(hObject, handles);

function pltVertVel(hObject,handles,transect,ensValid,xVar)

    % Clear unused axes
    cla(handles.axAll);
    legend(handles.axAll,'off')
    cla(handles.axTop);

    % Set axes visibility
    set(handles.axTop,'Visible','on');
    set(handles.axBottom,'Visible','on');
    set(handles.axAll,'Visible','off');       
    set(handles.axAll,'HandleVisibility','off');

    % Process data
    wVel=transect.wVel.w_mps;
    rawValidData=transect.wVel.validData(:,:,2)&transect.wVel.validData(:,:,7);
    filteredValidData=transect.wVel.validData(:,:,4)&transect.wVel.validData(:,:,7);
    filteredValidData(:,~ensValid)=false;
    pltDiffinvalidData=(~filteredValidData)&rawValidData;
    % Compute x coordinates for plot
    xPlt=repmat(xVar,size(wVel,1),1);

    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    
    
    % Plot top figure
    plot(handles.axTop,xPlt(rawValidData),wVel(rawValidData).*unitsV,'.b');
    hold(handles.axTop,'on');
    plot(handles.axTop,xPlt(pltDiffinvalidData),wVel(pltDiffinvalidData).*unitsV,'or');
    xlabel(handles.axTop,'Ensembles');
    ylabel(handles.axTop,['Vertical Velocity ',uLabelV]);      
    grid(handles.axTop,'On')
    hold(handles.axTop,'off');
    
    % Update handles structure
    guidata(hObject, handles);
    
function pltOther(hObject,handles,transect,wSpeed,xPlt)
    
    % Clear all axes
    cla(handles.axTop);
    cla(handles.axBottom);
    cla(handles.axAll);
    xlabel(handles.axBottom,'');
    ylabel(handles.axBottom,'');
    
    % Set axes visibility
    set(handles.axTop,'Visible','off');
    set(handles.axBottom,'Visible','off');
    set(handles.axAll,'Visible','on');
    set(handles.axAll,'HandleVisibility','on');

    % Get valid data logical array
    validData=transect.wVel.validData;
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    

    % Plot times series figure
    upperLimit=transect.wVel.smoothUpperLimit;
    lowerLimit=transect.wVel.smoothLowerLimit;
    upperLimit(isnan(upperLimit))=0;
    lowerLimit(isnan(lowerLimit))=0;
    legendStart=4;

    % If plot requested but smooth filter not applied area and
    % smooth should not be plotted
    if get(handles.puOtherFilter,'Value')>1                
        area(handles.axAll,xPlt,upperLimit.*unitsV,min(lowerLimit).*unitsV,'facecolor',...
            [0.8275 0.8275 0.8275],'edgecolor',[0.8275 0.8275 0.8275]);
        hold(handles.axAll,'on')
        area(handles.axAll,xPlt,lowerLimit.*unitsV,min(lowerLimit).*unitsV,'facecolor',...
            'white','edgecolor','white');
        plot(handles.axAll,xPlt,transect.wVel.smoothSpeed.*unitsV,'r');
        legendStart=1;
    end

    wSpeedAvg=nanmean(wSpeed);    
    plot (handles.axAll,xPlt,wSpeedAvg.*unitsV,'.-b');
    hold(handles.axAll,'on')
    invalid=(~validData(:,:,5))&(validData(:,:,2)&validData(:,:,7));
    invalid=any(invalid);
    plot(handles.axAll,xPlt(invalid),wSpeedAvg(invalid).*unitsV,'ok');
    xlabel(handles.axAll,'Ensembles');
    ylabel(handles.axAll,['Speed ',uLabelV]);
    axis tight;
    box(handles.axAll,'on');
    legendText={'Filter Limits',' ','Loess Smooth','Raw Data',...
            'Filtered Bad Data'};
    legend (handles.axAll,legendText(legendStart:end));
    legend (handles.axAll,'Location','NorthOutside');
    grid(handles.axTop,'On')
    hold off 
    
    % Update handles structure
    guidata(hObject, handles);
    
function pltAll (hObject,handles,wSpeedProcessed,wSpeed,transect,xPlt)

    % Clear all axes
    cla(handles.axTop);
    cla(handles.axBottom);
    cla(handles.axAll);
    xlabel(handles.axBottom,'');
    ylabel(handles.axBottom,'');
    
    % Set visibility
    set(handles.axTop,'Visible','off');
    set(handles.axBottom,'Visible','off');
    set(handles.axAll,'Visible','on');
    set(handles.axAll,'HandleVisibility','on');
    
    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);      
    
    % Plot interpolated data first
    if strcmpi(transect.wVel.interpolateEns,'None') && strcmpi(transect.wVel.interpolateCells,'None')
        % Plot raw data
        wSpeedAvg=nanmean(wSpeed); 
        plot(handles.axAll,xPlt,wSpeedAvg.*unitsV,'-b')
        hold(handles.axAll,'on')
        plotted=[false;true];  
        pltSpeed=wSpeedAvg;
    else
        wSpeedProcessedAvg=nanmean(wSpeedProcessed);
        plot(handles.axAll,xPlt,wSpeedProcessedAvg.*unitsV,'-r')
        hold(handles.axAll,'on')
        plotted=[true;true];
        % Plot raw data
        wSpeedAvg=nanmean(wSpeed); 
        plot(handles.axAll,xPlt,wSpeedAvg.*unitsV,'-b')
        pltSpeed=wSpeedProcessedAvg;
    end
    % Plot results of each filter in time series of speed
    
    pltSpeed(isnan(pltSpeed))=0;
    validData=transect.wVel.validData;
    invalid(1,:)=any((~validData(:,:,2))&validData(:,:,7));
    plot(handles.axAll,xPlt(invalid(1,:)),pltSpeed(invalid(1,:)).*unitsV,'xk');
    invalid(2,:)=any((~validData(:,:,3))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axAll,xPlt(invalid(2,:)),pltSpeed(invalid(2,:)).*unitsV,'*k');
    invalid(3,:)=any((~validData(:,:,4))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axAll,xPlt(invalid(3,:)),pltSpeed(invalid(3,:)).*unitsV,'sk');
    invalid(4,:)=any((~validData(:,:,5))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axAll,xPlt(invalid(4,:)),pltSpeed(invalid(4,:)).*unitsV,'ok');
    invalid(5,:)=any((~validData(:,:,6))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axAll,xPlt(invalid(5,:)),pltSpeed(invalid(5,:)).*unitsV,'dk');
    invalid(6,:)=any((~validData(:,:,7))&validData(:,:,2));
    plot(handles.axAll,xPlt(invalid(6,:)),pltSpeed(invalid(6,:)).*unitsV,'^k');
    invalid(7,:)=any((~validData(:,:,8))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axAll,xPlt(invalid(7,:)),pltSpeed(invalid(7,:)).*unitsV,'>k');
    invalid(8,:)=any((~validData(:,:,9))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axAll,xPlt(invalid(8,:)),pltSpeed(invalid(8,:)).*unitsV,'<k');
    plotted=logical([plotted;any(invalid,2)]);
    legendText={'Interpolated','Water Speed','Invalid Raw','Error Vel','Vertical Vel','Other','3-Beam','Excluded','SNR','Depth'};
    legend(handles.axAll,legendText{plotted},'Location','Northoutside')
    xlabel(handles.axAll,'Ensembles')
    ylabel(handles.axAll,['Water Speed ',uLabelV])
    grid(handles.axTop,'On')
    hold(handles.axAll,'off')
    
    % Update handles structure
    guidata(hObject, handles);
    
function pltSNR(hObject,handles,transect,ensValid,xVar)

    % Clear unused axes
    cla(handles.axAll);
    legend(handles.axAll,'off')
    cla(handles.axTop);

    % Set axes visibility
    set(handles.axTop,'Visible','on');
    set(handles.axBottom,'Visible','on');
    set(handles.axAll,'Visible','off');       
    set(handles.axAll,'HandleVisibility','off');

    % Process data
    snrRng=transect.wVel.snrRng;
    rawValidData=any(transect.wVel.validData(:,:,2)&transect.wVel.validData(:,:,7));
    filteredValidData=any(transect.wVel.validData(:,:,8)&transect.wVel.validData(:,:,7));
    filteredValidData(~ensValid)=false;
    pltDiffinvalidData=(~filteredValidData)&rawValidData;
    % Compute x coordinates for plot
    xPlt=xVar;

    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);    
    
    % Plot top figure
    plot(handles.axTop,xPlt(rawValidData),snrRng(rawValidData),'.b');
    hold(handles.axTop,'on');
    plot(handles.axTop,xPlt(pltDiffinvalidData),snrRng(pltDiffinvalidData),'or');

    xlabel(handles.axTop,'Ensembles');
    ylabel(handles.axTop,'SNR Range (dB)');  
    grid(handles.axTop,'On')
    hold(handles.axTop,'off');
    
    % Update handles structure
    guidata(hObject, handles);
    
function pltContour(hObject,handles,wSpeedProcessed,depth,depthCellDepthMatrix,depthCellSizeMatrix,xVar,location)
   
    if strcmpi('Top',location)
        h=handles.axTop;
    else
        h=handles.axBottom;
    end

    % Plot bottom figure, not visible if all plotted
    vis=get(h,'Visible');            

    % Plot if visible
    if strcmpi(vis,'on')
        % Intialize axes
        cla(h);
        set(handles.figure1,'CurrentAxes',h);
        hold (h,'off')
        
        % Get units multiplier
        [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);          
        
        % Compute water speed
         wVelMatrix=wSpeedProcessed;

        wVelMatrix(isnan(wVelMatrix))=-999;
        
        % Create matrices for plotting contour plot
        xPltMatrix=repmat(xVar,size(depthCellSizeMatrix,1),1);

        % Prepare data to properly plot variable bin sizes
        [trackPlt,depthCellPlt,wVelPlt]=contourDataPrep(xPltMatrix,depthCellDepthMatrix,depthCellSizeMatrix,wVelMatrix);
        validData=~isnan(wSpeedProcessed);
    if nansum(nansum(validData(:,:,1)))>0
        % Prepare colormap
        maxLimit=nanmax(nanmax(wSpeedProcessed));
        maxLimit=prctile(nanmax(wSpeedProcessed),95);
        minLimit=-1.*maxLimit/64;
        caxis([minLimit.*unitsV,maxLimit.*unitsV]);
        colormap('jet');
        cmap=ones(size(colormap,1)+1,size(colormap,2));
        cmap(2:end,:)=colormap;
        colormap(cmap);
        
        % Creat contour plot
        h_surface=surface(trackPlt,depthCellPlt.*unitsL,wVelPlt.*unitsV);
        set(h_surface,'EdgeColor','none');
    end
        % Add cross section
        hold(h,'on')
        plot(h,xVar,depth.*unitsL,'-k')                  
        set(h,'YDir','reverse');
        
         
        xlabel(h,'Ensembles');
        ylabel(h,['Depth ',uLabelL]);
        ylim(h,[0,nanmax(depth.*unitsL)])
        xlim(h,[nanmin(xVar)-1,nanmax(xVar)+1])
        box('on');
        if strcmpi('Bottom',location)
            title(h,['Processed Water Speed ',uLabelV]);
            colorbar('Location','Northoutside');
        else
            title(h,['Filtered Water Speed ',uLabelV]);
        end
        grid(h,'Off')
        hold(h,'off')
    end
    
    set(h,'Visible',vis);
    
    % Update handles structure
    guidata(hObject, handles);
    
function pltShiptrack(hObject,handles,boatX,boatY,boatXProcessed,boatYProcessed,meanVelX,meanVelY,validData,dataAboveSL)
% Plot shiptrack using same line and symbol properties

    % Get units multiplier
    [unitsL,unitsQ,unitsA,unitsV,uLabelL,uLabelQ,uLabelA,uLabelV]=clsMeasurement.unitsMultiplier(handles);  
    
    % Plot processed ship track and velocity vectors
    plot(handles.axShipTrack,boatXProcessed.*unitsL,boatYProcessed.*unitsL,'-r','LineWidth',3);
    hold(handles.axShipTrack,'on')
    plot(handles.axShipTrack,boatXProcessed(end).*unitsL,boatYProcessed(end).*unitsL,'sk','MarkerFaceColor','k','MarkerSize',8);
    quiver(handles.axShipTrack,boatXProcessed.*unitsL,boatYProcessed.*unitsL,meanVelX.*unitsV,meanVelY.*unitsV,'b','ShowArrowHead','on','AutoScaleFactor',5);%,...

    % Plot raw ship track with invalid data identified
    plot(handles.axShipTrack,boatX.*unitsL,boatY.*unitsL,'-k')
    invalid(1,:)=any((~validData(:,:,2))&validData(:,:,7));
    plot(handles.axShipTrack,boatX(invalid(1,:)).*unitsL,boatY(invalid(1,:)).*unitsL,'xk');
    invalid(2,:)=any((~validData(:,:,3))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axShipTrack,boatX(invalid(2,:)).*unitsL,boatY(invalid(2,:)).*unitsL,'*k');
    invalid(3,:)=any((~validData(:,:,4))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axShipTrack,boatX(invalid(3,:)).*unitsL,boatY(invalid(3,:)).*unitsL,'sk');
    invalid(4,:)=any((~validData(:,:,5))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axShipTrack,boatX(invalid(4,:)).*unitsL,boatY(invalid(4,:)).*unitsL,'ok');
    invalid(5,:)=any((~validData(:,:,6))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axShipTrack,boatX(invalid(5,:)).*unitsL,boatY(invalid(5,:)).*unitsL,'dk');
    invalid(6,:)=any((~validData(:,:,7))&validData(:,:,2));
    plot(handles.axShipTrack,boatX(invalid(6,:)).*unitsL,boatY(invalid(6,:)).*unitsL,'>k');
    invalid(7,:)=any((~validData(:,:,8))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axShipTrack,boatX(invalid(7,:)).*unitsL,boatY(invalid(7,:)).*unitsL,'>k');
    invalid(8,:)=any((~validData(:,:,9))&(validData(:,:,2)&validData(:,:,7)));
    plot(handles.axShipTrack,boatX(invalid(8,:)).*unitsL,boatY(invalid(8,:)).*unitsL,'<k');
    
    hold(handles.axShipTrack,'off')
    
    plotted=[true;true;true;true;any(invalid,2)];
    legendText={'Processed','End','Water Vel','Raw','Invalid Raw','Error Vel','Vertical Vel','Other','3-Beam','Excluded','SNR','Depth'};
    legend(handles.axShipTrack,legendText{plotted},'Location','Northwest')
    set(handles.axShipTrack,'DataAspectRatio',[1 1 1]);
    set(handles.axShipTrack,'Box','on');
    set(handles.axShipTrack,'PlotBoxAspectRatio',[1 1 1]);
    xlabel(handles.axShipTrack,['Distance East ',uLabelL]);
    ylabel(handles.axShipTrack,['Distance North ',uLabelL]);
    grid(handles.axShipTrack,'On')
    % Update handles structure
    guidata(hObject, handles);
    
    % --- Executes on key press with focus on tblGPS and none of its controls.
function tblWTFilters_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to tblGPS (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)    

% Make table inactive to avoid synching issues associated with multiple
% keypresses before the processing of the first can be completed.
set(handles.tblWTFilters,'Enable','inactive');

if strcmp(eventdata.Key,'uparrow') || strcmp(eventdata.Key,'downarrow')
    tableData=get(handles.tblWTFilters,'Data');

    rowTrue=handles.plottedTransect;
    if strcmp(eventdata.Key,'downarrow')
        if rowTrue+1<=size(tableData,1)
            newRow=rowTrue+1;          
        else
            newRow=size(tableData,1);
        end
    elseif strcmp(eventdata.Key,'uparrow')
        if rowTrue-1>0
            newRow=rowTrue-1;
        else
            newRow=1;
        end
    end

    set(handles.plottedtxt,'String',tableData{newRow,1});
    handles.plottedTransect=newRow;
    
%     idxStop=findstr(tableData{newRow,1},'</');
%     idxStart=findstr(tableData{newRow,1}(1:72),'>');
%     fileName=tableData{newRow,1}(idxStart(end)+1:idxStop(1)-1);
%     set(handles.plottedtxt,'String',fileName);
%     handles.plottedTransect=newRow;
    drawnow

    % Update graphics
        cla(handles.axTop);
        cla(handles.axBottom);
        cla(handles.axAll);
        cla(handles.axShipTrack);
        handles.pltShiptrack=1;
    handles.pltShiptrack=1;
     rbGraphicsPanel_SelectionChangeFcn(hObject, eventdata, handles)
    guidata(hObject, handles);
    drawnow
end    
set(handles.tblWTFilters,'Enable','on');
    
%==========================================================================
%================NO MODIFIED CODE BELOW HERE===============================
%==========================================================================
function rbThreeBeam_Callback(hObject, eventdata, handles)

function rbDiffVel_Callback(hObject, eventdata, handles)

function rbVertVel_Callback(hObject, eventdata, handles)

function rbOther_Callback(hObject, eventdata, handles)

function rbAll_Callback(hObject, eventdata, handles)

function edDiffVelThreshold_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function textTableQ_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function puWTInterp_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function puOtherFilter_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function edVertVelThreshold_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function puVertVel_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function pu3Beam_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function puDiffVel_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    


% --- Executes when entered data in editable cell(s) in tblWTFilters.
function tblWTFilters_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to tblWTFilters (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function puWTCellInterp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to puWTCellInterp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% Hints: get(hObject,'String') returns contents of edExcludedDist as text
%        str2double(get(hObject,'String')) returns contents of edExcludedDist as a double


% --- Executes during object creation, after setting all properties.
function edExcludedDist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edExcludedDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end







% --- Executes during object creation, after setting all properties.
function puSNRFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to puSNRFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

 
