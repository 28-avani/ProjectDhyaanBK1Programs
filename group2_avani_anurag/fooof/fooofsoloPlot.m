% =========================================================================
% FOOOF Individual Analysis: Raw (M1) vs Baseline Corrected (M1-EO1)
% BUGFIX: Correctly routes EO1 to exponentBL instead of exponentST.
% =========================================================================
clear; clc;

% --- PATHS (Update to your local directories) ---
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
fooofFolder = fullfile(basePath, 'meditationDataset', 'FOOOFData');
% Try Desktop path if default doesn't exist
if ~exist(fooofFolder, 'dir'); fooofFolder = '/Users/anuragsarkar/Desktop/NSPCourse/FOOOFData'; end

infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'controlList');

medSubj = '013AR'; mCtrlSubj = '064PK';
protM1 = 4; protEO1 = 1; freqIdx = 1; % Broadband [1 150] Hz

%% 1. Define Combined Regions
regIdx{1} = [14:16, 18:20, 32+[12:15, 17:20]];                       regName{1} = 'Occipital'; 
regIdx{2} = [6:8, 11, 12, 22, 23, 25, 28, 29, 32+[7:9, 11, 22, 24:26]]; regName{2} = 'Central'; 
regIdx{3} = [1, 3, 4, 30:32, 32+[1, 2, 4, 5, 28:31]];                regName{3} = 'Frontal'; 
regIdx{4} = 1:64;                                                    regName{4} = 'All Brain'; 
numRegs = length(regName);

%% 2. Load and Process Data (Using Corrected Loader)
[medM1, medEO1] = loadFOOOF_Fixed({medSubj}, fooofFolder, protM1, protEO1, freqIdx);
[mCtrlM1, mCtrlEO1] = loadFOOOF_Fixed({mCtrlSubj}, fooofFolder, protM1, protEO1, freqIdx);
[grpM1, grpEO1] = loadFOOOF_Fixed(controlList, fooofFolder, protM1, protEO1, freqIdx);

med_Raw = nan(1, numRegs); ctrl_Raw = nan(1, numRegs);
med_Diff = nan(1, numRegs); ctrl_Diff = nan(1, numRegs);
pMed_R = nan(1, numRegs); pCtrl_R = nan(1, numRegs);
pMed_D = nan(1, numRegs); pCtrl_D = nan(1, numRegs);

for r = 1:numRegs
    idx = regIdx{r};
    
    % PART 1: RAW (M1)
    med_Raw(r) = nanmean(medM1(idx)); ctrl_Raw(r) = nanmean(mCtrlM1(idx));
    grpRawDist = nanmean(grpM1(:, idx), 2);
    pMed_R(r) = calcP(med_Raw(r), grpRawDist); pCtrl_R(r) = calcP(ctrl_Raw(r), grpRawDist);
    
    % PART 2: BASELINE CORRECTED (M1 - EO1)
    med_Diff(r) = med_Raw(r) - nanmean(medEO1(idx));
    ctrl_Diff(r) = ctrl_Raw(r) - nanmean(mCtrlEO1(idx));
    grpDiffDist = nanmean(grpM1(:, idx), 2) - nanmean(grpEO1(:, idx), 2);
    pMed_D(r) = calcP(med_Diff(r), grpDiffDist); pCtrl_D(r) = calcP(ctrl_Diff(r), grpDiffDist);
end

%% 3. Visualization
figure('Name', 'FOOOF Regional Comparison', 'Color', 'w', 'Position', [100 100 1100 900]);
subplot(2,1,1); plotGroupedBars(gca, [med_Raw', ctrl_Raw'], pMed_R, pCtrl_R, regName, 'PART 1: Raw Exponent (M1)', 'Raw Exponent');
subplot(2,1,2); plotGroupedBars(gca, [med_Diff', ctrl_Diff'], pMed_D, pCtrl_D, regName, 'PART 2: \Delta Exponent (M1-EO1)', '\Delta Exponent');
%sgtitle(['Individual FOOOF Analysis: ' medSubj ' vs ' mCtrlSubj], 'FontSize', 18, 'FontWeight', 'bold');

%% --- NESTED HELPER FUNCTIONS ---
function [dataM1, dataEO1] = loadFOOOF_Fixed(subList, folder, pM1, pEO1, fIdx)
    n = length(subList); dataM1 = nan(n, 64); dataEO1 = nan(n, 64);
    for i = 1:n
        files = dir(fullfile(folder, [subList{i} '*FOOOF.mat']));
        if ~isempty(files)
            % Load BOTH exponentST and exponentBL
            tmp = load(fullfile(folder, files(1).name), 'exponentST', 'exponentBL');
            % M1 is a Task -> Pull from ST
            if length(tmp.exponentST) >= pM1 && ~isempty(tmp.exponentST{pM1})
                dataM1(i,:) = tmp.exponentST{pM1}(:, fIdx)'; 
            end
            % EO1 is Resting -> Pull from BL
            if length(tmp.exponentBL) >= pEO1 && ~isempty(tmp.exponentBL{pEO1})
                dataEO1(i,:) = tmp.exponentBL{pEO1}(:, fIdx)'; 
            end
        end
    end
end

function p = calcP(val, dist)
    mu = nanmean(dist); sigma = nanstd(dist);
    if isnan(mu) || isnan(val) || sigma == 0; p = 1.0; return; end
    z = (val - mu) / sigma; p = 2 * (1 - normcdf(abs(z))); 
end

function plotGroupedBars(ax, barData, pM, pC, names, tStr, yLab)
    axes(ax); hold on;
    if all(isnan(barData(:))); text(0.5,0.5,'ERROR: NO DATA EXTRACTED','HorizontalAlignment','center','FontSize',14,'Color','r'); return; end
    b = bar(barData, 'EdgeColor', 'k', 'LineWidth', 1.5, 'BarWidth', 0.8);
    b(1).FaceColor = [0.8 0.3 0.3]; b(2).FaceColor = [0.3 0.3 0.8];
    set(gca, 'XTick', 1:length(names), 'XTickLabel', names, 'FontSize', 12);
    ylabel(yLab, 'FontWeight', 'bold'); title(tStr); grid on;
    yMax = nanmax(barData(:)); yMin = nanmin(barData(:)); yR = yMax - yMin;
    if isnan(yR) || yR == 0; yR = 0.5; end
    ylim([min(0, yMin - 0.2*yR), yMax + 0.6*yR]);
    
    for r = 1:length(names)
        [sM, cM] = getStarStr(pM(r), [0.6 0 0]);
        valM = barData(r,1); if isnan(valM); valM = 0; end
        text(r-0.15, valM + 0.1*yR, sM, 'HorizontalAlignment','center','FontWeight','bold','Color',cM,'FontSize',14);
        [sC, cC] = getStarStr(pC(r), [0 0 0.6]);
        valC = barData(r,2); if isnan(valC); valC = 0; end
        text(r+0.15, valC + 0.1*yR, sC, 'HorizontalAlignment','center','FontWeight','bold','Color',cC,'FontSize',14);
    end
end

function [str, col] = getStarStr(p, baseCol)
    if isnan(p) || p >= 0.05; str = 'n.s.'; col = [0.5 0.5 0.5];
    elseif p < 0.001; str = '***'; col = baseCol;
    elseif p < 0.01; str = '**'; col = baseCol; else; str = '*'; col = baseCol; end
end