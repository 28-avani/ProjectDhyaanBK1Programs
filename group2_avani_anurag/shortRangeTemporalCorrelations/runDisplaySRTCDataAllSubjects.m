% A GUI to choose different options for displaying group-level SRTC data
% Streamlined from the Power script specifically for Tau Topoplots

function runDisplaySRTCDataAllSubjects

fontSizeSmall = 10; fontSizeMedium = 12; fontSizeLarge = 16;
backgroundColor = 'w'; panelHeight = 0.125;
colormap jet

%%%%%%%%%%%%%%%%%%%%%%%%%%% Subject Choices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel1 = uipanel('Title','Subjects','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.025 1-panelHeight 0.20 panelHeight]);

% Comparison - paired or unpaired
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 2/3 0.5 1/3],'Style','text','String','Comparison','FontSize',fontSizeSmall);
comparisonList = [{'paired'} {'unpaired'}];
hComparison = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 2/3 0.5 1/3],'Style','popup','String',comparisonList,'FontSize',fontSizeSmall);

% Gender - all, male, female
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 1/3 0.5 1/3],'Style','text','String','Gender','FontSize',fontSizeSmall);
genderList = [{'all'} {'male'} {'female'}];
hGender = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 1/3 0.5 1/3],'Style','popup','String',genderList,'FontSize',fontSizeSmall);

% Age - all, young, mid
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 0 0.5 1/3],'Style','text','String','Age','FontSize',fontSizeSmall);
ageList = [{'all'} {'young'} {'mid'}];
hAge = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 0 0.5 1/3],'Style','popup','String',ageList,'FontSize',fontSizeSmall);

%%%%%%%%%%%%%%%%%%%%%%%% Protocol & Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel2 = uipanel('Title','Protocol & Data','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.25 1-panelHeight 0.20 panelHeight]);

% Protocol
uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 2/3 0.5 1/3],'Style','text','String','ProtocolName','FontSize',fontSizeSmall);
protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M1'} {'G2'} {'EO2'} {'EC2'} {'M2'}];
hProtocol = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 2/3 0.5 1/3],'Style','popup','String',protocolNameList,'FontSize',fontSizeSmall);

% Bad Eye condition
uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 1/3 0.5 1/3],'Style','text','String','BadEyeCondition','FontSize',fontSizeSmall);
badEyeConditionList1 = [{'eye position (ep)'} {'none (wo)'}]; badEyeConditionList2 = [{'ep'} {'wo'}];
hBadEye = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 1/3 0.5 1/3],'Style','popup','String',badEyeConditionList1,'FontSize',fontSizeSmall);

% Bad Trial Version
uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 0 0.5 1/3],'Style','text','String','BadTrialVersion','FontSize',fontSizeSmall);
badTrialVersionList = {'v8'};
hBadTrialVersion = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 0 0.5 1/3],'Style','popup','String',badTrialVersionList,'FontSize',fontSizeSmall);

%%%%%%%%%%%%%%%%%%%%%%%%% Axis Ranges %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel3 = uipanel('Title','Axis Ranges','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.475 1-panelHeight 0.15 panelHeight]);

% Tau is typically bounded between ~20ms and ~150ms in the Gamma band
uicontrol('Parent',hPanel3,'Unit','Normalized','Position',[0 0.5 0.5 0.5],'Style','text','String','Tau Limits (ms)','FontSize',fontSizeSmall);
hAxisRangeMin = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.5 0.5 0.25 0.5], 'Style','edit','String','20','FontSize',fontSizeSmall);
hAxisRangeMax = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.75 0.5 0.25 0.5], 'Style','edit','String','120','FontSize',fontSizeSmall);

