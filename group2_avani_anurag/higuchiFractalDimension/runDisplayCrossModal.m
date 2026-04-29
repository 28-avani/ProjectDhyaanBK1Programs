% A GUI to correlate State Shifts across HFD and FOOOF metrics
function runDisplayCrossModal
fontSizeSmall = 10; fontSizeMedium = 12; fontSizeLarge = 16;
backgroundColor = 'w'; panelHeight = 0.125;
colormap jet

%%%%%%%%%%%%%%%%%%%%%%%%%%% Subject Choices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel1 = uipanel('Title','Subjects','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.025 1-panelHeight 0.15 panelHeight]);
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 2/3 0.5 1/3],'Style','text','String','Comparison','FontSize',fontSizeSmall);
comparisonList = [{'paired'} {'unpaired'}];
hComparison = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 2/3 0.5 1/3],'Style','popup','String',comparisonList,'FontSize',fontSizeSmall);
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 1/3 0.5 1/3],'Style','text','String','Gender','FontSize',fontSizeSmall);
genderList = [{'all'} {'male'} {'female'}];
hGender = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 1/3 0.5 1/3],'Style','popup','String',genderList,'FontSize',fontSizeSmall);
uicontrol('Parent',hPanel1,'Unit','Normalized','Position',[0 0 0.5 1/3],'Style','text','String','Age','FontSize',fontSizeSmall);
ageList = [{'all'} {'young'} {'mid'}];
hAge = uicontrol('Parent',hPanel1,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 0 0.5 1/3],'Style','popup','String',ageList,'FontSize',fontSizeSmall);

%%%%%%%%%%%%%%%%%%%%%%%% Protocol Details %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel2 = uipanel('Title','Protocol','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.175 1-panelHeight 0.15 panelHeight]);
uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 2/3 0.5 1/3],'Style','text','String','ProtocolName','FontSize',fontSizeSmall);
protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M1'} {'G2'} {'EO2'} {'EC2'} {'M2'}];
hProtocol = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 2/3 0.5 1/3],'Style','popup','String',protocolNameList,'Value',3,'FontSize',fontSizeSmall);
uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 1/3 0.5 1/3],'Style','text','String','Analysis','FontSize',fontSizeSmall);
analysisChoiceList1 = [{'spontaneous (bl)'} {'stimulus (st)'} {'combined'}];
analysisChoiceList2 = [{'bl'} {'st'} {'combined'}];
hAnalysisChoice = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 1/3 0.5 1/3],'Style','popup','String',analysisChoiceList1,'Value',2,'FontSize',fontSizeSmall);
uicontrol('Parent',hPanel2,'Unit','Normalized','Position',[0 0 0.5 1/3],'Style','text','String','Ref Choice','FontSize',fontSizeSmall);
refChoiceList = [{'none'} protocolNameList];
hRefChoice = uicontrol('Parent',hPanel2,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 0 0.5 1/3],'Style','popup','String',refChoiceList,'Value',4,'FontSize',fontSizeSmall); % Default to Ref G1

