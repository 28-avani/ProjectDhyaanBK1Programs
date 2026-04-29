% =========================================================================
% FOOOF Topographical Analysis: Individual and Group Level (12 Plots)
% Conditions: Raw (M1) & Baseline-Corrected (M1-EO1)
% Freq Range: Broadband [1 150] Hz
% =========================================================================
clear; clc;

%% 1. Setup Paths & Parameters
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
fooofFolder = fullfile(basePath, 'meditationDataset', 'FOOOFData');
if ~exist(fooofFolder, 'dir')
    fooofFolder = '/Users/anuragsarkar/Desktop/NSPCourse/FOOOFData'; 
end

infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'meditatorList', 'controlList');
load('actiCap64_UOL.mat', 'chanlocs'); % Ensure this is in your MATLAB path

medSubj = '013AR'; 
mCtrlSubj = '064PK';
protM1 = 4;   % Index for M1
protEO1 = 1;  % Index for EO1
freqIdx = 1;  % Broadband

%% 2. Data Extraction
fprintf('Extracting FOOOF Data...\n');

% Individual Data
[indMedM1, indMedEO1] = loadFOOOF_Robust({medSubj}, fooofFolder, protM1, protEO1, freqIdx);
[indCtrlM1, indCtrlEO1] = loadFOOOF_Robust({mCtrlSubj}, fooofFolder, protM1, protEO1, freqIdx);

% Group Data
[grpMedM1, grpMedEO1] = loadFOOOF_Robust(meditatorList, fooofFolder, protM1, protEO1, freqIdx);
[grpCtrlM1, grpCtrlEO1] = loadFOOOF_Robust(controlList, fooofFolder, protM1, protEO1, freqIdx);

% Calculate Averages and Differences
avgGrpMedM1 = nanmean(grpMedM1, 1);
avgGrpCtrlM1 = nanmean(grpCtrlM1, 1);
avgGrpMedEO1 = nanmean(grpMedEO1, 1);
avgGrpCtrlEO1 = nanmean(grpCtrlEO1, 1);

% Baseline Corrections (M1 - EO1)
indMedDiff = indMedM1 - indMedEO1;
indCtrlDiff = indCtrlM1 - indCtrlEO1;
avgGrpMedDiff = avgGrpMedM1 - avgGrpMedEO1;
avgGrpCtrlDiff = avgGrpCtrlM1 - avgGrpCtrlEO1;

%% 3. Visualization: Figure 1 - INDIVIDUAL LEVEL
figure('Name', 'FOOOF Topoplots: Individual Level', 'Color', 'w', 'Position', [50 450 1400 600]);
colormap('jet');

% --- Color Limits ---
% Synchronize color scales for accurate visual comparison
cLimRawInd = [min([indMedM1, indCtrlM1]), max([indMedM1, indCtrlM1])];
cLimDiffInd = [-max(abs([indMedDiff, indCtrlDiff])), max(abs([indMedDiff, indCtrlDiff]))];
if cLimDiffInd(1) == 0; cLimDiffInd = [-1 1]; end % Safeguard

% Row 1: Raw (M1)
subplot(2,3,1); topoplot(indMedM1, chanlocs, 'maplimits', cLimRawInd); colorbar;
title(sprintf('Meditator (%s) - Raw M1', medSubj), 'FontSize', 14);

subplot(2,3,2); topoplot(indCtrlM1, chanlocs, 'maplimits', cLimRawInd); colorbar;
title(sprintf('Control (%s) - Raw M1', mCtrlSubj), 'FontSize', 14);

subplot(2,3,3); topoplot(indMedM1 - indCtrlM1, chanlocs, 'maplimits', 'maxmin'); colorbar;
title('Difference (Med - Ctrl)', 'FontSize', 14, 'Color', [0.5 0 0]);

% Row 2: Baseline Corrected (M1 - EO1)
subplot(2,3,4); topoplot(indMedDiff, chanlocs, 'maplimits', cLimDiffInd); colorbar;
title('Meditator \Delta (M1 - EO1)', 'FontSize', 14);

