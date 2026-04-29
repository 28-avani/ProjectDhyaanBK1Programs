% =========================================================================
% PAPER REPLICATION: Figure 3 & 4 (Sliding Window HFD Spectral Profile)
% Plots Median HFD vs Center Frequency with Shaded SEM and WRS tests.
% =========================================================================
clear; clc;

% --- 1. SETUP ---
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
hfdFolder = fullfile(basePath, 'meditationDataset', 'HFDData');
load(fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles', 'BK1AllSubjectList.mat'));

protM1 = 4; protEO1 = 1;
freqCenters = [50.5, 70, 90, 110, 130, 150]; % Based on 20Hz sliding windows
numFreqs = length(freqCenters);

% Occipital/High-Priority Electrodes (as used in the paper's TF plots)
hpElecs = [14:16, 18:20, 32+[12:15, 17:20]]; 

% --- 2. ROBUST DATA EXTRACTION ---
[medM1, medEO1] = loadSliding(meditatorList, hfdFolder, protM1, protEO1, hpElecs);
[ctrlM1, ctrlEO1] = loadSliding(controlList, hfdFolder, protM1, protEO1, hpElecs);

medDiff = medM1 - medEO1;
ctrlDiff = ctrlM1 - ctrlEO1;

% --- 3. VISUALIZATION ---
figure('Name', 'HFD Spectral Profile (Sliding Window)', 'Color', 'w', 'Position', [100 100 1200 500]);

% Subplot A: Raw M1 HFD vs Frequency
subplot(1,2,1);
plotSpectral(freqCenters, medM1, ctrlM1, 'Raw HFD during Meditation (M1)', 'HFD');

% Subplot B: Delta HFD vs Frequency
subplot(1,2,2);
plotSpectral(freqCenters, medDiff, ctrlDiff, '\Delta HFD (M1 - EO1)', '\Delta HFD');

sgtitle('High-Frequency HFD Spectral Profile (Occipital Hub)', 'FontSize', 18, 'FontWeight', 'bold');

%% --- HELPER FUNCTIONS ---
function [dataM1, dataEO1] = loadSliding(subList, folder, pM1, pEO1, elecs)
    n = length(subList); dataM1 = nan(n, 6); dataEO1 = nan(n, 6);
    for i = 1:n
        files = dir(fullfile(folder, [subList{i} '*Sliding.mat']));
        if ~isempty(files)
            try
                tmp = load(fullfile(folder, files(1).name));
                % Average across the targeted electrodes for each of the 6 freq bands
                if isfield(tmp, 'hfdValsST') && length(tmp.hfdValsST) >= pM1 && ~isempty(tmp.hfdValsST{pM1})
                    dataM1(i,:) = nanmean(tmp.hfdValsST{pM1}(elecs, :), 1);
                end
                if isfield(tmp, 'hfdValsBL') && length(tmp.hfdValsBL) >= pEO1 && ~isempty(tmp.hfdValsBL{pEO1})
                    dataEO1(i,:) = nanmean(tmp.hfdValsBL{pEO1}(elecs, :), 1);
                end
            catch; end
        end
    end
end

function plotSpectral(x, dMed, dCtrl, tStr, yLab)
    hold on;
    % Calculate Medians and Standard Error of Median (SEM)
    mMed = nanmedian(dMed, 1); mCtrl = nanmedian(dCtrl, 1);
    semMed = (nanstd(dMed, 1) ./ sqrt(sum(~isnan(dMed)))) * 1.253; % Approx SEM for median
    semCtrl = (nanstd(dCtrl, 1) ./ sqrt(sum(~isnan(dCtrl)))) * 1.253;
    
    % Plot Shaded Errors
    fill([x, fliplr(x)], [mMed+semMed, fliplr(mMed-semMed)], [0.8 0.2 0.2], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    fill([x, fliplr(x)], [mCtrl+semCtrl, fliplr(mCtrl-semCtrl)], [0.2 0.2 0.8], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    
    % Plot Median Lines
    plot(x, mMed, 'Color', [0.8 0 0], 'LineWidth', 2.5, 'DisplayName', 'Meditators');
    plot(x, mCtrl, 'Color', [0 0 0.8], 'LineWidth', 2.5, 'DisplayName', 'Controls');
    
    % Formatting
    xlabel('Center Frequency (Hz)', 'FontWeight', 'bold'); ylabel(yLab, 'FontWeight', 'bold');
    title(tStr, 'FontSize', 14); grid on; legend('Location', 'northeast');
    
    % Abscissa Significance Bars (Wilcoxon Rank-Sum)
    yLim = ylim; yBase = yLim(1) + 0.05 * (yLim(2) - yLim(1));
    for f = 1:length(x)
        p = ranksum(dMed(:,f), dCtrl(:,f)); % Non-parametric test per paper
        if p < 0.05
            plot([x(f)-5, x(f)+5], [yBase, yBase], 'k-', 'LineWidth', 4, 'HandleVisibility', 'off');
        end
    end
end