function varargout = winExtrap(varargin)
%WINEXTRAP M-file for winExtrap.fig
%      WINEXTRAP, by itself, creates a new WINEXTRAP or raises the existing
%      singleton*.
%
%      H = WINEXTRAP returns the handle to a new WINEXTRAP or the handle to
%      the existing singleton*.
%
%      WINEXTRAP('Property','Value',...) creates a new WINEXTRAP using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to winExtrap_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      WINEXTRAP('CALLBACK') and WINEXTRAP('CALLBACK',hObject,...) call the
%      local function named CALLBACK in WINEXTRAP.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help winExtrap

% Last Modified by GUIDE v2.5 13-Jun-2017 13:29:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @winExtrap_OpeningFcn, ...
                   'gui_OutputFcn',  @winExtrap_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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

% --- Executes just before winExtrap is made visible.
function winExtrap_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for winExtrap
handles.output = hObject;

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
    %meas=handles.meas;
    meas=varargin{1};
    handles.meas=meas;
    %set(gcf,'CloseRequestFcn',{@optionalClose,handles});
    % Initialize custom handles data structure variables
    extrapGui.draftUnits='M';
    extrapGui.pathName=pwd;
    extrapGui.backup=handles;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Number of checked transects
    nChecked=length(idxTrans); 
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    
    % Populate the transect list box in the GUI
    for n=1:nChecked
        idx=find(meas.transects(idxTrans(n)).fileName=='\',1,'last');
        if isempty(idx)
            idx=0;
        end
        fileName{n}=meas.transects(idxTrans(n)).fileName(idx+1:end);
    end % for n
    fileName{nChecked+1}='Measurement';
    set(handles.listFiles,'String',fileName);
    set(handles.listFiles,'Value',nChecked+1);
    
    % Set GUI defaults
    if strcmp(meas.extrapFit.selFit(end).fitMethod,'Manual')
        set(handles.puFit,'Value',2);
        set(handles.puTop,'Enable','on');
        set(handles.puBottom,'Enable','on');
        set(handles.edExp,'Enable','on');        
    else
        set(handles.puFit,'Value',1);    
        set(handles.puTop,'Enable','off');
        set(handles.puBottom,'Enable','off');
        set(handles.edExp,'Enable','off');
    end % if manual


    updateFit(handles,meas);
    plotTrans(handles,meas);
    displayNos(meas.extrapFit.normData(end),handles.zpts_table)
    displayTable(meas.extrapFit,handles.q_table)
    
    % Update Current Extrapolations
    [topChk,botChk,expChk,~,~,~]=clsTransectData.checkConsistency(meas.transects);
    set(handles.txtTop,'String',topChk);
    set(handles.txtBot,'String',botChk);
    set(handles.txtExp,'String',num2str(expChk,'%0.4f'));
    drawnow;

    % Update handles structure
    guidata(hObject, handles);

function varargout = winExtrap_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function optionalClose(hObject,eventdata,handles)
    selection = questdlg('Do you want to save or cancel any changes?',...
                     'Close Request Function',...
                     'Save','Cancel','Cancel');
switch selection,
   case 'Save',
     pbClose_Callback(hObject, eventdata, handles)
   case 'Cancel'
     pbCancel_Callback(hObject, eventdata, handles)
end

function pbClose_Callback(hObject, eventdata, handles)
    % Retrieve data
    meas=handles.meas;
    extents=meas.extrapFit.normData.dataExtent;
    threshold=meas.extrapFit.threshold;
    type=meas.extrapFit.normData.dataType;
    
    % Check for changes to default settings
    if (extents(1)==0 && extents(2)==100 && threshold==20 && strcmp(type,'q')) || strcmpi(meas.extrapFit.fitMethod,'Manual')
        % Recompute discharge
        meas=changeExtrapolation(meas);   
        s=clsMeasurement.currentSettings(meas);
        oldpointer = get(gcf, 'pointer');      
        set(gcf, 'pointer', 'watch');     
        drawnow;     
        meas=applySettings(meas,s);     
        set(gcf, 'pointer', oldpointer);     
        drawnow;
        handles.meas = meas;
        delete(handles.winExtrap);
    else
        % If defaults were changed and Automatic used, issue warning
        warndlg('The data have been subsectioned, the threshold changed,or the data type changed to velocity. To save the fit based on these changes set the fit to Manual and then click OK again.','Subsection/Threshold/Type warning');           
    end 
    
function pbCancel_Callback(hObject, eventdata, handles)
% hObject    handle to pbCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)    
    % Get data 
    meas=handles.meas;
    % Store data
    handles.meas = meas;
    % Update handles structure
    guidata(hObject, handles);
    
    delete (handles.output); 
    
