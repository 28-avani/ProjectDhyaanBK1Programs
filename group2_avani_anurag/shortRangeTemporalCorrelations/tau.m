% =========================================================================
% Combined Regional Analysis: Raw (M1) vs Baseline Corrected (M1-EO1)
% Meditator: 013AR  |  Matched Control: 064PK 
% Regions: Occipital, Central, Frontal (L+R Combined)
% =========================================================================
clear; clc;

%% 1. Setup Paths and Parameters
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');

medSubj = '013AR';
mCtrlSubj = '064PK';
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'controlList');

%% 2. Define Combined Electrode Regions
% Occipital (L+R Combined)
regIdx{1} = [14:16, 18:20, 32+[12:15, 17:20]]; 
regName{1} = 'Occipital'; 

% Central (L+R Combined)
regIdx{2} = [6:8, 11, 12, 22, 23, 25, 28, 29, 32+[7:9, 11, 22, 24:26]]; 
regName{2} = 'Central'; 

% Frontal (L+R Combined)
regIdx{3} = [1, 3, 4, 30:32, 32+[1, 2, 4, 5, 28:31]]; 
regName{3} = 'Frontal'; 

numRegs = length(regName);

%% 3. Load and Process Data
[medM1, medEO1] = loadTauBoth({medSubj}, dataFolder);
[mCtrlM1, mCtrlEO1] = loadTauBoth({mCtrlSubj}, dataFolder);
[grpM1, grpEO1] = loadTauBoth(controlList, dataFolder);

% Pre-allocate result arrays
med_Raw = nan(1, numRegs); ctrl_Raw = nan(1, numRegs);
med_Diff = nan(1, numRegs); ctrl_Diff = nan(1, numRegs);
pMed_R = nan(1, numRegs); pCtrl_R = nan(1, numRegs);
pMed_D = nan(1, numRegs); pCtrl_D = nan(1, numRegs);

for r = 1:numRegs
    idx = regIdx{r};
    
    % --- PART 1: RAW (M1) ---
    med_Raw(r) = nanmean(medM1(idx));
    ctrl_Raw(r) = nanmean(mCtrlM1(idx));
    grpRawDist = nanmean(grpM1(:, idx), 2);
    
    pMed_R(r) = calculateNormativeP(med_Raw(r), grpRawDist);
    pCtrl_R(r) = calculateNormativeP(ctrl_Raw(r), grpRawDist);
    
    % --- PART 2: BASELINE CORRECTED (M1 - EO1) ---
    med_Diff(r) = nanmean(medM1(idx)) - nanmean(medEO1(idx));
    ctrl_Diff(r) = nanmean(mCtrlM1(idx)) - nanmean(mCtrlEO1(idx));
    grpDiffDist = nanmean(grpM1(:, idx), 2) - nanmean(grpEO1(:, idx), 2);
    
    pMed_D(r) = calculateNormativeP(med_Diff(r), grpDiffDist);
    pCtrl_D(r) = calculateNormativeP(ctrl_Diff(r), grpDiffDist);
end

%% 4. Visualization
figure('Name', 'Combined Regional Analysis', 'Color', 'w', 'Position', [50 50 1000 850]);

% Subplot 1: Raw M1
subplot(2,1,1);
plotGroupedBars(gca, [med_Raw', ctrl_Raw'], pMed_R, pCtrl_R, regName, ...
    'PART 1: Raw Intrinsic Timescale during Meditation (M1)', 'Raw \tau (ms)');

% Subplot 2: Baseline Corrected
subplot(2,1,2);
plotGroupedBars(gca, [med_Diff', ctrl_Diff'], pMed_D, pCtrl_D, regName, ...
    'PART 2: Baseline-Corrected Task Response (M1 - EO1)', '\Delta \tau (ms)');

%sgtitle(['Combined Regional Analysis: ' medSubj ' vs ' mCtrlSubj], 'FontSize', 16, 'FontWeight', 'bold');

%% ========================================================================
%% HELPER FUNCTIONS
%% ========================================================================

function [dataM1, dataEO1] = loadTauBoth(subList, folder)
    n = length(subList); dataM1 = nan(n, 64); dataEO1 = nan(n, 64);
    for i = 1:n
        fM1 = fullfile(folder, subList{i}, 'M1_ep_v8_srtc.mat');
        fEO1 = fullfile(folder, subList{i}, 'EO1_ep_v8_srtc.mat');
        if exist(fM1, 'file'); tmp = load(fM1); if isfield(tmp,'tau_srtc'); dataM1(i,:) = tmp.tau_srtc(:)'; end; end
        if exist(fEO1, 'file'); tmp = load(fEO1); if isfield(tmp,'tau_srtc'); dataEO1(i,:) = tmp.tau_srtc(:)'; end; end
    end
end

function p = calculateNormativeP(val, dist)
    z = (val - nanmean(dist)) / nanstd(dist);
    p = 2 * (1 - normcdf(abs(z)));
end

function plotGroupedBars(ax, barData, pMed, pCtrl, names, tStr, yLab)
    axes(ax); hold on;
    b = bar(barData, 'EdgeColor', 'k', 'LineWidth', 1.2);
    b(1).FaceColor = [0.8 0.3 0.3]; b(2).FaceColor = [0.3 0.3 0.8];
    
    set(gca, 'XTick', 1:length(names), 'XTickLabel', names, 'FontSize', 11);
    ylabel(yLab, 'FontWeight', 'bold'); title(tStr, 'FontSize', 13); grid on;
    
    yMax = max(barData(:)); yMin = min(barData(:));
    yRange = max(1.0, yMax - yMin);
    ylim([min(0, yMin - 0.2*yRange), yMax + 0.5*yRange]);

    for r = 1:length(names)
        % Meditator Star
        mStar = getStarStr(pMed(r));
        colM = [0.6 0 0]; if strcmp(mStar, ''); colM = [0.5 0.5 0.5]; end
        text(r-0.15, barData(r,1) + 0.1*yRange, mStar, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', colM, 'FontSize', 13);
        
        % Control Star
        cStar = getStarStr(pCtrl(r));
        colC = [0 0 0.6]; if strcmp(cStar, ''); colC = [0.5 0.5 0.5]; end
        text(r+0.15, barData(r,2) + 0.1*yRange, cStar, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'Color', colC, 'FontSize', 13);
    end
end

function s = getStarStr(p)
    if p < 0.001; s = '***'; elseif p < 0.01; s = '**'; elseif p < 0.05; s = '*'; else; s = ''; end
end