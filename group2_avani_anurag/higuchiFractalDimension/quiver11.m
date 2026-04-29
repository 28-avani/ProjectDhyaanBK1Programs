% =========================================================================
% PAPER EXTENSION: State-Space Trajectory and Delta Anticorrelation
% Proving meditation drives the brain along the HFD-FOOOF axis.
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
freqIdx = 1; % Broadband
hpElecs = [14:16, 18:20, 32+[12:15, 17:20]]; % Occipital Hub

% --- 2. EXTRACT MATCHED DATA ---
numSubjs = length(allSubjs);
hfd_BL = nan(numSubjs, 1); fooof_BL = nan(numSubjs, 1);
hfd_ST = nan(numSubjs, 1); fooof_ST = nan(numSubjs, 1);

fprintf('Extracting Data for Trajectory Analysis...\n');
for i = 1:numSubjs
    subj = allSubjs{i};
    
    % Extract HFD
    hfdFile = dir(fullfile(hfdFolder, [subj '*.mat']));
    hfdFile = hfdFile(~contains({hfdFile.name}, 'Sliding') & ~contains({hfdFile.name}, 'FOOOF'));
    if ~isempty(hfdFile)
        try
            tmpH = load(fullfile(hfdFolder, hfdFile(1).name), 'hfdValsBL', 'hfdValsST');
            if isfield(tmpH, 'hfdValsBL') && length(tmpH.hfdValsBL) >= protEO1 && ~isempty(tmpH.hfdValsBL{protEO1})
                hfd_BL(i) = nanmedian(tmpH.hfdValsBL{protEO1}(hpElecs, freqIdx));
            end
            if isfield(tmpH, 'hfdValsST') && length(tmpH.hfdValsST) >= protM1 && ~isempty(tmpH.hfdValsST{protM1})
                hfd_ST(i) = nanmedian(tmpH.hfdValsST{protM1}(hpElecs, freqIdx));
            end
        catch; end
    end
    
    % Extract FOOOF
    fooofFile = dir(fullfile(fooofFolder, [subj '*FOOOF.mat']));
    if ~isempty(fooofFile)
        try
            tmpF = load(fullfile(fooofFolder, fooofFile(1).name), 'exponentBL', 'exponentST');
            if isfield(tmpF, 'exponentBL') && length(tmpF.exponentBL) >= protEO1 && ~isempty(tmpF.exponentBL{protEO1})
                fooof_BL(i) = nanmedian(tmpF.exponentBL{protEO1}(hpElecs, freqIdx));
            end
            if isfield(tmpF, 'exponentST') && length(tmpF.exponentST) >= protM1 && ~isempty(tmpF.exponentST{protM1})
                fooof_ST(i) = nanmedian(tmpF.exponentST{protM1}(hpElecs, freqIdx));
            end
        catch; end
    end
end

% Filter valid complete pairs
valid = ~isnan(hfd_BL) & ~isnan(fooof_BL) & ~isnan(hfd_ST) & ~isnan(fooof_ST);
f_BL = fooof_BL(valid); h_BL = hfd_BL(valid);
f_ST = fooof_ST(valid); h_ST = hfd_ST(valid);
isM = isMed(valid);

% Calculate Deltas (M1 - EO1)
df = f_ST - f_BL;
dh = h_ST - h_BL;

% --- 3. VISUALIZATION DASHBOARD ---
figure('Name', 'State-Space Dynamics', 'Color', 'w', 'Position', [100 100 1200 550]);

% --- PLOT 1: State-Space Trajectories (Quiver) ---
subplot(1,2,1); hold on;

% Plot Meditator Trajectories (Red Arrows)
quiver(f_BL(isM), h_BL(isM), df(isM), dh(isM), 0, 'Color', [0.8 0.2 0.2], 'LineWidth', 1.2, 'MaxHeadSize', 0.15, 'DisplayName', 'Meditator Shift');
% Plot Control Trajectories (Blue Arrows)
quiver(f_BL(~isM), h_BL(~isM), df(~isM), dh(~isM), 0, 'Color', [0.2 0.2 0.8], 'LineWidth', 1.2, 'MaxHeadSize', 0.15, 'DisplayName', 'Control Shift');

% Mark starting points (EO1)
scatter(f_BL(isM), h_BL(isM), 25, [0.8 0.2 0.2], 'filled', 'MarkerEdgeColor', 'w', 'HandleVisibility', 'off');
scatter(f_BL(~isM), h_BL(~isM), 25, [0.2 0.2 0.8], 'filled', 'MarkerEdgeColor', 'w', 'HandleVisibility', 'off');

xlabel('1/f Slope (FOOOF Exponent)', 'FontWeight', 'bold');
ylabel('Higuchi Fractal Dimension (HFD)', 'FontWeight', 'bold');
title('Individual Brain Trajectories (EO1 \rightarrow M1)', 'FontSize', 14);
legend('Location', 'northeast'); grid on; box on;

% --- PLOT 2: Delta vs Delta Correlation ---
subplot(1,2,2); hold on;

scatter(df(isM), dh(isM), 70, [0.8 0.2 0.2], 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Meditators');
scatter(df(~isM), dh(~isM), 70, [0.2 0.2 0.8], 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Controls');

% Spearman Correlation of the SHIFT
[R, P] = corr(df, dh, 'Type', 'Spearman');
coeffs = polyfit(df, dh, 1);
xFit = linspace(min(df), max(df), 100);
plot(xFit, polyval(coeffs, xFit), 'k--', 'LineWidth', 2, 'HandleVisibility', 'off');

% Origin lines to show directionality
xL = xlim; yL = ylim;
plot([0 0], yL, 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');
plot(xL, [0 0], 'k-', 'LineWidth', 0.5, 'HandleVisibility', 'off');

if P < 0.0001; statStr = sprintf('Spearman r = %.3f\np = %.2e', R, P); else; statStr = sprintf('Spearman r = %.3f\np = %.4f', R, P); end
text(xL(1) + 0.65*(xL(2)-xL(1)), yL(1) + 0.90*(yL(2)-yL(1)), statStr, 'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 5);

xlabel('\Delta 1/f Slope (M1 - EO1)', 'FontWeight', 'bold');
ylabel('\Delta HFD (M1 - EO1)', 'FontWeight', 'bold');
title('Correlation of State Shifts (\Delta vs \Delta)', 'FontSize', 14);
legend('Location', 'northeast'); grid on; box on;

sgtitle('Meditation as a Trajectory Along the Complexity-Inhibition Axis', 'FontSize', 18, 'FontWeight', 'bold');