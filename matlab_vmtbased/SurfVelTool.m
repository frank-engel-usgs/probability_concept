function varargout = SurfVelTool(varargin)
% SURFVELTOOL MATLAB code for SurfVelTool.fig
%      SURFVELTOOL, by itself, creates a new SURFVELTOOL or raises the existing
%      singleton*.
%
%      H = SURFVELTOOL returns the handle to a new SURFVELTOOL or the handle to
%      the existing singleton*.
%
%      SURFVELTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SURFVELTOOL.M with the given input arguments.
%
%      SURFVELTOOL('Property','Value',...) creates a new SURFVELTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SurfVelTool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SurfVelTool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SurfVelTool

% Last Modified by GUIDE v2.5 24-Aug-2018 20:40:24

% Begin initialization code - DO NOT EDIT
% Adress 2015b java bug #1293244
javax.swing.UIManager.setLookAndFeel('com.sun.java.swing.plaf.windows.WindowsLookAndFeel')
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SurfVelTool_OpeningFcn, ...
                   'gui_OutputFcn',  @SurfVelTool_OutputFcn, ...
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


% --- Executes just before SurfVelTool is made visible.
function SurfVelTool_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SurfVelTool (see VARARGIN)

% Choose default command line output for SurfVelTool
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SurfVelTool wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SurfVelTool_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in ProcessVMTOutputFile.
function ProcessVMTOutputFile_Callback(hObject, eventdata, handles)
% hObject    handle to ProcessVMTOutputFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close all
find_yaxisVMT();

% --- Executes on button press in ProcessQRevOutputFile.
function ProcessQRevOutputFile_Callback(hObject, eventdata, handles)
% hObject    handle to ProcessQRevOutputFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close all
find_yaxisQRev();


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
close all hidden
delete(hObject);
