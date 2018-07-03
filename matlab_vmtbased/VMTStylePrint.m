function VMTStylePrint()
% Modify the existing figures
% ---------------------------
% Find what plots exist already
hf = findobj('type','figure');
valid_names = {'Plan View Map'; 'Mean Cross Section Contour'};

% Defaults for Print Stlye Figure
BkgdColor   = 'white';
AxColor     = 'black';
FigColor    = 'white'; % [0.3 0.3 0.3]
FntSize     = 14;

% Loop through valid figures and adjust
% -------------------------------------
if ~isempty(hf) &&  any(ishandle(hf))
    
    for i = 1:length(valid_names)
        switch valid_names{i}
            case 'Plan View Map'
                % Focus the figure
                hff = findobj('name','Plan View Map');
                if ~isempty(hff) &&  ishandle(hff)
                    figure(hff)
                    
                    % Make the changes to figure
                    set(gcf,'Color',BkgdColor);
                    set(gca,'FontSize',FntSize)
                    set(get(gca,'Title'),'FontSize',FntSize)
                    set(gca,'Color',FigColor)
                    set(gca,'XColor',AxColor)
                    set(gca,'YColor',AxColor)
                    set(gca,'ZColor',AxColor)
                    set(findobj(gcf,'tag','Colorbar'),...
                        'FontSize',FntSize,...
                        'Color',AxColor,...
                        'XColor',AxColor,...
                        'YColor',AxColor);
                    set(get(gca,'Title'),'FontSize',FntSize,'Color',AxColor)
                    set(get(gca,'xLabel'),'FontSize',FntSize,'Color',AxColor)
                    set(get(gca,'yLabel'),'FontSize',FntSize,'Color',AxColor)
                    
                    % Add a text object at the bottom of the figure with
                    % the file(s) and path for the data
                    ismultiplot = false;
                    if ~ismultiplot
                        filestr = '';
                        wd = length(filestr);
                        hd = 1;
                    else
                        % Construct a filename
                        filestr   = '';
                        wd        = max(cellfun(@length,filestr));
                        hd        = numel(filestr);
                        
                    end
                    
                    fileinfotxt = uicontrol('style','text','units','characters');
                    disableMenuBar(hff)
                    set(fileinfotxt,...
                        'string',filestr)
                    set(fileinfotxt,...
                        'position',[0,0,wd,hd],...
                        'Fontsize',FntSize/2,...
                        'ForegroundColor',AxColor,...
                        'BackgroundColor',BkgdColor,...
                        'HorizontalAlignment','Left',...
                        'Tag','fileinfotxt',...
                        'Visible','off')  % hide this by default, editFigureDialog handles it now)
                    
                end
            case 'Mean Cross Section Contour'
                % Focus the figure
                hff = findobj('name','Mean Cross Section Contour');
                if ~isempty(hff) &&  ishandle(hff)
                    figure(hff)
                    
                    % Make the changes to figure
                    set(gcf,'Color',BkgdColor);
                    set(gca,'FontSize',FntSize)
                    set(get(gca,'Title'),'FontSize',FntSize)
                    set(gca,'Color',FigColor)
                    set(gca,'XColor',AxColor)
                    set(gca,'YColor',AxColor)
                    set(gca,'ZColor',AxColor)
                    set(findobj(gcf,'tag','Colorbar'),...
                        'FontSize',FntSize,...
                        'Color',AxColor,...
                        'XColor',AxColor,...
                        'YColor',AxColor);
                    set(get(gca,'Title'),'FontSize',FntSize,'Color',AxColor)
                    set(get(gca,'xLabel'),'FontSize',FntSize,'Color',AxColor)
                    set(get(gca,'yLabel'),'FontSize',FntSize,'Color',AxColor)
                    set(findobj(gca,'tag','PlotBedElevation')   ,'color'    ,AxColor)
                    set(findobj(gca,'tag','ReferenceVectorText'),'color'    ,AxColor)
                    
                    % Add a text object at the bottom of the figure with
                    % the file(s) and path for the data
                    ismultiplot = false;
                    if ~ismultiplot
                        filestr = '';
                        wd = length(filestr);
                        hd = 1;
                    else
                        % Construct a filename
                        filestr   = '';
                        wd        = max(cellfun(@length,filestr));
                        hd        = numel(filestr);
                        
                    end
                    
                    fileinfotxt = uicontrol('style','text','units','characters');
                    disableMenuBar(hff)
                    set(fileinfotxt,...
                        'string',filestr)
                    set(fileinfotxt,...
                        'position',[0,0,wd,hd],...
                        'Fontsize',FntSize/2,...
                        'ForegroundColor',AxColor,...
                        'BackgroundColor',BkgdColor,...
                        'HorizontalAlignment','Left',...
                        'Tag','fileinfotxt',...
                        'Visible','off')  % hide this by default, editFigureDialog handles it now
                end
            otherwise
        end
    end
    
    
end


%[EOF] menuStylePrint_Callback
