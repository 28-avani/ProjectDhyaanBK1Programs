% =========================================================================
% PAPER REPLICATION: Group-Level HFD Distributions (4 Regions)
% Generates non-parametric violin/box plots for Occipital, Central, 
% Frontal, and All Brain regions. 
% =========================================================================
clear; clc;

% --- 1. SETUP ---
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
hfdFolder = fullfile(basePath, 'meditationDataset', 'HFDData');
if ~exist(hfdFolder, 'dir'); hfdFolder = '/Users/anuragsarkar/Desktop/NSPCourse/HFDData'; end

load(fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles', 'BK1AllSubjectList.mat'));

protM1 = 4; protEO1 = 1; freqIdx = 1; % 1 = Broadband

% Define 4 Regions (Including 'All Brain')
regIdx{1} = [14:16, 18:20, 32+[12:15, 17:20]];                       regName{1} = 'Occipital'; 
regIdx{2} = [6:8, 11, 12, 22, 23, 25, 28, 29, 32+[7:9, 11, 22, 24:26]]; regName{2} = 'Central'; 
regIdx{3} = [1, 3, 4, 30:32, 32+[1, 2, 4, 5, 28:31]];                regName{3} = 'Frontal'; 
regIdx{4} = 1:64;                                                    regName{4} = 'All Brain'; 
numRegs = length(regName);

% --- 2. LOAD DATA ---
fprintf('Extracting Group HFD Data...\n');
[medM1, medEO1] = loadFixed(meditatorList, hfdFolder, protM1, protEO1, freqIdx);
[ctrlM1, ctrlEO1] = loadFixed(controlList, hfdFolder, protM1, protEO1, freqIdx);

medDiff = medM1 - medEO1; 
ctrlDiff = ctrlM1 - ctrlEO1;

% --- 3. FIGURE: NON-PARAMETRIC VIOLIN DISTRIBUTIONS ---
figure('Name', 'HFD Regional Distributions (4 Regions)', 'Color', 'w', 'Position', [50 50 1500 650]);

for r = 1:numRegs
    % Calculate regional averages per subject
    mM1_reg = nanmean(medM1(:, regIdx{r}), 2); 
    cM1_reg = nanmean(ctrlM1(:, regIdx{r}), 2);
    
    mDf_reg = nanmean(medDiff(:, regIdx{r}), 2); 
    cDf_reg = nanmean(ctrlDiff(:, regIdx{r}), 2);
    
    % Plot Raw M1 (Top Row)
    subplot(2, 4, r); 
    plotViolin(mM1_reg, cM1_reg, [regName{r} ' (Raw)']);
    
    % Plot Delta M1-EO1 (Bottom Row)
    subplot(2, 4, r+4); 
    plotViolin(mDf_reg, cDf_reg, [regName{r} ' (\Delta M1-EO1)']);
end

sgtitle('Group Level HFD Distributions (Wilcoxon Rank-Sum)', 'FontSize', 20, 'FontWeight', 'bold');

%% --- ROBUST HELPER FUNCTIONS ---
function [dataM1, dataEO1] = loadFixed(subList, folder, pM1, pEO1, fIdx)
    n = length(subList); dataM1 = nan(n, 64); dataEO1 = nan(n, 64);
    for i = 1:n
        files = dir(fullfile(folder, [subList{i} '*.mat'])); 
        targetFile = '';
        
        for f = 1:length(files)
            % Ensure we are pulling the fixed broadband HFD, not sliding or FOOOF
            if ~contains(files(f).name, 'Sliding') && ~contains(files(f).name, 'FOOOF')
                targetFile = files(f).name; break;
            end
        end
        
        if ~isempty(targetFile)
            try
                tmp = load(fullfile(folder, targetFile), 'hfdValsST', 'hfdValsBL');
                if isfield(tmp, 'hfdValsST') && length(tmp.hfdValsST)>=pM1 && ~isempty(tmp.hfdValsST{pM1})
                    dataM1(i,:) = tmp.hfdValsST{pM1}(:,fIdx)'; 
                end
                if isfield(tmp, 'hfdValsBL') && length(tmp.hfdValsBL)>=pEO1 && ~isempty(tmp.hfdValsBL{pEO1})
                    dataEO1(i,:) = tmp.hfdValsBL{pEO1}(:,fIdx)'; 
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
    scatter(ones(size(mY))+jM, mY, 35, [0.8 0.2 0.2], 'filled', 'MarkerFaceAlpha', 0.5);
    
    jC = (rand(size(cY))-0.5)*0.15; 
    scatter(2*ones(size(cY))+jC, cY, 35, [0.2 0.2 0.8], 'filled', 'MarkerFaceAlpha', 0.5);
    
    % Wilcoxon Rank-Sum (Matches the EJN 2025 paper)
    p = ranksum(mY, cY);
    
    yMx = nanmax([mY;cY]); yMn = nanmin([mY;cY]); 
    yR = nanmax(0.1, yMx - yMn);
    
    line([1, 2], [yMx+0.1*yR, yMx+0.1*yR], 'Color', 'k', 'LineWidth', 1.2);
    
    star = 'n.s.'; 
    if p<0.05; star = sprintf('p=%.3f *', p); end
    
    text(1.5, yMx+0.18*yR, star, 'HorizontalAlignment','center','FontWeight','bold','FontSize',12);
    ylim([yMn-0.2*yR, yMx+0.4*yR]); grid on; title(tStr, 'FontSize', 14);
end