% =========================================================================
% HFD Individual Analysis: Meditator (013AR) vs Control (064PK)
% Generates 6 Topoplots and Regional Bar Graphs (Raw M1 & Delta M1-EO1)
% =========================================================================
clear; clc;

%% 1. SETUP PATHS & PARAMETERS
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
hfdFolder = fullfile(basePath, 'meditationDataset', 'HFDData');
if ~exist(hfdFolder, 'dir')
    hfdFolder = '/Users/anuragsarkar/Desktop/NSPCourse/HFDData'; 
end

infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'controlList');
load('actiCap64_UOL.mat', 'chanlocs'); % Ensure this is in your MATLAB path

medSubj = '013AR'; 
mCtrlSubj = '064PK';
protM1 = 4;   % Index for M1 (Meditation)
protEO1 = 1;  % Index for EO1 (Baseline)
freqIdx = 1;  % Broadband (1-90 Hz)

% Define Regions
regIdx{1} = [14:16, 18:20, 32+[12:15, 17:20]];                       regName{1} = 'Occipital'; 
regIdx{2} = [6:8, 11, 12, 22, 23, 25, 28, 29, 32+[7:9, 11, 22, 24:26]]; regName{2} = 'Central'; 
regIdx{3} = [1, 3, 4, 30:32, 32+[1, 2, 4, 5, 28:31]];                regName{3} = 'Frontal'; 
regIdx{4} = 1:64;                                                    regName{4} = 'All Brain'; 
numRegs = length(regName);

%% 2. DATA EXTRACTION
fprintf('Extracting HFD Data...\n');

% Load Individual Data
[indMedM1, indMedEO1] = loadHFD_Robust({medSubj}, hfdFolder, protM1, protEO1, freqIdx);
[indCtrlM1, indCtrlEO1] = loadHFD_Robust({mCtrlSubj}, hfdFolder, protM1, protEO1, freqIdx);

% Load Group Control Data (used to calculate significance Z-scores for the individual)
[grpCtrlM1, grpCtrlEO1] = loadHFD_Robust(controlList, hfdFolder, protM1, protEO1, freqIdx);

% Calculate Deltas (M1 - EO1)
indMedDiff = indMedM1 - indMedEO1;
indCtrlDiff = indCtrlM1 - indCtrlEO1;

%% 3. FIGURE 1: TOPOPLOTS (2x3 Grid)
figure('Name', 'HFD Topoplots: Individual Level', 'Color', 'w', 'Position', [50 450 1400 600]);
colormap('jet');

% Synchronize color scales for accurate visual comparison
cLimRaw = [min([indMedM1, indCtrlM1]), max([indMedM1, indCtrlM1])];
cLimDiff = [-max(abs([indMedDiff, indCtrlDiff])), max(abs([indMedDiff, indCtrlDiff]))];
if cLimDiff(1) == 0 || isnan(cLimDiff(1)); cLimDiff = [-0.1 0.1]; end % Safeguard

% --- Row 1: Raw (M1) ---
subplot(2,3,1); topoplot(indMedM1, chanlocs, 'maplimits', cLimRaw); colorbar;
title(sprintf('Meditator (%s) - Raw M1', medSubj), 'FontSize', 14);

subplot(2,3,2); topoplot(indCtrlM1, chanlocs, 'maplimits', cLimRaw); colorbar;
title(sprintf('Control (%s) - Raw M1', mCtrlSubj), 'FontSize', 14);

subplot(2,3,3); topoplot(indMedM1 - indCtrlM1, chanlocs, 'maplimits', 'maxmin'); colorbar;
title('Difference (Med - Ctrl)', 'FontSize', 14, 'Color', [0.5 0 0]);

% --- Row 2: Baseline Corrected (M1 - EO1) ---
subplot(2,3,4); topoplot(indMedDiff, chanlocs, 'maplimits', cLimDiff); colorbar;
title('Meditator \Delta (M1 - EO1)', 'FontSize', 14);

subplot(2,3,5); topoplot(indCtrlDiff, chanlocs, 'maplimits', cLimDiff); colorbar;
title('Control \Delta (M1 - EO1)', 'FontSize', 14);

subplot(2,3,6); topoplot(indMedDiff - indCtrlDiff, chanlocs, 'maplimits', 'maxmin'); colorbar;
title('Difference (\Delta Med - \Delta Ctrl)', 'FontSize', 14, 'Color', [0.5 0 0]);

sgtitle(['Individual HFD Spatial Distribution: ' medSubj ' vs ' mCtrlSubj], 'FontSize', 18, 'FontWeight', 'bold');

%% 4. FIGURE 2: REGIONAL BAR GRAPHS
med_Raw = nan(1, numRegs); ctrl_Raw = nan(1, numRegs);
med_Delta = nan(1, numRegs); ctrl_Delta = nan(1, numRegs);
pMed_R = nan(1, numRegs); pCtrl_R = nan(1, numRegs);
pMed_D = nan(1, numRegs); pCtrl_D = nan(1, numRegs);

