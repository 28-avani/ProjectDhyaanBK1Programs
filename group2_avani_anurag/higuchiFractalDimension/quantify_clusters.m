% =========================================================================
% PAPER EXTENSION: Multivariate Cluster Quantification
% Analyzes the 2D separability of Meditators vs Controls in Delta State-Space
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

protM1 = 4; protEO1 = 1; freqIdx = 1; % Broadband
hpElecs = [14:16, 18:20, 32+[12:15, 17:20]]; % Occipital Hub

% --- 2. EXTRACT MATCHED DATA ---
numSubjs = length(allSubjs);
hfd_BL = nan(numSubjs, 1); fooof_BL = nan(numSubjs, 1);
hfd_ST = nan(numSubjs, 1); fooof_ST = nan(numSubjs, 1);

fprintf('Extracting Data for Cluster Analysis...\n');
for i = 1:numSubjs
    subj = allSubjs{i};
    
    % HFD
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
    
    % FOOOF
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

% --- 3. MULTIVARIATE STATISTICS (MANOVA) ---
% We test if the 2D points [df, dh] are significantly different between Med and Ctrl
X_2D = [df, dh];
[d, p_manova, stats] = manova1(X_2D, isM);

% --- 4. VISUALIZATION DASHBOARD ---
figure('Name', 'Multivariate Cluster Quantification', 'Color', 'w', 'Position', [100 100 800 650]);
hold on;

% Plot Origin (No Shift)
plot([-1 1]*max(abs(xlim)), [0 0], 'k:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
plot([0 0], [-1 1]*max(abs(ylim)), 'k:', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Plot Scatters
scatter(df(isM), dh(isM), 80, [0.8 0.2 0.2], 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Meditators');
scatter(df(~isM), dh(~isM), 80, [0.2 0.2 0.8], 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Controls');

% Calculate and Plot 95% Confidence Ellipses
[muM, covM] = plotEllipse(df(isM), dh(isM), [0.8 0.2 0.2]);
[muC, covC] = plotEllipse(df(~isM), dh(~isM), [0.2 0.2 0.8]);

% Plot Centroids
plot(muM(1), muM(2), 'p', 'MarkerSize', 15, 'MarkerFaceColor', [1 0.8 0], 'MarkerEdgeColor', 'k', 'DisplayName', 'Med Centroid');
plot(muC(1), muC(2), 'p', 'MarkerSize', 15, 'MarkerFaceColor', [0 0.8 1], 'MarkerEdgeColor', 'k', 'DisplayName', 'Ctrl Centroid');

% Formatting
xlabel('\Delta 1/f Slope (M1 - EO1)', 'FontWeight', 'bold', 'FontSize', 13);
ylabel('\Delta HFD (M1 - EO1)', 'FontWeight', 'bold', 'FontSize', 13);
title('2D Cluster Separability (95% Confidence Ellipses)', 'FontSize', 16);
legend('Location', 'northeast'); grid on; box on;

% Add Statistical Results Box
if p_manova < 0.0001; pStr = sprintf('%.2e', p_manova); else; pStr = sprintf('%.4f', p_manova); end

statBox = sprintf('MANOVA 2D Separation:\np-value = %s\n\nCentroid Distance:\n%.3f units', ...
                  pStr, norm(muM - muC));
              
xL = xlim; yL = ylim;
text(xL(1) + 0.05*(xL(2)-xL(1)), yL(1) + 0.1*(yL(2)-yL(1)), statBox, ...
    'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 8);

%% --- HELPER FUNCTION: 95% CONFIDENCE ELLIPSE ---
function [mu, covMat] = plotEllipse(x, y, color)
    % Calculates and plots a 2D confidence ellipse using eigenvalues
    covMat = cov(x, y);
    mu = [mean(x), mean(y)];
    
    [V, D] = eig(covMat);
    t = linspace(0, 2*pi, 100);
    
    % 2.4477 is the critical value for 95% confidence in 2 degrees of freedom (Chi-Square)
    a = sqrt(D(1,1)) * 2.4477; 
    b = sqrt(D(2,2)) * 2.4477;
    
    ellipse_x_r  = a*cos(t);
    ellipse_y_r  = b*sin(t);
    
    % Rotate and translate the ellipse
    ellipse_rot = V * [ellipse_x_r; ellipse_y_r];
    x_plot = ellipse_rot(1,:) + mu(1);
    y_plot = ellipse_rot(2,:) + mu(2);
    
    % Plot shaded region and boundary
    fill(x_plot, y_plot, color, 'FaceAlpha', 0.1, 'EdgeColor', color, 'LineWidth', 2, 'HandleVisibility', 'off');
end