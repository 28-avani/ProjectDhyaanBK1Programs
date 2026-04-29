% =========================================================================
% Single-Subject Case Study: Normative Z-Scoring & Significant Electrodes
% Meditator: 013AR  |  Matched Control: 064PK
% =========================================================================

clear; clc;

%% 1. Setup Paths and Parameters
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');

medSubj = '013AR';
matchedCtrlSubj = '064PK';
protocol = 'M1'; % Focusing purely on the Meditation state

% Load Metadata & Cap Data
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'controlList');
capData = load('actiCap64_UOL.mat'); chanlocs = capData.chanlocs;
numElecs = 64;

%% 2. Load Data for Target Subjects and the ENTIRE Control Group
function data = loadSingleProtocol(subList, prot, folder, nElec)
    nSubj = length(subList); data = nan(nSubj, nElec);
    for i = 1:nSubj
        fName = fullfile(folder, subList{i}, [prot '_ep_v8_srtc.mat']);
        if exist(fName, 'file')
            tmp = load(fName);
            if isfield(tmp, 'tau_srtc'); data(i, :) = tmp.tau_srtc; end
        end
    end
end

% Extract Data
medData = loadSingleProtocol({medSubj}, protocol, dataFolder, numElecs);
matchedCtrlData = loadSingleProtocol({matchedCtrlSubj}, protocol, dataFolder, numElecs);
ctrlGroupData = loadSingleProtocol(controlList, protocol, dataFolder, numElecs);

%% 3. Calculate Normative Z-Scores & p-values
% Find the mean and standard dev of the "normal" non-meditating brain
ctrlMean = nanmean(ctrlGroupData, 1);
ctrlStd = nanstd(ctrlGroupData, 0, 1);

% Calculate Z-Score for 013AR: (Value - Mean) / StdDev
zScores = (medData - ctrlMean) ./ ctrlStd;

% Convert Z-score to two-tailed p-value
pValues = 2 * (1 - normcdf(abs(zScores)));

% Identify Significant Electrodes (p < 0.05 is roughly |Z| > 1.96)
sigIdx = find(pValues < 0.05);
[~, sortOrder] = sort(abs(zScores(sigIdx)), 'descend');
sortedSigIdx = sigIdx(sortOrder); % Sorted from most to least significant

% Pick Top 7 to display on the Bar Chart (to prevent clutter)
numToDisplay = min(7, length(sortedSigIdx));
targetIdx = sortedSigIdx(1:numToDisplay);

%% 4. Visualization Dashboard
figure('Name', sprintf('Case Study: %s vs Normative Baseline', medSubj), ...
       'Color', 'w', 'Position', [50 100 1200 700]);

% --- TOP ROW: Spatial Topography ---
cLims = [min([medData, matchedCtrlData]), max([medData, matchedCtrlData])];

% Plot A: Meditator
subplot(2, 3, 1);
topoplot(medData, chanlocs, 'maplimits', cLims, 'electrodes', 'on');
title(sprintf('%s (Meditator)', medSubj), 'Color', [0.8 0.2 0.2], 'FontSize', 12); colorbar;

% Plot B: Matched Control
subplot(2, 3, 2);
topoplot(matchedCtrlData, chanlocs, 'maplimits', cLims, 'electrodes', 'on');
title(sprintf('%s (Matched Ctrl)', matchedCtrlSubj), 'Color', [0.2 0.2 0.8], 'FontSize', 12); colorbar;

% Plot C: Difference Map with Highlights
diffMap = medData - matchedCtrlData;
subplot(2, 3, 3);
% Use emarker2 to draw bright green circles around significant electrodes
topoplot(diffMap, chanlocs, 'maplimits', 'maxmin', ...
         'emarker2', {targetIdx, 'o', [0 0.8 0], 8, 2.5});
title('\Delta \tau (Med - Ctrl)', 'FontSize', 12); colorbar;
text(0, -0.65, 'Green rings = Significant Electrodes', 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0 0.6 0]);

% --- BOTTOM ROW: Significant Electrodes Bar Plot ---
subplot(2, 3, [4 5 6]); hold on;

if ~isempty(targetIdx)
    % Prepare data for grouped bar chart
    barData = [medData(targetIdx)', matchedCtrlData(targetIdx)'];
    
    % Plot Bars
    b = bar(barData, 'EdgeColor', 'k', 'LineWidth', 1);
    b(1).FaceColor = [0.8 0.3 0.3]; % Meditator Red
    b(2).FaceColor = [0.3 0.3 0.8]; % Control Blue
    
    % Set X-Axis labels to electrode names
    elecNames = {chanlocs(targetIdx).labels};
    set(gca, 'XTick', 1:length(targetIdx), 'XTickLabel', elecNames, 'FontSize', 11);
    ylabel('\tau (ms)', 'FontSize', 12, 'FontWeight', 'bold');
    title('Top Significant Electrodes (Normative Z-Test)', 'FontSize', 14);
    legend(sprintf('Meditator (%s)', medSubj), sprintf('Matched Ctrl (%s)', matchedCtrlSubj), 'Location', 'northeast');
    
    % Add p-values and significance brackets above the bars
    yMax = max(barData(:)) * 1.1;
    ylim([0, yMax * 1.2]); % Give space for text
    
    for i = 1:length(targetIdx)
        pval = pValues(targetIdx(i));
        
        % Formatting the bracket
        xCenter = i;
        bracketY = max(barData(i,:)) + (yMax * 0.05);
        
        % Draw Bracket
        plot([xCenter-0.15, xCenter+0.15], [bracketY, bracketY], '-k', 'LineWidth', 1.2);
        
        % Text Label
        sigTxt = sprintf('p = %.4f', pval);
        if pval < 0.001; sigTxt = 'p < 0.001 ***';
        elseif pval < 0.01; sigTxt = sprintf('p = %.3f **', pval);
        elseif pval < 0.05; sigTxt = sprintf('p = %.3f *', pval);
        end
        
        text(xCenter, bracketY + (yMax * 0.05), sigTxt, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 10);
    end
else
    title('No electrodes reached normative significance (p < 0.05).');
end
grid on;