for r = 1:numRegs
    idx = regIdx{r};
    
    % PART 1: RAW (M1)
    med_Raw(r) = nanmean(indMedM1(idx)); 
    ctrl_Raw(r) = nanmean(indCtrlM1(idx));
    grpRawDist = nanmean(grpCtrlM1(:, idx), 2); % Background normative distribution
    pMed_R(r) = calcZStat(med_Raw(r), grpRawDist); 
    pCtrl_R(r) = calcZStat(ctrl_Raw(r), grpRawDist);
    
    % PART 2: DELTA (M1 - EO1)
    med_Delta(r) = nanmean(indMedDiff(idx));
    ctrl_Delta(r) = nanmean(indCtrlDiff(idx));
    grpDiffDist = nanmean(grpCtrlM1(:, idx), 2) - nanmean(grpCtrlEO1(:, idx), 2);
    pMed_D(r) = calcZStat(med_Delta(r), grpDiffDist); 
    pCtrl_D(r) = calcZStat(ctrl_Delta(r), grpDiffDist);
end

figure('Name', 'HFD Regional Comparison', 'Color', 'w', 'Position', [100 100 1100 900]);

% Plot Raw
subplot(2,1,1); 
plotGroupedBars(gca, [med_Raw', ctrl_Raw'], pMed_R, pCtrl_R, regName, 'PART 1: Raw Complexity (M1)', 'Raw HFD');

% Plot Delta
subplot(2,1,2); 
plotGroupedBars(gca, [med_Delta', ctrl_Delta'], pMed_D, pCtrl_D, regName, 'PART 2: \Delta Complexity (M1-EO1)', '\Delta HFD');

sgtitle(['Individual HFD Hub Analysis: ' medSubj ' vs ' mCtrlSubj], 'FontSize', 18, 'FontWeight', 'bold');

%% --- ROBUST HELPER FUNCTIONS ---
function [dataM1, dataEO1] = loadHFD_Robust(subList, folder, pM1, pEO1, fIdx)
    n = length(subList); dataM1 = nan(n, 64); dataEO1 = nan(n, 64);
    for i = 1:n
        files = dir(fullfile(folder, [subList{i} '*.mat']));
        % Exclude Sliding windows and FOOOF files to safely grab Fixed HFD
        files = files(~contains({files.name}, 'Sliding') & ~contains({files.name}, 'FOOOF'));
        
        if ~isempty(files)
            try
                tmp = load(fullfile(folder, files(1).name), 'hfdValsST', 'hfdValsBL');
                if isfield(tmp, 'hfdValsST') && length(tmp.hfdValsST) >= pM1 && ~isempty(tmp.hfdValsST{pM1})
                    dataM1(i,:) = tmp.hfdValsST{pM1}(:, fIdx)'; 
                end
                if isfield(tmp, 'hfdValsBL') && length(tmp.hfdValsBL) >= pEO1 && ~isempty(tmp.hfdValsBL{pEO1})
                    dataEO1(i,:) = tmp.hfdValsBL{pEO1}(:, fIdx)'; 
                end
            catch; end
        end
    end
end

function p = calcZStat(val, dist)
    mu = nanmean(dist); sigma = nanstd(dist);
    if isnan(mu) || isnan(val) || sigma == 0; p = 1.0; return; end
    z = (val - mu) / sigma; 
    p = 2 * (1 - normcdf(abs(z))); % Two-tailed p-value from Z-score
end

function plotGroupedBars(ax, barData, pM, pC, names, tStr, yLab)
    axes(ax); hold on;
    if all(isnan(barData(:))); text(0.5,0.5,'NO DATA EXTRACTED','HorizontalAlignment','center','Color','r'); return; end
    
    b = bar(barData, 'EdgeColor', 'k', 'LineWidth', 1.5, 'BarWidth', 0.8);
    b(1).FaceColor = [0.8 0.3 0.3]; b(2).FaceColor = [0.3 0.3 0.8];
    set(gca, 'XTick', 1:length(names), 'XTickLabel', names, 'FontSize', 12);
    ylabel(yLab, 'FontWeight', 'bold'); title(tStr); grid on;
    legend({'Meditator (13AR)', 'Control (064PK)'}, 'Location', 'best');
    
    yMax = nanmax(barData(:)); yMin = nanmin(barData(:)); yR = nanmax(0.1, yMax - yMin);
    ylim([min(0, yMin - 0.2*yR), yMax + 0.5*yR]);
    
    for r = 1:length(names)
        % Plot Meditator Significance
        [sM, cM] = getStarStr(pM(r), [0.6 0 0]);
        valM = barData(r,1); if isnan(valM); valM = 0; end
        text(r-0.15, valM + 0.1*yR, sM, 'HorizontalAlignment','center','FontWeight','bold','Color',cM,'FontSize',14);
        
        % Plot Control Significance
        [sC, cC] = getStarStr(pC(r), [0 0 0.6]);
        valC = barData(r,2); if isnan(valC); valC = 0; end
        text(r+0.15, valC + 0.1*yR, sC, 'HorizontalAlignment','center','FontWeight','bold','Color',cC,'FontSize',14);
    end
end

function [str, col] = getStarStr(p, baseCol)
    if isnan(p) || p >= 0.05; str = 'n.s.'; col = [0.5 0.5 0.5];
    elseif p < 0.001; str = '***'; col = baseCol;
    elseif p < 0.01; str = '**'; col = baseCol;
    else; str = '*'; col = baseCol; end
end