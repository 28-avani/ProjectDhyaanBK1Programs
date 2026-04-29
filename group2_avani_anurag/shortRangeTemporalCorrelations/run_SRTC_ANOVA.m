% =========================================================================
% SRTC Group Analysis: Meditator vs. Control (Filtered for Good Subjects)
% =========================================================================

%% 1. Setup and Initialization
clear; clc;

% Define Paths
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
infoFilePath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles', 'BK1AllSubjectList.mat');
dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');

% A. Load the Master Lists
load(infoFilePath); % Loads 'meditatorList' and 'controlList'

% B. Get the Good Subject List
% Assuming getGoodSubjectsBK1 is a function in your path
try
    goodSubjectList = getGoodSubjectsBK1(); 
catch
    warning('getGoodSubjectsBK1.m not found. Ensure it is in your MATLAB path.');
    goodSubjectList = allSubjectList; % Fallback
end

% C. Filter lists to keep ONLY good subjects
% 'stable' preserves the original order of the subjects
meditatorListFiltered = intersect(meditatorList, goodSubjectList, 'stable');
controlListFiltered   = intersect(controlList, goodSubjectList, 'stable');

fprintf('Original: %d Meditators, %d Controls\n', length(meditatorList), length(controlList));
fprintf('Filtered: %d Meditators, %d Controls\n', length(meditatorListFiltered), length(controlListFiltered));

protocolList = {'EO1', 'EC1', 'G1', 'M1', 'G2', 'EO2', 'EC2', 'M2'};
numProtocols = length(protocolList);
numElectrodes = 64; 

%% 2. Function to Extract Data (Now using the Filtered Lists)
extractData = @(subList) gatherGroupData(subList, protocolList, dataFolder, numElectrodes);

disp('Loading Filtered Meditator Data...');
[medData, medSubjects] = extractData(meditatorListFiltered);

disp('Loading Filtered Control Data...');
[ctrlData, ctrlSubjects] = extractData(controlListFiltered);

% ... [Rest of the ANOVA loop and Topoplot code remains the same] ...

%% 3. Statistical Testing (Mixed ANOVA per Electrode)
% We want to find the p-value for the Group effect, Protocol effect, and Interaction.

p_Group      = zeros(numElectrodes, 1);
p_Protocol   = zeros(numElectrodes, 1);
p_Inter      = zeros(numElectrodes, 1);
F_Group      = zeros(numElectrodes, 1); % Storing F-stats for plotting

disp('Running ANOVAs for each electrode...');

disp('Running ANOVAs for each electrode...');

for e = 1:numElectrodes
    % Prepare flat arrays for 'anovan'
    Y = []; g_group = []; g_prot = []; g_subj = [];
    
    % Append Meditator Data
    for s = 1:length(medSubjects)
        for p = 1:numProtocols
            Y = [Y; medData(s, p, e)];
            g_group = [g_group; 1];
            g_prot = [g_prot; p];
            g_subj = [g_subj; s]; 
        end
    end
    
    % Append Control Data
    offset = length(medSubjects);
    for s = 1:length(ctrlSubjects)
        for p = 1:numProtocols
            Y = [Y; ctrlData(s, p, e)];
            g_group = [g_group; 2];
            g_prot = [g_prot; p];
            g_subj = [g_subj; s + offset];
        end
    end
    
    % --- NEW SAFETY GATE ---
    % Check if we have enough non-NaN data to actually run a model
    % We need at least some data from both groups to calculate a Group effect.
    hasMedData = any(~isnan(Y(g_group == 1)));
    hasCtrlData = any(~isnan(Y(g_group == 2)));
    
    if ~hasMedData || ~hasCtrlData
        fprintf('Skipping electrode %d: Missing data for one or both groups.\n', e);
        p_Group(e) = NaN;
        p_Protocol(e) = NaN;
        p_Inter(e) = NaN;
        continue; 
    end
    % -----------------------

    % Run N-Way ANOVA
    try
        [p, tbl, ~] = anovan(Y, {g_group, g_prot, g_subj}, ...
            'model', 2, 'random', 3, 'nested', [0 0 0; 0 0 0; 1 0 0], ...
            'varnames', {'Group', 'Protocol', 'Subject'}, 'display', 'off');
        
        p_Group(e) = p(1);       
        p_Protocol(e) = p(2);
        p_Inter(e) = p(4); 
        F_Group(e) = cell2mat(tbl(2,6)); 
    catch ME
        fprintf('Error at electrode %d: %s\n', e, ME.message);
    end
end

disp('Analysis Complete!');

%% 4. Visualization
% Load your channel locations
load('actiCap64_UOL.mat'); 

figure('Name', 'SRTC Group Differences', 'Color', 'w', 'Position', [100 100 1200 400]);

% Plot 1: Main Effect of Group (F-Statistic)
subplot(1,3,1);
topoplot(F_Group, chanlocs, 'maplimits', 'maxmin', 'electrodes', 'on');
title('Main Effect of Group (F-Statistic)');
colorbar;

% Plot 2: Significant Electrodes (Group Effect, p < 0.05)
subplot(1,3,2);
sigGroupMask = double(p_Group < 0.05);
topoplot(sigGroupMask, chanlocs, 'maplimits', [0 1], 'electrodes', 'on');
title('Significant Group Differences (p < 0.05)');
colormap(gca, [0.8 0.8 0.8; 1 0.2 0.2]); % Gray = NS, Red = Sig

% Plot 3: Significant Electrodes (Interaction Effect, p < 0.05)
subplot(1,3,3);
sigInterMask = double(p_Inter < 0.05);
topoplot(sigInterMask, chanlocs, 'maplimits', [0 1], 'electrodes', 'on');
title('Significant Group x Protocol Interaction');
colormap(gca, [0.8 0.8 0.8; 0.2 0.2 1]); % Gray = NS, Blue = Sig


%% --- Helper Function Definition ---
function [groupData, validSubjects] = gatherGroupData(subjectList, protocols, dataFolder, nElec)
    nSubj = length(subjectList);
    nProt = length(protocols);
    
    % Initialize with NaNs (Empty data will just remain NaN)
    groupData = nan(nSubj, nProt, nElec);
    validSubjects = {};
    validIdx = 1;
    
    for s = 1:nSubj
        subjName = subjectList{s};
        subjFolder = fullfile(dataFolder, subjName);
        
        if ~exist(subjFolder, 'dir'); continue; end
        
        for p = 1:nProt
            fileName = fullfile(subjFolder, [protocols{p} '_ep_v8_srtc.mat']);
            if exist(fileName, 'file')
                tmp = load(fileName);
                
                % 1. Check if tau_srtc exists and is NOT empty (0-by-0)
                if isfield(tmp, 'tau_srtc') && ~isempty(tmp.tau_srtc)
                    
                    % 2. Reshape the 64x1 vector to 1x1x64 so it fits into the 3D matrix
                    groupData(validIdx, p, :) = reshape(tmp.tau_srtc, 1, 1, nElec);
                    
                end
            end
        end
        validSubjects{validIdx} = subjName;
        validIdx = validIdx + 1;
    end
end