%%%%%%%%%%%%%%%%%%%%%%%%%%% Bad Electrodes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel3 = uipanel('Title','Bad Electrode Condition','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.325 1-panelHeight 0.15 panelHeight]);
uicontrol('Parent',hPanel3,'Unit','Normalized','Position',[0 2/3 0.5 1/3],'Style','text','String','BadEyeCondition','FontSize',fontSizeSmall);
badEyeConditionList1 = [{'eye position (ep)'} {'none (wo)'}]; badEyeConditionList2 = [{'ep'} {'wo'}];
hBadEye = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 2/3 0.5 1/3],'Style','popup','String',badEyeConditionList1,'FontSize',fontSizeSmall);
uicontrol('Parent',hPanel3,'Unit','Normalized','Position',[0 1/3 0.5 1/3],'Style','text','String','BadTrialVersion','FontSize',fontSizeSmall);
badTrialVersionList = {'v8'};
hBadTrialVersion = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 1/3 0.5 1/3],'Style','popup','String',badTrialVersionList,'FontSize',fontSizeSmall);
uicontrol('Parent',hPanel3,'Unit','Normalized','Position',[0 0 0.5 1/3],'Style','text','String','BadElecChoice','FontSize',fontSizeSmall);
badElectrodeChoiceList = [{'Reject badElectrodes of protocolName'} {'Reject common badElectrodes of all protocols'} {'Reject badElectrodes of G1'}];
hBadElectrodeChoice = uicontrol('Parent',hPanel3,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position', [0.5 0 0.5 1/3],'Style','popup','String',badElectrodeChoiceList,'FontSize',fontSizeSmall);

%%%%%%%%%%%%%%%%%%%%%%%%% Freq Ranges %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel4 = uipanel('Title','Freq Range (Mapped)','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.475 1-panelHeight 0.15 panelHeight]);
% Mapped bands for Cross-Modal (1=Broadband, 2=Gamma)
freqRangeList0{1} = [1 150];  
freqRangeList0{2} = [30 80];  
numFreqRanges = length(freqRangeList0);
hFreqRangeMin = cell(1,numFreqRanges);
hFreqRangeMax = cell(1,numFreqRanges);
for i=1:numFreqRanges
    uicontrol('Parent',hPanel4,'Unit','Normalized','Position',[0 1-i/numFreqRanges 0.5 1/numFreqRanges],'Style','text','String',['Freq Range' num2str(i)],'FontSize',fontSizeSmall);
    hFreqRangeMin{i} = uicontrol('Parent',hPanel4,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.5 1-i/numFreqRanges 0.25 1/numFreqRanges], ...
        'Style','edit','String',num2str(freqRangeList0{i}(1)),'FontSize',fontSizeSmall);
    hFreqRangeMax{i} = uicontrol('Parent',hPanel4,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.75 1-i/numFreqRanges 0.25 1/numFreqRanges], ...
        'Style','edit','String',num2str(freqRangeList0{i}(2)),'FontSize',fontSizeSmall);
end

%%%%%%%%%%%%%%%%%%%%%%%%% Axis Ranges %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel5 = uipanel('Title','Axis Ranges','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.625 1-panelHeight 0.15 panelHeight]);
axisRangeList0{1} = [-1 1];      axisRangeName{1} = 'XLims (\Delta X)';
axisRangeList0{2} = [-0.5 0.5];  axisRangeName{2} = 'YLims (\Delta Y)'; 
numAxisRanges = length(axisRangeList0);
hAxisRangeMin = cell(1,numAxisRanges);
hAxisRangeMax = cell(1,numAxisRanges);
for i=1:numAxisRanges
    uicontrol('Parent',hPanel5,'Unit','Normalized','Position',[0 1-i/numAxisRanges 0.5 1/numAxisRanges],'Style','text','String',axisRangeName{i},'FontSize',fontSizeSmall);
    hAxisRangeMin{i} = uicontrol('Parent',hPanel5,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.5 1-i/numAxisRanges 0.25 1/numAxisRanges], ...
        'Style','edit','String',num2str(axisRangeList0{i}(1)),'FontSize',fontSizeSmall);
    hAxisRangeMax{i} = uicontrol('Parent',hPanel5,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.75 1-i/numAxisRanges 0.25 1/numAxisRanges], ...
        'Style','edit','String',num2str(axisRangeList0{i}(2)),'FontSize',fontSizeSmall);
end

