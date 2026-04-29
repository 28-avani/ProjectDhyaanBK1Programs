% analysisChoice - 'st', 'bl' or 'combined'
% refChoice - 'none' (show raw values) or a protocolName.
% metricChoice - 1 for Exponent, 2 for Offset
function [metricDataToReturn,goodSubjectNameListsToReturn,topoplotDataToReturn] = displayFOOOFDataAllSubjects(subjectNameLists,protocolName,analysisChoice,refChoice,badEyeCondition,badTrialVersion,badElectrodeRejectionFlag,stRange,freqRangeList,axisRangeList,cutoffList,useMedianFlag,hAllPlots,pairedDataFlag,displayDataFlag,metricChoice)
if ~exist('protocolName','var');          protocolName='G1';            end
if ~exist('analysisChoice','var');        analysisChoice='st';          end
if ~exist('refChoice','var');             refChoice='none';             end
if ~exist('badEyeCondition','var');       badEyeCondition='ep';         end
if ~exist('badTrialVersion','var');       badTrialVersion='v8';         end
if ~exist('badElectrodeRejectionFlag','var'); badElectrodeRejectionFlag=1;  end
if ~exist('stRange','var');               stRange = [0.25 1.25];        end
if ~exist('freqRangeList','var')
    freqRangeList{1} = [1 150]; % Default Broadband for FOOOF
end
numFreqRanges = length(freqRangeList);
if ~exist('axisRangeList','var')
    axisRangeList{1} = [0 100];        % Bad Subjects %
    axisRangeList{2} = [0.5 2.5];      % Violin YLims (Exponent values are typically 0.5-2.5)
    axisRangeList{3} = [-0.15 0.15];   % Topo cLims
end
if ~exist('cutoffList','var')
    cutoffList = [3 15]; 
end
cutoffNumElectrodes = cutoffList(1);
cutoffNumTrials = cutoffList(2);
if ~exist('useMedianFlag','var');         useMedianFlag = 0;            end
if ~exist('hAllPlots','var');             hAllPlots = [];               end
if ~exist('pairedDataFlag','var');        pairedDataFlag = 0;           end
if ~exist('displayDataFlag','var');       displayDataFlag = 1;          end
if ~exist('metricChoice','var');          metricChoice = 1;             end
metricColors = [0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250];
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Display options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
displaySettings.fontSizeLarge = 10;
displaySettings.tickLengthMedium = [0.025 0];
displaySettings.colorNames(1,:) = [0.8 0 0.8];      % Purple 
displaySettings.colorNames(2,:) = [0.25 0.41 0.88]; % Cyan
titleStr{1} = 'Meditators';
titleStr{2} = 'Controls';
%%%%%%%%%%%%%%%%%%%%%%%% Get electrode groups %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gridType = 'EEG';
capType = 'actiCap64_UOL';
saveFolderName = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset/FOOOFData';
[electrodeGroupList,groupNameList] = getElectrodeGroups(gridType,capType);
numGroups = length(electrodeGroupList);
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generate plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if displayDataFlag
    if isempty(hAllPlots)
        hScatter = getPlotHandles(1,numGroups,[0.05 0.55 0.6 0.3],0.02,0.02,1);
        hPower   = getPlotHandles(numFreqRanges,numGroups,[0.05 0.05 0.6 0.45],0.02,0.02,0);
        hTopo0   = getPlotHandles(1,2,[0.675 0.7 0.3 0.15],0.02,0.02,1);
        hTopo1   = getPlotHandles(1,3,[0.675 0.55 0.3 0.13],0.02,0.02,1);
        hTopo2   = getPlotHandles(numFreqRanges,3,[0.675 0.05 0.3 0.45],0.02,0.02,1);
    else
        hScatter = hAllPlots.hScatter;
        hPower   = hAllPlots.hPower;
        hTopo0   = hAllPlots.hTopo0;
        hTopo1   = hAllPlots.hTopo1;
        hTopo2   = hAllPlots.hTopo2;
    end
    montageChanlocs = showElectrodeGroups(hTopo0(1,:),capType,electrodeGroupList,groupNameList);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%% Protocol Position %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M1'} {'G2'} {'EO2'} {'EC2'} {'M2'}];