% Fit Callbacks
% =============

function listFiles_Callback(hObject, eventdata, handles)
% Allows the user to select which transect is plotted in the transect graph
 
    % Get data
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    set(handles.winExtrap,'Pointer','watch');
    drawnow;
    
    % Update graph
    plotTrans(handles,meas)

    % Update fit configuration for the transect
    selFit=meas.extrapFit.selFit;
    itrans=get(handles.listFiles,'Value');
    if strcmpi(selFit(idxTrans(itrans)).fitMethod,'Automatic')
        set(handles.puFit,'Value',1);
        set(handles.puTop,'Enable','off');
        set(handles.puBottom,'Enable','off');
        set(handles.edExp,'Enable','off');
        set(handles.slExp,'Enable','off');
    else
        set(handles.puFit,'Value',2);
        set(handles.puTop,'Enable','on');
        set(handles.puBottom,'Enable','on');
        set(handles.edExp,'Enable','on');
        set(handles.slExp,'Enable','on');
    end
    updateFit(handles,meas);
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;
    
function puFit_Callback(hObject, eventdata, handles)

    % Get data 
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    set(handles.winExtrap,'Pointer','watch');
    drawnow;
    ifile=get(handles.listFiles,'Value');

    % Fit set to Automatic
    % --------------------
    if get(handles.puFit,'Value')==1
        set(handles.puTop,'Enable','off');
        set(handles.puBottom,'Enable','off');
        set(handles.edExp,'Enable','off');
        set(handles.slExp,'Enable','off');

        % Compute selected fit
        % --------------------
        meas.extrapFit=changeFitMethod(meas.extrapFit,meas.transects,'Automatic',idxTrans(ifile));
        
        updateFit(handles,meas);
        plotTrans(handles,meas); 
    else
        
        % Fit set to Manual
        % -----------------
        topi=get(handles.puTop,'Value');
        topMethod=get(handles.puTop,'String');
        boti=get(handles.puBottom,'Value');
        botMethod=get(handles.puBottom,'String');
        exponent=str2double(get(handles.edExp,'String'));
        meas.extrapFit=changeFitMethod(meas.extrapFit,meas.transects,'Manual',idxTrans(ifile),'All',topMethod{topi},botMethod{boti},exponent);
        
        set(handles.puTop,'Enable','on');
        set(handles.puBottom,'Enable','on');
        set(handles.edExp,'Enable','on');
        set(handles.slExp,'Enable','on');
    end
    
    %%displayTable(meas.extrapFit,handles.q_table);
    updateFit(handles,meas);
    
    % Store data    
    handles.meas=meas;   

    
    % Update handles structure
    guidata(hObject, handles);  
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;

function puTop_Callback(hObject, eventdata, handles)

    % Get data 
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    set(handles.winExtrap,'Pointer','watch');
    drawnow;
    % Retrieve data
    % -------------
    ifile=get(handles.listFiles,'Value');
    
    % Set new exponent and recompute
    % ------------------------------
    topi=get(handles.puTop,'Value');
    topMethods=get(handles.puTop,'String');
    boti=get(handles.puBottom,'Value');
    botMethod=get(handles.puBottom,'String');
    exponent=str2double(get(handles.edExp,'String'));
    meas.extrapFit=changeFitMethod(meas.extrapFit,meas.transects,'Manual',idxTrans(ifile),'All',topMethods{topi},botMethod{boti},exponent);

    handles.meas = meas;
    
    updateFit(handles,meas); 

    %displayTable(meas.extrapFit,handles.q_table);

    % Update handles structure
    % ------------------------
    guidata(hObject, handles);

    % Update graphs
    % -------------
     plotTrans(handles,meas)

    % Update handles structure
    % ------------------------
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;

