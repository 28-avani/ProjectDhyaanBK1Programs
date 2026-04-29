% =========================================================================
% LONGITUDINAL ANALYSIS ACROSS ALL 6 CONDITIONS
% Plots the trajectory of the Occipital Hub for Individual and Group levels.
% Protocols: EO1 -> EC1 -> G1(Gratings) -> M1(Med) -> G2(Gratings) -> M2(Med)
% =========================================================================
clear; clc;

% --- 1. SETUP PATHS & PARAMETERS ---
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
hfdFolder = fullfile(basePath, 'meditationDataset', 'HFDData');
fooofFolder = fullfile(basePath, 'meditationDataset', 'FOOOFData');
if ~exist(hfdFolder, 'dir'); hfdFolder = '/Users/anuragsarkar/Desktop/NSPCourse/HFDData'; end
if ~exist(fooofFolder, 'dir'); fooofFolder = '/Users/anuragsarkar/Desktop/NSPCourse/FOOOFData'; end

load(fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles', 'BK1AllSubjectList.mat'));

metric = 'HFD'; % Change to 'FOOOF' to plot the 1/f Slope instead
freqIdx = 1;    % 1 = Broadband [1-90Hz for HFD, 1-150Hz for FOOOF]

medSubj = '013AR'; 
mCtrlSubj = '064PK';

% The significant Occipital Hub
occIdx = [14:16, 18:20, 32+[12:15, 17:20]]; 

% UPDATED LABELS: G1 and G2 are Visual Gratings
protNames = {'EO1', 'EC1', 'G1 (Gratings)', 'M1 (Med)', 'G2 (Gratings)', 'M2 (Med)'};
numProts = length(protNames);

% --- 2. EXTRACT LONGITUDINAL DATA ---
fprintf('Extracting %s Data across all conditions...\n', metric);
if strcmp(metric, 'HFD')
    indMed = loadAllConditions({medSubj}, hfdFolder, 'HFD', freqIdx, occIdx);
    indCtrl = loadAllConditions({mCtrlSubj}, hfdFolder, 'HFD', freqIdx, occIdx);
    grpMed = loadAllConditions(meditatorList, hfdFolder, 'HFD', freqIdx, occIdx);
    grpCtrl = loadAllConditions(controlList, hfdFolder, 'HFD', freqIdx, occIdx);
else
    indMed = loadAllConditions({medSubj}, fooofFolder, 'FOOOF', freqIdx, occIdx);
    indCtrl = loadAllConditions({mCtrlSubj}, fooofFolder, 'FOOOF', freqIdx, occIdx);
    grpMed = loadAllConditions(meditatorList, fooofFolder, 'FOOOF', freqIdx, occIdx);
    grpCtrl = loadAllConditions(controlList, fooofFolder, 'FOOOF', freqIdx, occIdx);
end

% --- 3. VISUALIZATION DASHBOARD ---
figure('Name', [metric ' Trajectory Across Conditions'], 'Color', 'w', 'Position', [100 150 1450 550]);

xVals = 1:numProts;

% --- Subplot A: Individual Trajectory (13AR vs 064PK) ---
subplot(1,2,1); hold on;

% Plot subtle background lines connecting the points
plot(xVals, indMed(1,:), '-', 'Color', [0.8 0.2 0.2 0.5], 'LineWidth', 2, 'HandleVisibility', 'off');
plot(xVals, indCtrl(1,:), '-', 'Color', [0.2 0.2 0.8 0.5], 'LineWidth', 2, 'HandleVisibility', 'off');

% Plot main scatter points
plot(xVals, indMed(1,:), 'o', 'Color', [0.8 0 0], 'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', ['Meditator (' medSubj ')']);
plot(xVals, indCtrl(1,:), 's', 'Color', [0 0 0.8], 'MarkerFaceColor', [0.2 0.2 0.8], 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', ['Control (' mCtrlSubj ')']);

xticks(xVals); xticklabels(protNames);
ylabel(['Occipital ' metric], 'FontWeight', 'bold', 'FontSize', 13);
title(['Individual Trajectory (' metric ')'], 'FontSize', 15);
legend('Location', 'best'); grid on; box on;

% --- Subplot B: Group Average Trajectory (with SEM & Stars) ---
subplot(1,2,2); hold on;

% Calculate Medians and Standard Error of the Median (SEM)
mMed = nanmedian(grpMed, 1);
mCtrl = nanmedian(grpCtrl, 1);
semMed = (nanstd(grpMed, 1) ./ sqrt(sum(~isnan(grpMed), 1))) * 1.253;
semCtrl = (nanstd(grpCtrl, 1) ./ sqrt(sum(~isnan(grpCtrl), 1))) * 1.253;

% Plot Error Bars and Lines
errorbar(xVals, mMed, semMed, '-o', 'Color', [0.8 0 0], 'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerSize', 9, 'LineWidth', 2.5, 'CapSize', 0, 'DisplayName', 'Meditator Group');
errorbar(xVals, mCtrl, semCtrl, '-s', 'Color', [0 0 0.8], 'MarkerFaceColor', [0.2 0.2 0.8], 'MarkerSize', 9, 'LineWidth', 2.5, 'CapSize', 0, 'DisplayName', 'Control Group');

xticks(xVals); xticklabels(protNames);
ylabel(['Occipital ' metric ' (Median \pm SEM)'], 'FontWeight', 'bold', 'FontSize', 13);
title(['Group Average Trajectory (' metric ')'], 'FontSize', 15);
legend('Location', 'southwest'); grid on; box on;

% Add Statistical Significance Markers (Wilcoxon Rank-Sum)
yLim = ylim; 
yRange = yLim(2) - yLim(1);
ylim([yLim(1), yLim(2) + 0.20*yRange]); % Expand Y-axis to give stars room

for p = 1:numProts
    if sum(~isnan(grpMed(:,p))) > 3 && sum(~isnan(grpCtrl(:,p))) > 3
        pval = ranksum(grpMed(:,p), grpCtrl(:,p));
        if pval < 0.05
            star = '*'; if pval < 0.01; star = '**'; end
            if pval < 0.001; star = '***'; end
            
            % Place star slightly above the highest error bar for that point
            starY = max(mMed(p)+semMed(p), mCtrl(p)+semCtrl(p)) + 0.08*yRange;
            text(p, starY, star, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 18, 'Color', 'k');
        end
    end
end

sgtitle([metric ' Dynamics Across the Experimental Session (Occipital Hub)'], 'FontSize', 18, 'FontWeight', 'bold');

%% --- ROBUST LOADER FUNCTION ---
function dataAll = loadAllConditions(subList, folder, type, fIdx, roiIdx)
    n = length(subList);
    dataAll = nan(n, 6); % 6 Protocols
    
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
                
                % Protocol 1 (EO1) & 2 (EC1) -> Pull from BL
                for p = 1:2
                    if strcmp(type, 'FOOOF') && isfield(tmp, 'exponentBL') && length(tmp.exponentBL)>=p && ~isempty(tmp.exponentBL{p})
                        dataAll(i, p) = nanmean(tmp.exponentBL{p}(roiIdx, fIdx));
                    elseif strcmp(type, 'HFD') && isfield(tmp, 'hfdValsBL') && length(tmp.hfdValsBL)>=p && ~isempty(tmp.hfdValsBL{p})
                        dataAll(i, p) = nanmean(tmp.hfdValsBL{p}(roiIdx, fIdx));
                    end
                end
                
                % Protocol 3 to 6 (G1, M1, G2, M2) -> Pull from ST
                for p = 3:6
                    if strcmp(type, 'FOOOF') && isfield(tmp, 'exponentST') && length(tmp.exponentST)>=p && ~isempty(tmp.exponentST{p})
                        dataAll(i, p) = nanmean(tmp.exponentST{p}(roiIdx, fIdx));
                    elseif strcmp(type, 'HFD') && isfield(tmp, 'hfdValsST') && length(tmp.hfdValsST)>=p && ~isempty(tmp.hfdValsST{p})
                        dataAll(i, p) = nanmean(tmp.hfdValsST{p}(roiIdx, fIdx));
                    end
                end
            catch
                % Skip corrupted files silently
            end
        end
    end
end