protocolPos = find(strcmp(protocolNameList,protocolName));
if ~strcmp(refChoice,'none')
    protocolPosRef = find(strcmp(protocolNameList,refChoice));
else
    protocolPosRef = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
goodSubjectNameLists = getGoodSubjectNameList(subjectNameLists,badEyeCondition,badTrialVersion,stRange,protocolPos,protocolPosRef,analysisChoice,badElectrodeRejectionFlag,cutoffNumTrials,pairedDataFlag,saveFolderName);
[expData, expDataRef, offData, offDataRef] = getMetricDataAllSubjects(goodSubjectNameLists,badEyeCondition,badTrialVersion,stRange,protocolPos,protocolPosRef,analysisChoice,badElectrodeRejectionFlag,cutoffNumTrials,saveFolderName);
% Route data based on user toggle
if metricChoice == 1
    mainData = expData; mainDataRef = expDataRef; metricName = 'Exponent'; metricColor = metricColors(1,:);
else
    mainData = offData; mainDataRef = offDataRef; metricName = 'Offset'; metricColor = metricColors(2,:);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%% Show Topoplots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numElectrodes = size(mainData{1},1);
percentData = zeros(2,numElectrodes);
comparisonData = zeros(numFreqRanges,2,numElectrodes);
topoplotDataToReturn = cell(2,numFreqRanges);
for i=1:2
    if isempty(protocolPosRef)
        x = mainData{i};
    else
        x = mainData{i} - mainDataRef{i}; % Linear Subtraction
    end
    numSubjects = size(x,3);
    
    %%%%%%%%%%%% Show percent of bad subjects per electrode %%%%%%%%%%%%%%%
    numBadSubjects = zeros(1,numElectrodes);
    for j=1:numElectrodes
        numBadSubjects(j) = sum(isnan(squeeze(x(j,1,:))));
    end
    if displayDataFlag && numSubjects > 0
        axes(hTopo1(i)); %#ok<*LAXES>
        percentData(i,:) = 100*(numBadSubjects/numSubjects);
        topoplot(percentData(i,:),montageChanlocs,'maplimits',axisRangeList{1},'electrodes','on','plotrad',0.6,'headrad',0.6); colorbar;
        title(titleStr{i},'color',displaySettings.colorNames(i,:));
        if i==1; ylabel('Bad subjects (%)'); end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%% Show topoplots of metrics %%%%%%%%%%%%%%%%%%%%%
    for j=1:numFreqRanges
        metricVals = squeeze(x(:,j,:));
        
        if useMedianFlag; data = squeeze(median(metricVals,2,'omitnan'));
        else;             data = squeeze(mean(metricVals,2,'omitnan')); end
        
        comparisonData(j,i,:) = data;
        topoplotDataToReturn{i,j} = data;
        if displayDataFlag && numSubjects > 0
            axes(hTopo2(j,i));
            topoplot(data,montageChanlocs,'electrodes','on','maplimits',axisRangeList{3},'plotrad',0.6,'headrad',0.6); colorbar;
            if i==1; ylabel(['F' num2str(j)]); end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%% Plot the difference of topoplots %%%%%%%%%%%%%%%%%%%
if displayDataFlag && ~isempty(mainData{1}) && ~isempty(mainData{2})
    axes(hTopo1(3));
    topoplot(-diff(percentData),montageChanlocs,'maplimits',[-25 25],'electrodes','on','plotrad',0.6,'headrad',0.6); colorbar;
    title('Diff (M-C)');
    for i=1:numFreqRanges
        axes(hTopo2(i,3));
        data = -diff(squeeze(comparisonData(i,:,:)));
        topoplot(data,montageChanlocs,'electrodes','on','maplimits',axisRangeList{3},'plotrad',0.6,'headrad',0.6); colorbar;
    end