function puBottom_Callback(hObject, eventdata, handles)

    % Get data 
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    set(handles.winExtrap,'Pointer','watch');
    drawnow;
    % Identify file/measurement
    ifile=get(handles.listFiles,'Value');
    
    % Set new exponent and recompute
    topi=get(handles.puTop,'Value');
    topMethods=get(handles.puTop,'String');
    boti=get(handles.puBottom,'Value');
    botMethod=get(handles.puBottom,'String');
    exponent=str2double(get(handles.edExp,'String'));
    meas.extrapFit=changeFitMethod(meas.extrapFit,meas.transects,'Manual',idxTrans(ifile),'All',topMethods{topi},botMethod{boti},exponent);

    handles.meas = meas;    
    
    % Update GUI
    updateFit(handles,meas);
    
    %displayTable(meas.extrapFit,handles.q_table);

    % Update handles structure
    guidata(hObject, handles);

    % Update graphs
     plotTrans(handles,meas)

    % Update handles structure
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;   
    
function edExp_Callback(hObject, eventdata, handles)

    % Get data 
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    set(handles.winExtrap,'Pointer','watch');
    drawnow;

    % Identify file/measurement
    ifile=get(handles.listFiles,'Value');
    
    % Set new exponent and recompute
    topi=get(handles.puTop,'Value');
    topMethods=get(handles.puTop,'String');
    boti=get(handles.puBottom,'Value');
    botMethod=get(handles.puBottom,'String');
    exponent=str2double(get(handles.edExp,'String'));
    meas.extrapFit=changeFitMethod(meas.extrapFit,meas.transects,'Manual',idxTrans(ifile),'All',topMethods{topi},botMethod{boti},exponent);

    handles.meas = meas;    
    
    % Update GUI
    updateFit(handles,meas);
    
    %displayTable(meas.extrapFit,handles.q_table);

    % Update handles structure
    % ------------------------
    guidata(hObject, handles);

    % Update graphs
    % -------------
     plotTrans(handles,meas)

    % Update handles structure
    % ------------------------
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;
    
function slExp_Callback(hObject, eventdata, handles)

    % Get data
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    set(handles.winExtrap,'Pointer','watch');
    drawnow;

    % Identify file/measurement
    ifile=get(handles.listFiles,'Value');

    % Get new exponent and recompute 
    topi=get(handles.puTop,'Value');
    topMethods=get(handles.puTop,'String');
    boti=get(handles.puBottom,'Value');
    botMethod=get(handles.puBottom,'String');
    exponent=get(handles.slExp,'Value');
    meas.extrapFit=changeFitMethod(meas.extrapFit,meas.transects,'Manual',idxTrans(ifile),'All',topMethods{topi},botMethod{boti},exponent);

    handles.meas = meas;
     
    % Update GUI
    updateFit(handles,meas);
    drawnow;
    %%displayTable(meas.extrapFit,handles.q_table);

    % Update handles structure
    % ------------------------
    guidata(hObject, handles);

    % Update graphs
    % -------------
     plotTrans(handles,meas)

    % Update handles structure
    % ------------------------
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;
    
function pbApply_Callback(hObject, eventdata, handles)  
    
    % Update handles structure
    guidata(hObject, handles);
    
    
% Data callbacks
% ==============

