% =========================================================================
% Single-Subject Case Study: Longitudinal Trajectory & Normative Stats
% Meditator: 013AR  |  Control: 064PK
% =========================================================================

clear; clc;

%% 1. Setup Paths and Parameters
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');

% Subjects
medSubj = '013AR';
ctrlSubj = '064PK';

% Protocols in Chronological Order
protocols = {'EO1', 'EC1', 'G1', 'M1', 'G2', 'EO2', 'EC2', 'M2'};
numProtos = length(protocols);

% Load Cap Data
capData = load('actiCap64_UOL.mat'); chanlocs = capData.chanlocs;

% Regions of Interest (Using actiCap 64 indices)
leftFrontalIdx = [1, 3, 4, 6, 7, 33, 38, 37, 36, 43];
rightFrontalIdx = [32, 30, 31, 28, 25, 61, 62, 60, 63, 58];
occipitalIdx = [28, 29, 30, 61, 62, 63, 64]; % Customize to your occipital hub
targetElec = 50; % The highly significant electrode found earlier

%% 2. Extract Data for All 8 Protocols
medDataAll = nan(numProtos, 64);
ctrlDataAll = nan(numProtos, 64);

for p = 1:numProtos
    % Meditator
    mFile = fullfile(dataFolder, medSubj, [protocols{p} '_ep_v8_srtc.mat']);
    if exist(mFile, 'file')
        tmp = load(mFile);
        if isfield(tmp, 'tau_srtc'); medDataAll(p, :) = tmp.tau_srtc; end
    end
    
    % Control
    cFile = fullfile(dataFolder, ctrlSubj, [protocols{p} '_ep_v8_srtc.mat']);
    if exist(cFile, 'file')
        tmp = load(cFile);
        if isfield(tmp, 'tau_srtc'); ctrlDataAll(p, :) = tmp.tau_srtc; end
    end
end

%% 3. Calculate Regional Dynamics
% Meditator
medLF = nanmean(medDataAll(:, leftFrontalIdx), 2);
medRF = nanmean(medDataAll(:, rightFrontalIdx), 2);
medFAI = medLF - medRF; % Asymmetry Index
medTarget = medDataAll(:, targetElec);

% Control
ctrlLF = nanmean(ctrlDataAll(:, leftFrontalIdx), 2);
ctrlRF = nanmean(ctrlDataAll(:, rightFrontalIdx), 2);
ctrlFAI = ctrlLF - ctrlRF; % Asymmetry Index
ctrlTarget = ctrlDataAll(:, targetElec);

%% 4. Visualization Dashboard
figure('Name', sprintf('Case Study: %s (Med) vs %s (Ctrl)', medSubj, ctrlSubj), ...
       'Color', 'w', 'Position', [50 50 1400 800]);

% --- Plot A: Spatial Topography during M1 (Meditation) ---
m1_idx = 4; % 'M1' is the 4th protocol
cLims = [min([medDataAll(m1_idx,:), ctrlDataAll(m1_idx,:)]), max([medDataAll(m1_idx,:), ctrlDataAll(m1_idx,:)])];

subplot(2, 3, 1);
topoplot(medDataAll(m1_idx, :), chanlocs, 'maplimits', cLims, 'electrodes', 'on');
title(sprintf('%s (Meditator) - M1', medSubj), 'FontSize', 12, 'Color', [0.8 0.2 0.2]); colorbar;

subplot(2, 3, 2);
topoplot(ctrlDataAll(m1_idx, :), chanlocs, 'maplimits', cLims, 'electrodes', 'on');
title(sprintf('%s (Control) - M1', ctrlSubj), 'FontSize', 12, 'Color', [0.2 0.2 0.8]); colorbar;

% --- Plot B: The Z-Score / Difference Map (M1) ---
% Technically, the difference between these two specific brains
diffMap = medDataAll(m1_idx, :) - ctrlDataAll(m1_idx, :);
subplot(2, 3, 3);
topoplot(diffMap, chanlocs, 'maplimits', 'maxmin', 'electrodes', 'on');
title('\Delta \tau (Med - Ctrl)', 'FontSize', 12); colorbar;

% --- Plot C: Target Electrode Trajectory Across Protocols ---
subplot(2, 3, 4); hold on;
plot(1:numProtos, medTarget, '-o', 'LineWidth', 2, 'Color', [0.8 0.2 0.2], 'MarkerFaceColor', [0.8 0.2 0.2], 'DisplayName', 'Meditator (013AR)');
plot(1:numProtos, ctrlTarget, '-o', 'LineWidth', 2, 'Color', [0.2 0.2 0.8], 'MarkerFaceColor', [0.2 0.2 0.8], 'DisplayName', 'Control (064PK)');

% Highlight meditation protocols
xline(3, '--k', 'G1 (Chant)', 'LabelOrientation', 'horizontal', 'FontSize', 9);
xline(4, '--k', 'M1 (Silent)', 'LabelOrientation', 'horizontal', 'FontSize', 9);
xline(8, '--k', 'M2 (Silent)', 'LabelOrientation', 'horizontal', 'FontSize', 9);

xticks(1:numProtos); xticklabels(protocols);
ylabel(sprintf('\\tau (ms) at Electrode %d', targetElec), 'FontWeight', 'bold');
title('Longitudinal Brain State Trajectory');
legend('Location', 'northwest'); grid on;

% --- Plot D: Frontal Asymmetry Index (FAI) Trajectory ---
subplot(2, 3, 5); hold on;
yline(0, '--k', 'LineWidth', 1.5, 'HandleVisibility', 'off'); % Symmetry line
plot(1:numProtos, medFAI, '-s', 'LineWidth', 2, 'Color', [0.8 0.2 0.2], 'MarkerFaceColor', [0.8 0.2 0.2]);
plot(1:numProtos, ctrlFAI, '-s', 'LineWidth', 2, 'Color', [0.2 0.2 0.8], 'MarkerFaceColor', [0.2 0.2 0.8]);

xticks(1:numProtos); xticklabels(protocols);
ylabel('FAI (\tau_{Left} - \tau_{Right})', 'FontWeight', 'bold');
title('Hemispheric Emotional Balance (FAI)');
text(1, max([medFAI; ctrlFAI])*0.9, 'Positive = Left Dominant', 'Color', [0.1 0.6 0.1], 'FontSize', 9);
grid on;

% --- Plot E: Occipital Hub Trajectory ---
medOcc = nanmean(medDataAll(:, occipitalIdx), 2);
ctrlOcc = nanmean(ctrlDataAll(:, occipitalIdx), 2);

subplot(2, 3, 6); hold on;
plot(1:numProtos, medOcc, '-^', 'LineWidth', 2, 'Color', [0.8 0.2 0.2], 'MarkerFaceColor', [0.8 0.2 0.2]);
plot(1:numProtos, ctrlOcc, '-^', 'LineWidth', 2, 'Color', [0.2 0.2 0.8], 'MarkerFaceColor', [0.2 0.2 0.8]);

xticks(1:numProtos); xticklabels(protocols);
ylabel('\tau (ms) at Occipital Hub', 'FontWeight', 'bold');
title('Visual/Posterior Processing Network');
grid on;