%%%%%%%%%%%%%%%%%%%%%%%%% Plot Choices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel4 = uipanel('Title','Plot','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.65 1-panelHeight 0.15 panelHeight]);

uicontrol('Parent',hPanel4,'Unit','Normalized','Position',[0 0.5 0.5 0.5],'Style','pushbutton','String','Rescale','FontSize',fontSizeMedium,'Callback',{@rescale_Callback});
uicontrol('Parent',hPanel4,'Unit','Normalized','Position',[0.5 0.5 0.5 0.5],'Style','pushbutton','String','Clear','FontSize',fontSizeMedium,'Callback',{@cla_Callback});
uicontrol('Parent',hPanel4,'Unit','Normalized','Position',[0 0 1 0.5],'Style','pushbutton','String','Plot','FontSize',fontSizeMedium,'Callback',{@plot_Callback});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot_Callback(~,~)
        %%%%%%%%%%%%%%%%%%%%% Get SubjectLists %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        comparisonStr=comparisonList{get(hComparison,'val')};
        if strcmp(comparisonStr,'paired')
            pairedSubjectNameList = getPairedSubjectsBK1;            
            subjectNameLists{1} = pairedSubjectNameList(:,1);
            subjectNameLists{2} = pairedSubjectNameList(:,2);
        else
            [~, meditatorList, controlList] = getGoodSubjectsBK1;
            subjectNameLists{1} = meditatorList;
            subjectNameLists{2} = controlList;
        end
        
        % Sub-select Subjects based on Demographics
        [subjectNameList,~,~,ageListAllSub,genderListAllSub] = getDemographicDetails('BK1');
        
        % sub-select based on Gender
        genderStr=genderList{get(hGender,'Value')};
        maleSubjectNameList = subjectNameList(strcmpi(genderListAllSub, 'M'));
        femaleSubjectNameList = subjectNameList(strcmpi(genderListAllSub, 'F'));
        if  strcmp(genderStr,'male')
            subjectNameLists{1} = intersect(subjectNameLists{1},maleSubjectNameList,'stable');
            subjectNameLists{2} = intersect(subjectNameLists{2},maleSubjectNameList,'stable');
        elseif strcmp(genderStr,'female')
            subjectNameLists{1} = intersect(subjectNameLists{1},femaleSubjectNameList,'stable');
            subjectNameLists{2} = intersect(subjectNameLists{2},femaleSubjectNameList,'stable');
        end
        
        % sub-select based on Age
        ageStr=ageList{get(hAge,'Value')};
        youngSubjectNameList = subjectNameList(ageListAllSub<40);
        midSubjectNameList = subjectNameList(ageListAllSub>=40);
        if  strcmp(ageStr,'young')
            subjectNameLists{1} = intersect(subjectNameLists{1},youngSubjectNameList,'stable');
            subjectNameLists{2} = intersect(subjectNameLists{2},youngSubjectNameList,'stable');
        elseif strcmp(ageStr,'mid')
            subjectNameLists{1} = intersect(subjectNameLists{1},midSubjectNameList,'stable');
            subjectNameLists{2} = intersect(subjectNameLists{2},midSubjectNameList,'stable');
        end
        
        %%%%%%%%%%%%%%%%%%%% Call Display Function %%%%%%%%%%%%%%%%%%%%%%%%
        protocolName = protocolNameList{get(hProtocol,'val')};
        badEyeCondition = badEyeConditionList2{get(hBadEye,'val')};
        badTrialVersion = badTrialVersionList{get(hBadTrialVersion,'val')};
        
        % Note: Currently passes the first sub-list (e.g. Meditators) to the display script. 
        % If you want to compare both, your displaySRTCDataAllSubjects script can be expanded!
        displaySRTCDataAllSubjects(subjectNameLists{1}, protocolName, badEyeCondition, badTrialVersion);
        
        % Apply custom color scaling based on UI
        cLims = [str2double(get(hAxisRangeMin,'String')) str2double(get(hAxisRangeMax,'String'))];
        clim(cLims);
    end

    function cla_Callback(~,~)
        % Clears the current figure if it exists
        f = gcf;
        if ~isempty(f)
            clf(f);
        end
    end

    function rescale_Callback(~,~)
        % Grabs the limits from the text boxes and applies them instantly to the topoplot
        cLims = [str2double(get(hAxisRangeMin,'String')) str2double(get(hAxisRangeMax,'String'))];
        f = gcf;
        if ~isempty(f)
            axes_objs = findobj(f, 'type', 'axes');
            for i = 1:length(axes_objs)
                clim(axes_objs(i), cLims);
            end
        end
    end
end