function pbThresh_Callback(hObject, eventdata, handles)
    set(handles.winExtrap,'Pointer','watch');
    drawnow;

    % Get data
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;    
    % Prompt for new threshold value, showing existing value as default
    threshold=meas.extrapFit.threshold;
    temp1=sprintf('Current threshold is %i percent \nEnter new threshold value in percent:',threshold);
    temp=inputdlg(temp1,'Threshold',1,{num2str(threshold)});
    if ~isempty(temp)   
        
        % Get new threshold in handles data structure
        threshold=str2double(temp);

        % Reprocess data with new threshold value
        % ---------------------------------------
        meas.extrapFit=changeThreshold(meas.extrapFit,meas.transects,meas.extrapFit.normData(end).dataType,threshold);

        %%displayTable(meas.extrapFit,handles.q_table);
        itrans=get(handles.listFiles,'Value');
        displayNos(meas.extrapFit.normData(idxTrans(itrans)),handles.zpts_table);
        updateFit(handles,meas);
        
        % Store data
        handles.meas = meas;

        % Update handles structure
        guidata(hObject, handles);

        % Update graphs
         plotTrans(handles,meas)

        % Update handles structure
        guidata(hObject, handles);

        set(handles.winExtrap,'Pointer','arrow');
        drawnow;
    end % if empty

function pbSubsection_Callback(hObject, eventdata, handles)
    % Set cursor to busy
    set(handles.winExtrap,'Pointer','watch');
    drawnow;

    % Get data
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;    
    % Show existing extents in the user dialog for new extents
    % ---------------------------------------------------------
    extents=meas.extrapFit.normData.dataExtent;
    temp=inputdlg({'Enter lower discharge limit in percent:';'Enter upper discharge limit in percent:'}...
        ,'Discharge Extents',1,{num2str(extents(1)) num2str(extents(2))});
    if ~isempty(temp)  
        % Reprocess data with new threshold value
        extents(1)=str2double(temp(1));
        extents(2)=str2double(temp(2));
        meas.extrapFit=changeExtents(meas.extrapFit,meas.transects,meas.extrapFit.normData(end).dataType,extents);

        %%displayTable(meas.extrapFit,handles.q_table);
        itrans=get(handles.listFiles,'Value');
        displayNos(meas.extrapFit.normData(idxTrans(itrans)),handles.zpts_table);
        updateFit(handles,meas);
        
        % Store data
        handles.meas = meas;

        % Update handles structure
        guidata(hObject, handles);

        % Update graphs
         plotTrans(handles,meas)

        % Update handles structure
        guidata(hObject, handles);

        set(handles.winExtrap,'Pointer','arrow');
        drawnow;
    end % if empty
    
function puData_Callback(hObject, eventdata, handles)
    % Set cursor to busy
    set(handles.winExtrap,'Pointer','watch');
    drawnow;

    % Get data
    meas=handles.meas;
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    if get(handles.puData,'Value')==1
        dataType='q';
    else
        dataType='v';
    end
    meas.extrapFit=changeDataType(meas.extrapFit,meas.transects,dataType);
    %%displayTable(meas.extrapFit,handles.q_table);
    itrans=get(handles.listFiles,'Value');
    displayNos(meas.extrapFit.normData(idxTrans(itrans)),handles.zpts_table);
    updateFit(handles,meas);

    % Store data
    handles.meas = meas;

    % Update handles structure
    guidata(hObject, handles);

    % Update graphs
     plotTrans(handles,meas)

    % Update handles structure
    guidata(hObject, handles);

    set(handles.winExtrap,'Pointer','arrow');
    drawnow;
    
function pbComment_Callback(hObject, eventdata, handles)
% Add comment
    [handles]=commentButton(handles, 'Extrapolation');
    % Update handles structure
    guidata(hObject, handles);
    
function pbHelp_Callback(hObject, eventdata, handles)
% hObject    handle to pbHelp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%open('helpFiles\QRev_Users_Manual.pdf')  
web('QRev_Help_Files\HTML\extrapolation.htm')
    
% Plot Callbacks
% ==============

function cbCells_Callback(hObject, eventdata, handles)

   set(handles.winExtrap,'Pointer','watch');

    % Get data
    meas=handles.meas;
    
    % Update graphs
     plotTrans(handles,meas)

    % Update handles structure
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;

function cbSurfCells_Callback(hObject, eventdata, handles)
   set(handles.winExtrap,'Pointer','watch');
 
    % Get data
    meas=handles.meas;
    
    % Update graphs
     plotTrans(handles,meas)

    % Update handles structure
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;

