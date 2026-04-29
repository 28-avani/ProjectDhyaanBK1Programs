% =========================================================================
% PAPER REPLICATION: HFD vs 1/f Slope Anticorrelation (Dual State)
% Proving the decoupling effect: Baseline (EO1) vs Meditation (M1)
% =========================================================================
clear; clc;

% --- 1. SETUP PATHS ---
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
hfdFolder = fullfile(basePath, 'meditationDataset', 'HFDData');
fooofFolder = fullfile(basePath, 'meditationDataset', 'FOOOFData');
if ~exist(fooofFolder, 'dir'); fooofFolder = '/Users/anuragsarkar/Desktop/NSPCourse/FOOOFData'; end

load(fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles', 'BK1AllSubjectList.mat'));
allSubjs = [meditatorList; controlList];
isMed = [true(length(meditatorList), 1); false(length(controlList), 1)];

protM1 = 4; protEO1 = 1; 
freqIdx = 1; % Broadband for both
hpElecs = [14:16, 18:20, 32+[12:15, 17:20]]; % Occipital Hub

% --- 2. EXTRACT MATCHED DATA FOR BOTH STATES ---
numSubjs = length(allSubjs);
hfd_BL = nan(numSubjs, 1); fooof_BL = nan(numSubjs, 1);
hfd_ST = nan(numSubjs, 1); fooof_ST = nan(numSubjs, 1);

fprintf('Extracting matched HFD and FOOOF data for EO1 and M1...\n');
for i = 1:numSubjs
    subj = allSubjs{i};
    
    % --- Extract HFD ---
    hfdFile = dir(fullfile(hfdFolder, [subj '*.mat']));
    hfdFile = hfdFile(~contains({hfdFile.name}, 'Sliding') & ~contains({hfdFile.name}, 'FOOOF'));
    if ~isempty(hfdFile)
        try
            tmpH = load(fullfile(hfdFolder, hfdFile(1).name), 'hfdValsBL', 'hfdValsST');
            % Baseline (EO1)
            if isfield(tmpH, 'hfdValsBL') && length(tmpH.hfdValsBL) >= protEO1 && ~isempty(tmpH.hfdValsBL{protEO1})
                hfd_BL(i) = nanmedian(tmpH.hfdValsBL{protEO1}(hpElecs, freqIdx));
            end
            % Meditation (M1)
            if isfield(tmpH, 'hfdValsST') && length(tmpH.hfdValsST) >= protM1 && ~isempty(tmpH.hfdValsST{protM1})
                hfd_ST(i) = nanmedian(tmpH.hfdValsST{protM1}(hpElecs, freqIdx));
            end
        catch; end
    end
    
    % --- Extract FOOOF ---
    fooofFile = dir(fullfile(fooofFolder, [subj '*FOOOF.mat']));
    if ~isempty(fooofFile)
        try
            tmpF = load(fullfile(fooofFolder, fooofFile(1).name), 'exponentBL', 'exponentST');
            % Baseline (EO1)
            if isfield(tmpF, 'exponentBL') && length(tmpF.exponentBL) >= protEO1 && ~isempty(tmpF.exponentBL{protEO1})
                fooof_BL(i) = nanmedian(tmpF.exponentBL{protEO1}(hpElecs, freqIdx));
            end
            % Meditation (M1)
            if isfield(tmpF, 'exponentST') && length(tmpF.exponentST) >= protM1 && ~isempty(tmpF.exponentST{protM1})
                fooof_ST(i) = nanmedian(tmpF.exponentST{protM1}(hpElecs, freqIdx));
            end
        catch; end
    end
end

% --- 3. VISUALIZATION ---
figure('Name', 'State-Dependent Anticorrelation', 'Color', 'w', 'Position', [100 100 1200 550]);

% Subplot A: Resting Baseline (EO1) - Should match the EJN Paper
subplot(1,2,1); 
plotScatter(fooof_BL, hfd_BL, isMed, 'Resting Baseline (EO1)');

% Subplot B: Active Meditation (M1) - The "Zero" State
subplot(1,2,2); 
plotScatter(fooof_ST, hfd_ST, isMed, 'Active Meditation (M1)');

sgtitle('Decoupling of Complexity and Inhibition During Meditation', 'FontSize', 18, 'FontWeight', 'bold');

%% --- ROBUST HELPER FUNCTIONS ---
function plotScatter(xData, yData, isMed, tStr)
    hold on;
    % Filter valid pairs to prevent NaN crashes
    valid = ~isnan(xData) & ~isnan(yData);
    if sum(valid) < 3
        title([tStr ' (Insufficient Data)']); return;
    end
    
    xCln = xData(valid); yCln = yData(valid); isMCln = isMed(valid);
    
    % Scatter
    scatter(xCln(isMCln), yCln(isMCln), 70, [0.8 0.2 0.2], 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Meditators');
    scatter(xCln(~isMCln), yCln(~isMCln), 70, [0.2 0.2 0.8], 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Controls');
    
    % Statistics
    [R, P] = corr(xCln, yCln, 'Type', 'Spearman');
    coeffs = polyfit(xCln, yCln, 1);
    xFit = linspace(min(xCln), max(xCln), 100);
    plot(xFit, polyval(coeffs, xFit), 'k--', 'LineWidth', 2, 'HandleVisibility', 'off');
    
    % Bulletproof text formatting for p-values
    if P == 0 || P < 1e-10
        statStr = sprintf('Spearman r = %.3f\np < 1e-10', R);
    elseif P < 0.001
        statStr = sprintf('Spearman r = %.3f\np = %.2e', R, P);
    else
        statStr = sprintf('Spearman r = %.3f\np = %.3f', R, P);
    end
    
    xL = xlim; yL = ylim;
    text(xL(1) + 0.65*(xL(2)-xL(1)), yL(1) + 0.90*(yL(2)-yL(1)), statStr, ...
        'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 5);
    
    xlabel('1/f Slope (FOOOF Exponent)', 'FontWeight', 'bold');
    ylabel('Higuchi Fractal Dimension (HFD)', 'FontWeight', 'bold');
    title(tStr, 'FontSize', 14); legend('Location', 'southwest'); grid on; box on;
end