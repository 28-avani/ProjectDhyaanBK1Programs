% =========================================================================
% Global Tau Trajectory: 013AR & Group Analysis (All 8 Protocols)
% Metric: SRTC (Tau) averaged across all 64 electrodes
% =========================================================================
clear; clc;

%% 1. Setup Paths and Parameters
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');

% Subjects and Protocols
targetSubj = '013AR';
protocols = {'EO1', 'EC1', 'G1', 'M1', 'G2', 'EO2', 'EC2', 'M2'};
numProtos = length(protocols);

% Load Subject Lists
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'meditatorList', 'controlList');
numMeds = length(meditatorList);
numCtrls = length(controlList);

%% 2. Data Extraction
% Initialize: Subjects x Protocols
medGrpData = nan(numMeds, numProtos);
ctrlGrpData = nan(numCtrls, numProtos);
targetData = nan(1, numProtos);

fprintf('Extracting Global Tau for all protocols...\n');

for p = 1:numProtos
    prot = protocols{p};
    
    % A. Extract 013AR Data
    fTarget = fullfile(dataFolder, targetSubj, [prot '_ep_v8_srtc.mat']);
    if exist(fTarget, 'file')
        tmp = load(fTarget);
        if isfield(tmp, 'tau_srtc'); targetData(p) = nanmean(tmp.tau_srtc); end
    end
    
    % B. Extract Meditator Group
    for m = 1:numMeds
        fMed = fullfile(dataFolder, meditatorList{m}, [prot '_ep_v8_srtc.mat']);
        if exist(fMed, 'file')
            tmp = load(fMed);
            if isfield(tmp, 'tau_srtc'); medGrpData(m, p) = nanmean(tmp.tau_srtc); end
        end
    end
    
    % C. Extract Control Group
    for c = 1:numCtrls
        fCtrl = fullfile(dataFolder, controlList{c}, [prot '_ep_v8_srtc.mat']);
        if exist(fCtrl, 'file')
            tmp = load(fCtrl);
            if isfield(tmp, 'tau_srtc'); ctrlGrpData(c, p) = nanmean(tmp.tau_srtc); end
        end
    end
end

%% 3. Statistics and Visualization
figure('Name', 'Longitudinal Tau Analysis', 'Color', 'w', 'Position', [50 50 1200 850]);

% --- PLOT 1: Case Study (013AR vs Control Population) ---
subplot(2,1,1); hold on;
% Calculate Control Distribution
ctrlMean = nanmean(ctrlGrpData, 1);
ctrlSEM = nanstd(ctrlGrpData, 0, 1) ./ sqrt(sum(~isnan(ctrlGrpData), 1));

% Plot Control Shade (Mean +/- SEM)
fill([1:numProtos, fliplr(1:numProtos)], [ctrlMean+ctrlSEM, fliplr(ctrlMean-ctrlSEM)], ...
     [0.8 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');
plot(1:numProtos, ctrlMean, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Control Group (Mean \pm SEM)');

% Plot 013AR
plot(1:numProtos, targetData, '-o', 'LineWidth', 2.5, 'Color', [0.8 0.2 0.2], ...
     'MarkerFaceColor', [0.8 0.2 0.2], 'DisplayName', 'Subject 013AR (Meditator)');

% Formatting
title('Case Study: 013AR vs Control Population Trajectory', 'FontSize', 14);
ylabel('Global \tau (ms)'); grid on;
xticks(1:numProtos); xticklabels(protocols);
legend('Location', 'northwest');

% --- PLOT 2: Group Level Analysis (Meditators vs Controls) ---
subplot(2,1,2); hold on;
mMean = nanmean(medGrpData, 1);
mSEM  = nanstd(medGrpData, 0, 1) ./ sqrt(sum(~isnan(medGrpData), 1));
cMean = nanmean(ctrlGrpData, 1);
cSEM  = nanstd(ctrlGrpData, 0, 1) ./ sqrt(sum(~isnan(ctrlGrpData), 1));

% Plot Error Bars
errorbar(1:numProtos, mMean, mSEM, 'r-o', 'LineWidth', 2, 'MarkerFaceColor', 'r', 'DisplayName', 'Meditator Group');
errorbar(1:numProtos, cMean, cSEM, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'DisplayName', 'Control Group');

% Calculate Significance Stars
for p = 1:numProtos
    [~, pVal] = ttest2(medGrpData(:,p), ctrlGrpData(:,p));
    if pVal < 0.05
        yPos = max(mMean(p)+mSEM(p), cMean(p)+cSEM(p)) + 1;
        text(p, yPos, '*', 'FontSize', 20, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end
end

title('Group Level: Meditators vs Controls (All Protocols)', 'FontSize', 14);
ylabel('Global \tau (ms)'); grid on;
xticks(1:numProtos); xticklabels(protocols);
legend('Location', 'northwest');

sgtitle('Longitudinal Global Intrinsic Timescale (\tau) Analysis', 'FontSize', 18, 'FontWeight', 'bold');