function cbTransMed_Callback(hObject, eventdata, handles)
   set(handles.winExtrap,'Pointer','watch');
     
    % Get data
    meas=handles.meas;
    
    % Update graphs
     plotTrans(handles,meas)

    % Update handles structure
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;

function cbTransFit_Callback(hObject, eventdata, handles)
   set(handles.winExtrap,'Pointer','watch');

    % Get data
    meas=handles.meas;
    
    % Update graphs
     plotTrans(handles,meas)

    % Update handles structure
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;

function cbMeasMed_Callback(hObject, eventdata, handles)
   set(handles.winExtrap,'Pointer','watch');
   
    % Get data
    meas=handles.meas;
    
    % Update graphs
     plotTrans(handles,meas)

    % Update handles structure
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;

function cbMeasFit_Callback(hObject, eventdata, handles)
   set(handles.winExtrap,'Pointer','watch');

    % Get data
    meas=handles.meas;
    
    % Update graphs
     plotTrans(handles,meas)

    % Update handles structure
    guidata(hObject, handles);
    
    set(handles.winExtrap,'Pointer','arrow');
    drawnow;

% Plot functions
% ==============

function plotTrans(handles,meas)
% This function updates the trans_axes of the GUI with the selected data and
% profile fits.

    % Get axes handle and clear axes
    cla(handles.axProfile);

    % Get data from handles data structure
    % ------------------------------------
    % Index of checked transects
    idxTrans=find([meas.transects.checked]==1);
    % Adjust index to include composite of measurement
    idxTrans(end+1)=length([meas.transects.checked])+1;
    itrans=get(handles.listFiles,'Value');
    threshold=meas.extrapFit.threshold;
    nfiles=length(get(handles.listFiles,'string'))-1;
    selFit=meas.extrapFit.selFit;
    normData=meas.extrapFit.normData;
    transData=meas.transects;
    
    if nansum(nansum(normData(idxTrans(itrans)).unitNormalized))>0
        % Plot cell data
        % --------------
        if get(handles.cbCells,'Value')==1
            plotRaw(normData(idxTrans(itrans)),handles.axProfile);
        end

        % Highlight surface cells
        % -----------------------
        if get(handles.cbSurfCells,'Value')==1
            plotSurface(normData(idxTrans(itrans)),handles.axProfile);
        end

        % Plot transect median points
        % ---------------------------
        if get(handles.cbTransMed,'Value')==1 && itrans<length(idxTrans)
            plotMed(normData(idxTrans(itrans)),handles.axProfile,'Transect',transData(idxTrans(itrans)).startEdge);
        elseif get(handles.cbTransMed,'Value')==1 && itrans==length(idxTrans)
            for j=1:itrans-1
                hold on
                plotMed(normData(idxTrans(j)),handles.axProfile,'Transect',transData(idxTrans(j)).startEdge);
            end
        end

        % Plot measurement median points
        % ------------------------------
        if get(handles.cbMeasMed,'Value')==1
            plotMed(normData(end),handles.axProfile,'Measurement');
        end

        % Plot transect profile fits
        % --------------------------
        if get(handles.cbTransFit,'Value')==1
            if itrans<nfiles+1
                plotfit(selFit(idxTrans(itrans)),handles.axProfile,'Transect',transData(idxTrans(itrans)).startEdge);
            else
                for j=1:nfiles
                    hold on
                    plotfit(selFit(idxTrans(j)),handles.axProfile,'Transect',transData(idxTrans(j)).startEdge);
                end
            end

        end

        % Plot composite profile fit
        % --------------------------
        if get(handles.cbMeasFit,'Value')==1
            plotfit(selFit(end),handles.axProfile,'Measurement');
        end

        % Plot scale and labels
        % ---------------------
        plotScale(normData(idxTrans(itrans)),handles.axProfile);
        plotLabel(normData(idxTrans(itrans)),handles.axProfile);
    end % if
        % Update number of points in each 5% increment
        % --------------------------------------------
        displayNos(normData(idxTrans(itrans))',handles.zpts_table);
        drawnow;

function plotRaw (normData,h) 
% plots the unitNormalized data for each depth cell

    % Plot data
    hold (h,'on')
        plot(h,normData.unitNormalized,1-normData.cellDepthNormalized,'.','MarkerFaceColor',...
        [0.8275 0.8275 0.8275],'MarkerEdgeColor',[0.8275 0.8275 0.8275]);   
    hold (h,'off')

function plotSurface (normData,h)
% plots the unitNormalized data for each depth cell

    % Plot data 
    hold (h,'on')
        [~,idx]=max(~isnan(normData.unitNormalized));
        c=1:size(normData.unitNormalized,2)
        x=normData.unitNormalized(sub2ind(size(normData.unitNormalized),idx,c));
        y=normData.cellDepthNormalized(sub2ind(size(normData.unitNormalized),idx,c));
        plot(h,x,1-y,'og');   
    hold (h,'off')

function plotMed (normData,h,type,varargin)
% plots the median values as squares and horizontal lines between
% the 25 and 75 percentiles for each transect in normData.

        % Assign variables from normData
        unitNormMed=normData.unitNormalizedMed;
        avgz=normData.unitNormalizedz;
        unitNormNo=normData.unitNormalizedNo;
        unit25=normData.unitNormalized25;
        unit75=normData.unitNormalized75;
        datatype=normData.dataType;
        validData=normData.validData;

        % If data are from a composite profile use different
        % plotting parameters.
        if strcmp(type,'Measurement') 

            % Plot all median values in red
            hold (h,'on')
            plot(h,unitNormMed,avgz,'sr','MarkerFaceColor','r')

            % Plot innerquartile range bars around medians in red
            for j=1:20
                hold (h,'on')
                plot(h,[unit25(j) unit75(j)],[avgz(j) avgz(j)],'-r')
            end

            % Plot combined median values that meet in black
            hold (h,'on')
            plot(h,unitNormMed(validData),avgz(validData),'sk','MarkerFaceColor','k')

            % Plot innerquartile range bars around median values that meet criteria
            % in blue
            for k=1:length(validData)
                hold (h,'on')
                plot(h,[unit25(validData(k)) unit75(validData(k))],[avgz(validData(k)) avgz(validData(k))],'-k','LineWidth',2)
            end

        % If data are from individual transects use blue line color
        else

            % Plot all median values in red
            hold (h,'on')
            plot(h,unitNormMed,avgz,'sr')

            % Plot innerquartile range bars around medians in red
            idxnan=find(~isnan(unit25));
            for j=1:length(idxnan)
                hold (h,'on')
                plot(h,[unit25(idxnan(j)) unit75(idxnan(j))],[avgz(idxnan(j)) avgz(idxnan(j))],'-r')
            end
            if ~isempty(varargin)
                if strcmp(varargin,'Left')
                   colorl='-m';
                   colorsq='sm';
                else
                    colorl='-b';
                    colorsq='sb';
                end
            else
                colorl='-b';
                colorsq='sb';
            end
            % Plot median values that meet thresholds in blue
            hold (h,'on')
            plot(h,unitNormMed(validData),avgz(validData),colorsq)

            % Plot innerquartile range bars around median values that meet criteria
            % in blue
            for j=1:length(validData)
                hold (h,'on')
                plot(h,[unit25(validData(j)) unit75(validData(j))],[avgz(validData(j)) avgz(validData(j))],colorl)
            end
        end
    hold (h,'off')

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
    ylim(h,[0 1]);
    xlim(h,[lower upper]);
    box (h,'on')
    grid(h,'On')

function plotLabel (normData,h)
% Label axes based on type of data plotted.

    % Set datatype to either dischage (q) or velocity (v)
    datatype= normData(1).dataType;

    % Label axes
    if strcmpi(datatype,'q')
        xlabel(h,'Normalized Unit Q','FontSize',10)
    else
        xlabel(h,'Normalized Velocity','FontSize',10)
    end
    ylabel(h,'Normalized Distance from Streambed','FontSize',10);

function plotfit(fitData,h,type,varargin)
% If input to the plot method is from a single transect 
% (dataType=q or v) the line is blue. If the input to the plot method
% is a composite of multiple transects (dataType=Q or V) then the line
% is a heavy black line.

    % Plot specified extraplation          
    for i=1:length(fitData)
        if strcmp(type,'Measurement')
            hold (h,'on')
            plot(h,fitData(i).u,fitData(i).z,'-k','LineWidth',2); 
        else
            hold (h,'on')
            if ~isempty(varargin)
                if strcmp(varargin{i},'Left')
                    plot(h,fitData(i).u,fitData(i).z,'-m');
                else
                    plot(h,fitData(i).u,fitData(i).z,'-b');
                end
            else
                plot(h,fitData(i).u,fitData(i).z,'-b');
            end
        end
    end
    hold (h,'off')    

% GUI update functions
% ====================

function updateFit (handles,meas)
        % Update GUI
        j=get(handles.listFiles,'Value');
        % Index of checked transects
        idxTrans=find([meas.transects.checked]==1);
        % Adjust index to include composite of measurement
        idxTrans(end+1)=length([meas.transects.checked])+1;  
        switch meas.extrapFit.selFit(idxTrans(j)).topMethod
            case 'Power'
                set(handles.puTop,'Value',1);
            case 'Constant'
                set(handles.puTop,'Value',2);
            case '3-Point'
                set(handles.puTop,'Value',3);
        end
        
        if strcmp(meas.extrapFit.selFit(idxTrans(j)).botMethod,'Power')
            set(handles.puBottom,'Value',1);
        else
            set(handles.puBottom,'Value',2);
        end
        set(handles.edExp,'String',num2str(meas.extrapFit.selFit(idxTrans(j)).exponent,'%6.4f'));
        set(handles.slExp,'Value',meas.extrapFit.selFit(idxTrans(j)).exponent);
        
function displayNos (normData,h)
% Display number of cells in each median value in text boxes
% defined by h vector.

    tableData=[normData.unitNormalizedz',normData.unitNormalizedNo'];
    set(h,'Data',tableData);

function displayTable(extrapFit,h)
% Displays discharge sensitivity in predefined table with 
% h as handle.

    %set QSensitivity object
    QSens = extrapFit.qSensitivity;
    
    %get selected methods
    top = extrapFit.selFit(end).topMethod;
    bottom = extrapFit.selFit(end).botMethod;
    exp = sprintf('%.4f',extrapFit.selFit(end).exponent);
    
    qTable(1,1)={'Power'};
    qTable(1,2)={'Power'};
    qTable(1,3)={'0.1667'};
    qTable(1,4)={num2str(QSens.qPPoptperdiff,'%6.2f')};
    qTable(2,1)={'Power'};
    qTable(2,2)={'Power'};
    qTable(2,3)={num2str(QSens.ppExponent,'%6.4f')};
    qTable(2,4)={num2str(QSens.qPPoptperdiff,'%6.2f')};
    qTable(3,1)={'Constant'};
    qTable(3,2)={'No Slip'};
    qTable(3,3)={'0.1667'};
    qTable(3,4)={num2str(QSens.qCNSperdiff,'%6.2f')};                
    qTable(4,1)={'Constant'};
    qTable(4,2)={'No Slip'};
    qTable(4,3)={num2str(QSens.nsExponent,'%6.4f')};
    qTable(4,4)={num2str(QSens.qCNSoptperdiff,'%6.2f')};                
    qTable(5,1)={'3-Point'};
    qTable(5,2)={'No Slip'};
    qTable(5,3)={'0.1667'};
    qTable(5,4)={num2str(QSens.q3pNSperdiff,'%6.2f')}; 
    qTable(6,1)={'3-Point'};
    qTable(6,2)={'No Slip'};
    qTable(6,3)={num2str(QSens.nsExponent,'%6.4f')};
    qTable(6,4)={num2str(QSens.q3pNSoptperdiff,'%6.2f')};
    
    qMan = 0;
    if ~isnan(QSens.qManmean)
        qTable{7,1}=QSens.manTop;
        qTable{7,2}=QSens.manBot;
        qTable(7,3)={num2str(QSens.manExp,'%6.4f')};
        qTable(7,4)={num2str(QSens.qManperdiff,'%6.2f')};  
        qMan = 1;
    end
    
    %for all table entries, check if selected method and label reference
    % if it is
    for x = 1:6+qMan
        if strcmpi(qTable{x,1},top) & strcmpi(qTable{x,2},bottom) & abs(qTable{x,3}-exp)<0.0001
            qTable(x,1) = {['<html><b>',qTable{x,1},'</b></html>']};
            qTable(x,2) = {['<html><b>',qTable{x,2},'</b></html>']};
            qTable(x,3) = {['<html><b>',qTable{x,3},'</b></html>']};
            qTable(x,4) = {'<html><b>Reference</b></html>'};
            
        end
    end
    
    set(h,'Data',nan);
    set(h,'Data',qTable);

function q_table_CellSelectionCallback(hObject, eventdata, handles)
    if ~isempty(eventdata.Indices)
        row=eventdata.Indices(1);
        tableData=get(handles.q_table,'data');
        top=tableData{row,1};
        if strcmp(top(1),'<')
            idx=find(top=='>');
            top=top(idx(2)+1:end);
            idx=find(top=='<');
            top=top(1:idx(1)-1);
        end
        bottom=tableData{row,2};
        if strcmp(bottom(1),'<')
            idx=find(bottom=='>');
            bottom=bottom(idx(2)+1:end);
            idx=find(bottom=='<');
            bottom=bottom(1:idx(1)-1);
        end
        exponent=tableData{row,3};
        if strcmp(exponent(1),'<')
            idx=find(exponent=='>');
            exponent=exponent(idx(2)+1:end);
            idx=find(exponent=='<');
            exponent=exponent(1:idx(1)-1);
        end


        % Get data 
        meas=handles.meas;
        % Index of checked transects
        idxTrans=find([meas.transects.checked]==1);
        % Adjust index to include composite of measurement
        idxTrans(end+1)=length([meas.transects.checked])+1;
        set(handles.winExtrap,'Pointer','watch');
        drawnow;
        ifile=get(handles.listFiles,'Value');

      
        % Fit set to Manual
        % -----------------   
        set(handles.puFit,'Value',2);
        set(handles.puTop,'Enable','on');
        set(handles.puBottom,'Enable','on');
        set(handles.edExp,'Enable','on');
        set(handles.slExp,'Enable','on');
        
        switch top
            case 'Power'
                set(handles.puTop,'Value',1);
            case 'Constant'
                set(handles.puTop,'Value',2);
            case '3-Point'
                set(handles.puTop,'Value',3);   
        end
        
        switch bottom
            case 'Power'
                set(handles.puBottom,'Value',1);
            case 'No Slip'
                set(handles.puBottom,'Value',2);
        end
        
        set(handles.edExp,'String',num2str(exponent,4));
        
        meas.extrapFit=changeFitMethod(meas.extrapFit,meas.transects,'Manual',idxTrans(ifile),'All',top,bottom,str2double(exponent));
        
    
        
        

        % Store data    
        handles.meas = meas;   
        
        updateFit(handles,meas);
        %displayTable(meas.extrapFit,handles.q_table);
        % Update graphs
        % -------------
        plotTrans(handles,meas)
        % Update handles structure
        guidata(hObject, handles);  
        set(handles.winExtrap,'Pointer','arrow');
        drawnow;
    end
    
%==========================================================================
%================NO MODIFIED CODE BELOW HERE===============================
%==========================================================================
function listFiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function puFit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to puFit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function puTop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to puTop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function puBottom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to puBottom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edExp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edExp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function slExp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slExp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function puData_CreateFcn(hObject, eventdata, handles)
% hObject    handle to puData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on edExp and none of its controls.
function edExp_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edExp (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over listFiles.
function listFiles_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to listFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