end
%%%%%%%%%%%%%%%%%%%%%% Scatter & Violin Plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
metricDataToReturn = cell(numGroups,numFreqRanges);
goodSubjectNameListsToReturn = cell(numGroups,2);
for i=1:numGroups
    %%%%%%%%%%%%% Find bad subjects based on electrode cutoff %%%%%%%%%%%%%
    badSubjectPosList = cell(1,2);
    for j=1:2
        pData = mainData{j}(electrodeGroupList{i},:,:);
        numGoodElecs = length(electrodeGroupList{i}) - sum(isnan(squeeze(pData(:,1,:))),1);
        badSubjectPosList{j} = find(numGoodElecs<cutoffNumElectrodes);
        if ~isempty(protocolPosRef)
            pDataRef = mainDataRef{j}(electrodeGroupList{i},:,:);
            numGoodElecsRef = length(electrodeGroupList{i}) - sum(isnan(squeeze(pDataRef(:,1,:))),1);
            badSubjectPosRef = find(numGoodElecsRef<=cutoffNumElectrodes);
            badSubjectPosList{j} = unique(cat(2,badSubjectPosList{j},badSubjectPosRef));
        end
    end
    if pairedDataFlag
        badSubjectPosList{1} = union(badSubjectPosList{1},badSubjectPosList{2});
        badSubjectPosList{2} = badSubjectPosList{1};
    end
    
    %%%%%%%%%%%%% Scatter Plot (Exponent vs Offset) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if displayDataFlag
        axes(hScatter(i)); hold on;
        for k=1:2
            tmpExp = squeeze(expData{k}(electrodeGroupList{i}, 1, :));
            tmpOff = squeeze(offData{k}(electrodeGroupList{i}, 1, :));
            
            if ~isempty(protocolPosRef)
                tmpExp = tmpExp - squeeze(expDataRef{k}(electrodeGroupList{i}, 1, :));
                tmpOff = tmpOff - squeeze(offDataRef{k}(electrodeGroupList{i}, 1, :));
            end
            
            subjExp = mean(tmpExp, 1, 'omitnan')';
            subjOff = mean(tmpOff, 1, 'omitnan')';
            
            subjExp(badSubjectPosList{k}) = [];
            subjOff(badSubjectPosList{k}) = [];
            
            scatter(subjExp, subjOff, 30, displaySettings.colorNames(k,:), 'filled', 'MarkerEdgeColor', 'k');
        end
        title(groupNameList{i});
        if i==1
            if isempty(protocolPosRef)
                xlabel('Exponent'); ylabel('Offset');
            else
                xlabel('\Delta Exponent'); ylabel('\Delta Offset');
            end
        end
        % Correlation line
        refline; 
        hold off;
    end
    
    %%%%%%%%%%%%% Violin plots for metrics %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for j=1:numFreqRanges
        tmpMetricVals = cell(1,2);
        for k=1:2
            pData = squeeze(mainData{k}(electrodeGroupList{i},j,:));
            if ~isempty(protocolPosRef)
                pDataRef = squeeze(mainDataRef{k}(electrodeGroupList{i},j,:));
            end
            
            badSubjectPos = badSubjectPosList{k};
            tmp = goodSubjectNameLists{k};
            tmp(badSubjectPos) = [];
            goodSubjectNameListsToReturn{i,k} = tmp;
            
            if ~isempty(badSubjectPos)       
                disp([groupNameList{i} ', ' titleStr{k} ', Not enough good electrodes for ' num2str(length(badSubjectPos)) ' subjects.']);
                pData(:,badSubjectPos)=[];
                if ~isempty(protocolPosRef); pDataRef(:,badSubjectPos)=[]; end
            end
            
            if isempty(protocolPosRef); tmpMetricVals{k} = mean(pData, 1, 'omitnan')';
            else; tmpMetricVals{k} = (mean(pData, 1, 'omitnan') - mean(pDataRef, 1, 'omitnan'))'; end
        end
        
        metricDataToReturn{i,j} = tmpMetricVals;
        
        if displayDataFlag
            displaySettings.plotAxes = hPower(j,i);
            if ~useMedianFlag
                displaySettings.parametricTest = 1; displaySettings.medianFlag = 0;
            else
                displaySettings.parametricTest = 0; displaySettings.medianFlag = 1;
            end
            if i==numGroups && j==1
                displaySettings.showYTicks=1; displaySettings.showXTicks=1;
            else
                displaySettings.showYTicks=0; displaySettings.showXTicks=0;
            end
            
            if ~isempty(tmpMetricVals{1}) && ~isempty(tmpMetricVals{2})
                displayViolinPlot(tmpMetricVals,[{displaySettings.colorNames(1,:)} {displaySettings.colorNames(2,:)}],1,1,1,pairedDataFlag,displaySettings);
            end
            
            if i==1
                if isempty(protocolPosRef)
                    ylabel(hPower(j,i), [metricName ' F' num2str(j)], 'color', metricColor);
                else
                    ylabel(hPower(j,i), ['\Delta ' metricName ' F' num2str(j)], 'color', metricColor);
                end
            end
        end
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function goodSubjectNameLists = getGoodSubjectNameList(subjectNameLists,badEyeCondition,badTrialVersion,stRange,protocolPos,protocolPosRef,analysisChoice,badElectrodeRejectionFlag,cutoffNumTrials,pairedDataFlag,saveFolderName)
badSubjectIndex = cell(1,2); badSubjectIndexRef = cell(1,2);
for i=1:2
    numSubjects = length(subjectNameLists{i});
    badSubjectIndexTMP = zeros(1,numSubjects); badSubjectIndexRefTMP = zeros(1,numSubjects);
    for j=1:numSubjects
        subjectName = subjectNameLists{i}{j};
        % CHANGED TO FOOOF .mat
        fileName = fullfile(saveFolderName,[subjectName '_' badEyeCondition '_' badTrialVersion '_' num2str(1000*stRange(1)) '_' num2str(1000*stRange(2)) '_FOOOF.mat']);
        if ~exist(fileName, 'file'); badSubjectIndexTMP(j)=1; badSubjectIndexRefTMP(j)=1; continue; end
        
        tmpData = load(fileName);
        [expTMP, ~] = getMetricData(tmpData,protocolPos,analysisChoice,badElectrodeRejectionFlag,cutoffNumTrials);
        if isempty(expTMP)
            disp(['Not enough trials for subject: ' subjectName]);
            badSubjectIndexTMP(j)=1;
        end
        if ~isempty(protocolPosRef)
            [expRefTMP, ~] = getMetricData(tmpData,protocolPosRef,'bl',badElectrodeRejectionFlag,cutoffNumTrials);
            if isempty(expRefTMP)
                disp(['Not enough trials in ref period for subject: ' subjectName]);
                badSubjectIndexRefTMP(j)=1;
            end
        end
    end
    badSubjectIndex{i} = badSubjectIndexTMP; badSubjectIndexRef{i} = badSubjectIndexRefTMP;
