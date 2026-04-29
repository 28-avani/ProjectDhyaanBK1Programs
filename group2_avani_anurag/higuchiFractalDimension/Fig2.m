% =========================================================================
% PAPER REPLICATION: Figure 2 (Spatial Maps & Non-Parametric Distributions)
% Analyzes HFD (1-90Hz) and FOOOF (1-150Hz) for M1 and Delta (M1-EO1)
% =========================================================================
clear; clc;

% --- 1. SETUP ---
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
hfdFolder = fullfile(basePath, 'meditationDataset', 'HFDData');
fooofFolder = fullfile(basePath, 'meditationDataset', 'FOOOFData');
if ~exist(fooofFolder, 'dir'); fooofFolder = '/Users/anuragsarkar/Desktop/NSPCourse/FOOOFData'; end

load(fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles', 'BK1AllSubjectList.mat'));
load('actiCap64_UOL.mat', 'chanlocs');

% Extract the broadband metrics (Freq Index 1)
metric = 'HFD'; % Change this to 'FOOOF' to plot FOOOF data instead
protM1 = 4; protEO1 = 1; freqIdx = 1; 

regIdx{1} = [14:16, 18:20, 32+[12:15, 17:20]];                       regName{1} = 'Occipital'; 
regIdx{2} = [6:8, 11, 12, 22, 23, 25, 28, 29, 32+[7:9, 11, 22, 24:26]]; regName{2} = 'Central'; 
regIdx{3} = [1, 3, 4, 30:32, 32+[1, 2, 4, 5, 28:31]];                regName{3} = 'Frontal'; 

% --- 2. LOAD DATA ---
fprintf('Extracting %s Data...\n', metric);
if strcmp(metric, 'HFD')
    [medM1, medEO1] = loadFixed(meditatorList, hfdFolder, 'HFD', protM1, protEO1, freqIdx);
    [ctrlM1, ctrlEO1] = loadFixed(controlList, hfdFolder, 'HFD', protM1, protEO1, freqIdx);
else
    [medM1, medEO1] = loadFixed(meditatorList, fooofFolder, 'FOOOF', protM1, protEO1, freqIdx);
    [ctrlM1, ctrlEO1] = loadFixed(controlList, fooofFolder, 'FOOOF', protM1, protEO1, freqIdx);
end

medDiff = medM1 - medEO1; ctrlDiff = ctrlM1 - ctrlEO1;

% --- 3. FIGURE 1: TOPOPLOTS ---
figure('Name', [metric ' Topographies'], 'Color', 'w', 'Position', [50 450 1200 600]);
colormap('jet');

cLimRaw = [nanmin([nanmedian(medM1, 1), nanmedian(ctrlM1, 1)]), nanmax([nanmedian(medM1, 1), nanmedian(ctrlM1, 1)])];
cLimDiff = [-nanmax(abs([nanmedian(medDiff, 1), nanmedian(ctrlDiff, 1)])), nanmax(abs([nanmedian(medDiff, 1), nanmedian(ctrlDiff, 1)]))];
if cLimDiff(1) == 0 || isnan(cLimDiff(1)); cLimDiff = [-1 1]; end

% Raw M1
subplot(2,3,1); topoplot(nanmedian(medM1, 1), chanlocs, 'maplimits', cLimRaw); title('Meditator (Raw M1)'); colorbar;
subplot(2,3,2); topoplot(nanmedian(ctrlM1, 1), chanlocs, 'maplimits', cLimRaw); title('Control (Raw M1)'); colorbar;
subplot(2,3,3); topoplot(nanmedian(medM1, 1) - nanmedian(ctrlM1, 1), chanlocs, 'maplimits', 'maxmin'); title('Difference (Med - Ctrl)'); colorbar;

% Delta
subplot(2,3,4); topoplot(nanmedian(medDiff, 1), chanlocs, 'maplimits', cLimDiff); title('Meditator \Delta (M1-EO1)'); colorbar;
subplot(2,3,5); topoplot(nanmedian(ctrlDiff, 1), chanlocs, 'maplimits', cLimDiff); title('Control \Delta (M1-EO1)'); colorbar;
subplot(2,3,6); topoplot(nanmedian(medDiff, 1) - nanmedian(ctrlDiff, 1), chanlocs, 'maplimits', 'maxmin'); title('Difference (\DeltaMed - \DeltaCtrl)'); colorbar;
sgtitle([metric ' Spatial Distribution (Median)'], 'FontSize', 18, 'FontWeight', 'bold');

% --- 4. FIGURE 2: NON-PARAMETRIC VIOLIN DISTRIBUTIONS ---
figure('Name', [metric ' Distributions'], 'Color', 'w', 'Position', [50 50 1200 600]);

for r = 1:3
    % Calculate regional averages
    mM1_reg = nanmean(medM1(:, regIdx{r}), 2); cM1_reg = nanmean(ctrlM1(:, regIdx{r}), 2);
    mDf_reg = nanmean(medDiff(:, regIdx{r}), 2); cDf_reg = nanmean(ctrlDiff(:, regIdx{r}), 2);
    
    subplot(2, 3, r); plotViolin(mM1_reg, cM1_reg, [regName{r} ' (Raw)']);
    subplot(2, 3, r+3); plotViolin(mDf_reg, cDf_reg, [regName{r} ' (\Delta)']);
end
sgtitle([metric ' Regional Distributions (Wilcoxon Rank-Sum)'], 'FontSize', 18, 'FontWeight', 'bold');

%% --- ROBUST HELPER FUNCTIONS ---

function [dataM1, dataEO1] = loadFixed(subList, folder, type, pM1, pEO1, fIdx)
    n = length(subList); dataM1 = nan(n, 64); dataEO1 = nan(n, 64);
    for i = 1:n
        files = dir(fullfile(folder, [subList{i} '*.mat'])); 
        targetFile = '';
        
        for f = 1:length(files)
            if strcmp(type, 'FOOOF') && contains(files(f).name, 'FOOOF')
                targetFile = files(f).name; break;
            elseif strcmp(type, 'HFD') && ~contains(files(f).name, 'Sliding') && ~contains(files(f).name, 'FOOOF')
                targetFile = files(f).name; break;
            end
        end
        
        if ~isempty(targetFile)
            try
                tmp = load(fullfile(folder, targetFile));
                if strcmp(type, 'FOOOF')
                    if isfield(tmp, 'exponentST') && length(tmp.exponentST)>=pM1 && ~isempty(tmp.exponentST{pM1}); dataM1(i,:) = tmp.exponentST{pM1}(:,fIdx)'; end
                    if isfield(tmp, 'exponentBL') && length(tmp.exponentBL)>=pEO1 && ~isempty(tmp.exponentBL{pEO1}); dataEO1(i,:) = tmp.exponentBL{pEO1}(:,fIdx)'; end
                else
                    if isfield(tmp, 'hfdValsST') && length(tmp.hfdValsST)>=pM1 && ~isempty(tmp.hfdValsST{pM1}); dataM1(i,:) = tmp.hfdValsST{pM1}(:,fIdx)'; end
                    if isfield(tmp, 'hfdValsBL') && length(tmp.hfdValsBL)>=pEO1 && ~isempty(tmp.hfdValsBL{pEO1}); dataEO1(i,:) = tmp.hfdValsBL{pEO1}(:,fIdx)'; end
                end
            catch
                % Silently skip corrupted files
            end
        end
    end
end

function plotViolin(mY, cY, tStr)
    vM = ~isnan(mY); vC = ~isnan(cY); 
    mY = mY(vM); cY = cY(vC);
    
    if isempty(mY) || isempty(cY)
        title([tStr ' (No Data)']); return; 
    end
    
    % Boxplot skeleton (no symbol for outliers since we overlay scatter)
    bh = boxplot([mY; cY], [ones(size(mY)); 2*ones(size(cY))], 'Labels', {'Med', 'Ctrl'}, 'Colors', 'k', 'Symbol', '');
    set(bh, 'LineWidth', 1.5); hold on;
    
    % Add jittered scatter points for "violin" feel
    jM = (rand(size(mY))-0.5)*0.15; 
    scatter(ones(size(mY))+jM, mY, 30, [0.8 0.2 0.2], 'filled', 'MarkerFaceAlpha', 0.5);
    
    jC = (rand(size(cY))-0.5)*0.15; 
    scatter(2*ones(size(cY))+jC, cY, 30, [0.2 0.2 0.8], 'filled', 'MarkerFaceAlpha', 0.5);
    
    % Wilcoxon Rank-Sum (Matches the EJN 2025 paper)
    p = ranksum(mY, cY);
    
    yMx = nanmax([mY;cY]); yMn = nanmin([mY;cY]); 
    yR = nanmax(0.1, yMx - yMn);
    
    line([1, 2], [yMx+0.1*yR, yMx+0.1*yR], 'Color', 'k', 'LineWidth', 1.2);
    
    star = 'n.s.'; 
    if p<0.05; star = sprintf('p=%.3f *', p); end
    
    text(1.5, yMx+0.18*yR, star, 'HorizontalAlignment','center','FontWeight','bold','FontSize',11);
    ylim([yMn-0.2*yR, yMx+0.4*yR]); grid on; title(tStr, 'FontSize', 14);
end