%%%%%%%%%%%%%%%%%%%%%%%%% Cutoff Choices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hPanel6 = uipanel('Title','Cutoffs','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.775 1-panelHeight 0.08 panelHeight]);
cutoffList0 = [3 15]; cutoffNames = [{'Num Elecs'} {'Num Trials'}];
numCutoffRanges = length(cutoffList0);
hCutoffs = cell(1,numCutoffRanges);
for i=1:numCutoffRanges
    uicontrol('Parent',hPanel6,'Unit','Normalized','Position',[0 1-i/numCutoffRanges 0.5 1/numCutoffRanges],'Style','text','String',cutoffNames{i},'FontSize',fontSizeSmall);
    hCutoffs{i} = uicontrol('Parent',hPanel6,'Unit','Normalized','BackgroundColor', backgroundColor,'Position',[0.5 1-i/numCutoffRanges 0.5 1/numCutoffRanges], ...
        'Style','edit','String',num2str(cutoffList0(i)),'FontSize',fontSizeSmall);
end

%%%%%%%%%%%%%%%%%%%%%%%%% Plot Choices (CROSS-MODAL) %%%%%%%%%%%%%%%%%%%%%%
hPanel7 = uipanel('Title','Metrics','fontSize',fontSizeLarge,'Unit','Normalized','Position',[0.855 1-panelHeight 0.12 panelHeight]);
metricOptions = {'HFD', 'Hurst', '1/f Exponent', '1/f Offset'};

uicontrol('Parent',hPanel7,'Unit','Normalized','Position',[0 2/3 0.25 1/3],'Style','text','String','X:','FontSize',fontSizeMedium);
hMetricX = uicontrol('Parent',hPanel7,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position',[0.25 2/3 0.75 1/3],'Style','popup','String',metricOptions,'Value',3,'FontSize',fontSizeSmall);

uicontrol('Parent',hPanel7,'Unit','Normalized','Position',[0 1/3 0.25 1/3],'Style','text','String','Y:','FontSize',fontSizeMedium);
hMetricY = uicontrol('Parent',hPanel7,'Unit','Normalized','BackgroundColor', backgroundColor, 'Position',[0.25 1/3 0.75 1/3],'Style','popup','String',metricOptions,'Value',1,'FontSize',fontSizeSmall);

uicontrol('Parent',hPanel7,'Unit','Normalized','Position',[0 0 0.5 1/3],'Style','pushbutton','String','Rescale','FontSize',fontSizeMedium,'Callback',{@rescale_Callback});
uicontrol('Parent',hPanel7,'Unit','Normalized','Position',[0.5 0 0.5 1/3],'Style','pushbutton','String','Plot','FontSize',fontSizeMedium,'Callback',{@plot_Callback});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
electrodeGroupList = getElectrodeGroups('EEG','actiCap64_UOL');
numGroups = length(electrodeGroupList);
% Dedicated Large Scatter Handles for Correlation plotting
hAllPlots.hScatter = getPlotHandles(numFreqRanges,numGroups,[0.05 0.05 0.9 0.75],0.05,0.05,1);

    function plot_Callback(~,~)
        comparisonStr=comparisonList{get(hComparison,'val')};
        if strcmp(comparisonStr,'paired')
            pairedSubjectNameList = getPairedSubjectsBK1;            
            subjectNameLists{1} = pairedSubjectNameList(:,1);
            subjectNameLists{2} = pairedSubjectNameList(:,2);
            pairedDataFlag      = 1;
        else
            [~, meditatorList, controlList] = getGoodSubjectsBK1;
            subjectNameLists{1} = meditatorList;
            subjectNameLists{2} = controlList;
            pairedDataFlag      = 0;
        end
        
        [subjectNameList,~,~,ageListAllSub,genderListAllSub] = getDemographicDetails('BK1');
        
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
        
        protocolName = protocolNameList{get(hProtocol,'val')};
        analysisChoice = analysisChoiceList2{get(hAnalysisChoice,'val')};
        refChoice = refChoiceList{get(hRefChoice,'val')};
        badEyeCondition = badEyeConditionList2{get(hBadEye,'val')};
        badTrialVersion = badTrialVersionList{get(hBadTrialVersion,'val')};
        badElectrodeRejectionFlag = get(hBadElectrodeChoice,'val');
        
        % Pass both X and Y metric choices
        metricChoice = [get(hMetricX,'val'), get(hMetricY,'val')]; 
        
        stRange = [0.25 1.25]; 
        freqRangeList = cell(1,numFreqRanges);
        axisRangeList = cell(1,numAxisRanges);
        cutoffList = zeros(1,numCutoffRanges);
        for ii=1:numAxisRanges; axisRangeList{ii} = [str2double(get(hAxisRangeMin{ii},'String')) str2double(get(hAxisRangeMax{ii},'String'))]; end
        for ii=1:numCutoffRanges; cutoffList(ii) = str2double(get(hCutoffs{ii},'String')); end
        
        % The Heavy Lifting Backend
        displayCrossModal(subjectNameLists,protocolName,analysisChoice,refChoice,badEyeCondition,badTrialVersion,badElectrodeRejectionFlag,stRange,freqRangeList,axisRangeList,cutoffList,hAllPlots,pairedDataFlag, metricChoice);
    end

    function rescale_Callback(~,~)
        axisLims = [str2double(get(hAxisRangeMin{1},'String')) str2double(get(hAxisRangeMax{1},'String')) str2double(get(hAxisRangeMin{2},'String')) str2double(get(hAxisRangeMax{2},'String'))];
        [numRows,numCols] = size(hAllPlots.hScatter);
        for ii=1:numRows
            for j=1:numCols
                axis(hAllPlots.hScatter(ii,j),axisLims);
            end
        end
    end
end