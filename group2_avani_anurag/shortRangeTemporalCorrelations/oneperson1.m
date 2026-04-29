% =========================================================================
% Single-Subject Case Study: Normative Comparison & Regional Significance
% Meditator: 013AR  |  Control: 064PK
% =========================================================================
clear; clc;

%% 1. Setup Paths and Regions
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');

medSubj = '013AR';
matchedCtrlSubj = '064PK';
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'controlList');
capData = load('actiCap64_UOL.mat'); chanlocs = capData.chanlocs;



%% 2. Data Loading Function
function [dataM1, dataEO1] = loadSubjectData(subList, folder)
    n = length(subList); dataM1 = nan(n, 64); dataEO1 = nan(n, 64);
    for i = 1:n
        fM1 = fullfile(folder, subList{i}, ['M1_ep_v8_srtc.mat']);
        fEO1 = fullfile(folder, subList{i}, ['EO1_ep_v8_srtc.mat']);
        if exist(fM1, 'file'); tmp = load(fM1); dataM1(i,:) = tmp.tau_srtc(:); end
        if exist(fEO1, 'file'); tmp = load(fEO1); dataEO1(i,:) = tmp.tau_srtc(:); end
    end
end

% Load Target Subjects and Entire Control Group
[medM1, medEO1] = loadSubjectData({medSubj}, dataFolder);
[mCtrlM1, mCtrlEO1] = loadSubjectData({matchedCtrlSubj}, dataFolder);
[grpM1, grpEO1] = loadSubjectData(controlList, dataFolder);

%% 3. PART 1: Raw Meditation State (M1) Comparison
% Calculate Normative Distribution from Controls
ctrlMean_M1 = nanmean(grpM1, 1);
ctrlStd_M1 = nanstd(grpM1, 0, 1);

% Calculate Z-Scores for both subjects relative to "Normal"
zMed_M1 = (medM1 - ctrlMean_M1) ./ ctrlStd_M1;
zCtrl_M1 = (mCtrlM1 - ctrlMean_M1) ./ ctrlStd_M1;

% Regional Significance (p-values from averaged Z-scores)
pMed_Front = 2 * (1 - normcdf(abs(nanmean(zMed_M1(frontIdx)))));
pMed_Occ   = 2 * (1 - normcdf(abs(nanmean(zMed_M1(occIdx)))));
pMatched_Front = 2 * (1 - normcdf(abs(nanmean(zCtrl_M1(frontIdx)))));
pMatched_Occ   = 2 * (1 - normcdf(abs(nanmean(zCtrl_M1(occIdx)))));

%% 4. PART 2: Baseline Corrected (M1 - EO1) Comparison
medDiff = medM1 - medEO1;
mCtrlDiff = mCtrlM1 - mCtrlEO1;
grpDiff = grpM1 - grpEO1;

ctrlMean_Diff = nanmean(grpDiff, 1);
ctrlStd_Diff = nanstd(grpDiff, 0, 1);

% Z-Scores for Baseline-Corrected Change
zMed_Diff = (medDiff - ctrlMean_Diff) ./ ctrlStd_Diff;
zCtrl_Diff = (mCtrlDiff - ctrlMean_Diff) ./ ctrlStd_Diff;

% Baseline-Corrected Regional Significance
pMed_Diff_Front = 2 * (1 - normcdf(abs(nanmean(zMed_Diff(frontIdx)))));
pMed_Diff_Occ   = 2 * (1 - normcdf(abs(nanmean(zMed_Diff(occIdx)))));

%% 5. Visualization Dashboard
figure('Name', 'Case Study Dashboard', 'Color', 'w', 'Position', [50 50 1400 900]);

% --- PART 1 PLOTS (Top Row) ---
subplot(2,3,1); topoplot(medM1, chanlocs, 'maplimits', [15 35]); title('Meditator M1'); colorbar;
subplot(2,3,2); topoplot(mCtrlM1, chanlocs, 'maplimits', [15 35]); title('Matched Ctrl M1'); colorbar;
subplot(2,3,3); topoplot(medM1 - mCtrlM1, chanlocs, 'maplimits', 'maxmin'); title('\Delta \tau (Raw M1)'); colorbar;

% --- PART 2 PLOTS (Bottom Row) ---
subplot(2,3,4); topoplot(medDiff, chanlocs, 'maplimits', [-5 10]); title('Meditator (M1-EO1)'); colorbar;
subplot(2,3,5); topoplot(mCtrlDiff, chanlocs, 'maplimits', [-5 10]); title('Matched Ctrl (M1-EO1)'); colorbar;
subplot(2,3,6); topoplot(medDiff - mCtrlDiff, chanlocs, 'maplimits', 'maxmin'); title('\Delta \tau (Baseline Corrected)'); colorbar;

% Display Statistical Summary
fprintf('\n--- PART 1: Raw M1 Significance (vs Normative Population) ---\n');
fprintf('Meditator (013AR)  | Frontal: p=%.4f | Occipital: p=%.4f\n', pMed_Front, pMed_Occ);
fprintf('Matched Ctrl (064PK)| Frontal: p=%.4f | Occipital: p=%.4f\n', pMatched_Front, pMatched_Occ);

fprintf('\n--- PART 2: Baseline Corrected Significance (vs Normative Change) ---\n');
fprintf('Meditator (013AR)  | Frontal: p=%.4f | Occipital: p=%.4f\n', pMed_Diff_Front, pMed_Diff_Occ);