subplot(2,3,5); topoplot(indCtrlDiff, chanlocs, 'maplimits', cLimDiffInd); colorbar;
title('Control \Delta (M1 - EO1)', 'FontSize', 14);

subplot(2,3,6); topoplot(indMedDiff - indCtrlDiff, chanlocs, 'maplimits', 'maxmin'); colorbar;
title('Difference (\Delta Med - \Delta Ctrl)', 'FontSize', 14, 'Color', [0.5 0 0]);

sgtitle('Individual Level FOOOF Exponent (E/I Balance)', 'FontSize', 18, 'FontWeight', 'bold');

%% 4. Visualization: Figure 2 - GROUP LEVEL
figure('Name', 'FOOOF Topoplots: Group Level', 'Color', 'w', 'Position', [50 50 1400 600]);
colormap('jet');

cLimRawGrp = [min([avgGrpMedM1, avgGrpCtrlM1]), max([avgGrpMedM1, avgGrpCtrlM1])];
cLimDiffGrp = [-max(abs([avgGrpMedDiff, avgGrpCtrlDiff])), max(abs([avgGrpMedDiff, avgGrpCtrlDiff]))];
if cLimDiffGrp(1) == 0; cLimDiffGrp = [-1 1]; end

% Row 1: Raw (M1)
subplot(2,3,1); topoplot(avgGrpMedM1, chanlocs, 'maplimits', cLimRawGrp); colorbar;
title('Meditator Group - Raw M1', 'FontSize', 14);

subplot(2,3,2); topoplot(avgGrpCtrlM1, chanlocs, 'maplimits', cLimRawGrp); colorbar;
title('Control Group - Raw M1', 'FontSize', 14);

subplot(2,3,3); topoplot(avgGrpMedM1 - avgGrpCtrlM1, chanlocs, 'maplimits', 'maxmin'); colorbar;
title('Difference (Med Avg - Ctrl Avg)', 'FontSize', 14, 'Color', [0.5 0 0]);

% Row 2: Baseline Corrected (M1 - EO1)
subplot(2,3,4); topoplot(avgGrpMedDiff, chanlocs, 'maplimits', cLimDiffGrp); colorbar;
title('Meditator Group \Delta (M1 - EO1)', 'FontSize', 14);

subplot(2,3,5); topoplot(avgGrpCtrlDiff, chanlocs, 'maplimits', cLimDiffGrp); colorbar;
title('Control Group \Delta (M1 - EO1)', 'FontSize', 14);

subplot(2,3,6); topoplot(avgGrpMedDiff - avgGrpCtrlDiff, chanlocs, 'maplimits', 'maxmin'); colorbar;
title('Difference (\Delta Med - \Delta Ctrl)', 'FontSize', 14, 'Color', [0.5 0 0]);

sgtitle('Group Level FOOOF Exponent (E/I Balance)', 'FontSize', 18, 'FontWeight', 'bold');

%% --- ROBUST LOADER FUNCTION ---
function [dataM1, dataEO1] = loadFOOOF_Robust(subList, folder, pM1, pEO1, fIdx)
    n = length(subList); 
    dataM1 = nan(n, 64); 
    dataEO1 = nan(n, 64);
    
    for i = 1:n
        searchPattern = fullfile(folder, [subList{i} '*FOOOF.mat']);
        fileInfo = dir(searchPattern);
        
        if ~isempty(fileInfo)
            tmp = load(fullfile(folder, fileInfo(1).name), 'exponentST', 'exponentBL');
            
            % Extract Task Data (M1) from ST
            if isfield(tmp, 'exponentST') && length(tmp.exponentST) >= pM1 && ~isempty(tmp.exponentST{pM1})
                dataM1(i,:) = tmp.exponentST{pM1}(:, fIdx)'; 
            end
            
            % Extract Baseline Data (EO1) from BL
            if isfield(tmp, 'exponentBL') && length(tmp.exponentBL) >= pEO1 && ~isempty(tmp.exponentBL{pEO1})
                dataEO1(i,:) = tmp.exponentBL{pEO1}(:, fIdx)'; 
            end
        end
    end
end