end
goodSubjectNameLists = cell(1,2);
if ~pairedDataFlag
    for i=1:2
        subjectNameListTMP = subjectNameLists{i};
        if isempty(protocolPosRef); badPos = find(badSubjectIndex{i}); else; badPos = union(find(badSubjectIndex{i}),find(badSubjectIndexRef{i})); end
        subjectNameListTMP(badPos)=[]; goodSubjectNameLists{i} = subjectNameListTMP;
    end
else
    if isempty(protocolPosRef); badPos = find(sum(cell2mat(badSubjectIndex'))); else; badPos = union(find(sum(cell2mat(badSubjectIndex'))),find(sum(cell2mat(badSubjectIndexRef')))); end
    for i=1:2
        subjectNameListTMP = subjectNameLists{i}; subjectNameListTMP(badPos)=[]; goodSubjectNameLists{i} = subjectNameListTMP;
    end
end
end

function [expData, expDataRef, offData, offDataRef] = getMetricDataAllSubjects(subjectNameLists,badEyeCondition,badTrialVersion,stRange,protocolPos,protocolPosRef,analysisChoice,badElectrodeRejectionFlag,cutoffNumTrials,saveFolderName)
expData = cell(1,2); expDataRef = cell(1,2);
offData = cell(1,2); offDataRef = cell(1,2);
for i=1:2
    expTMP=[]; expRefTMP=[];
    offTMP=[]; offRefTMP=[];
    for j=1:length(subjectNameLists{i})
        subjectName = subjectNameLists{i}{j};
        % CHANGED TO FOOOF .mat
        tmpData = load(fullfile(saveFolderName,[subjectName '_' badEyeCondition '_' badTrialVersion '_' num2str(1000*stRange(1)) '_' num2str(1000*stRange(2)) '_FOOOF.mat']));
        
        [tmpExp, tmpOff] = getMetricData(tmpData,protocolPos,analysisChoice,badElectrodeRejectionFlag,cutoffNumTrials);
        expTMP = cat(3,expTMP,tmpExp);
        offTMP = cat(3,offTMP,tmpOff);
        
        if ~isempty(protocolPosRef)
            [tmpExpRef, tmpOffRef] = getMetricData(tmpData,protocolPosRef,'bl',badElectrodeRejectionFlag,cutoffNumTrials);
            expRefTMP = cat(3,expRefTMP,tmpExpRef);
            offRefTMP = cat(3,offRefTMP,tmpOffRef);
        end
    end
    expData{i} = expTMP; expDataRef{i} = expRefTMP;
    offData{i} = offTMP; offDataRef{i} = offRefTMP;
end
end

function [tmpExp, tmpOff] = getMetricData(tmpData,protocolPos,analysisChoice,badElectrodeRejectionFlag,cutoffNumTrials)
numTrials = tmpData.numTrials(protocolPos);
badElectrodes = getBadElectrodes(tmpData.badElectrodes,badElectrodeRejectionFlag,protocolPos);
if numTrials < cutoffNumTrials
    tmpExp = []; tmpOff = [];
else
    if strcmpi(analysisChoice,'st')
        tmpExp = tmpData.exponentST{protocolPos}; tmpOff = tmpData.offsetST{protocolPos};
    elseif strcmpi(analysisChoice,'bl')
        tmpExp = tmpData.exponentBL{protocolPos}; tmpOff = tmpData.offsetBL{protocolPos};
    else
        tmpExp = (tmpData.exponentST{protocolPos} + tmpData.exponentBL{protocolPos})/2;
        tmpOff = (tmpData.offsetST{protocolPos} + tmpData.offsetBL{protocolPos})/2;
    end
    tmpExp(badElectrodes,:) = NaN;
    tmpOff(badElectrodes,:) = NaN;
end
end

function badElectrodes = getBadElectrodes(badElectrodeList,badElectrodeRejectionFlag,protocolPos)
if badElectrodeRejectionFlag==1; badElectrodes = badElectrodeList{protocolPos};
elseif badElectrodeRejectionFlag==2
    badElectrodes=[]; for i=1:length(badElectrodeList); badElectrodes=cat(1,badElectrodes,badElectrodeList{i}); end; badElectrodes = unique(badElectrodes);
elseif badElectrodeRejectionFlag==3; badElectrodes = badElectrodeList{3};
end
end