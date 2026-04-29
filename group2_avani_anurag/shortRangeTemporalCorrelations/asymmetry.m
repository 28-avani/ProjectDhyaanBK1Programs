% =========================================================================
% Hemispheric Asymmetry Analysis: Left vs. Right Frontal Tau (\tau)
% =========================================================================

%% 1. Setup Paths and Parameters
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');

protocol = 'M2'; % Meditation 1
eyeCond = 'ep';
trialVer = 'v8';

% Load Metadata
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'meditatorList', 'controlList');

%% 2. Map Electrodes based on actiCap 64 Convention
% Box 1 (Green) is Indices 1-32 | Box 2 (Yellow) is Indices 33-64
% Left Frontal (LF): Fp1(G1), F3(G3), F7(G4), FC5(G6), FC1(G7), AF7(Y1), AF3(Y6), F5(Y5), F1(Y4), FC3(Y11)
leftIdx  = [3, 4, 7, 8, 14, 15, 16, 17, 22, 23, 24, 25]; 

% Right Frontal (RF): Fp2(G32), F4(G30), F8(G31), FC6(G28), FC2(G25), AF8(Y29), AF4(Y30), F6(Y28), F2(Y31), FC4(Y26)
rightIdx = [1, 2, 5, 6, 9, 10, 11, 12, 18, 19, 20, 21];

%% 3. Load Data from Files
fprintf('Loading data for %s...\n', protocol);

function data = loadTau(subList, prot, eye, ver, folder)
    nSubj = length(subList); data = nan(nSubj, 64);
    for i = 1:nSubj
        fName = fullfile(folder, subList{i}, [prot '_' eye '_' ver '_srtc.mat']);
        if exist(fName, 'file')
            tmp = load(fName);
            if isfield(tmp, 'tau_srtc'); data(i, :) = tmp.tau_srtc; end
        end
    end
end

medData = loadTau(meditatorList, protocol, eyeCond, trialVer, dataFolder);
ctrlData = loadTau(controlList, protocol, eyeCond, trialVer, dataFolder);

%% 4. Calculate Asymmetry Index (FAI)
% Formula: FAI = average(tau_Left) - average(tau_Right)
medLF = nanmean(medData(:, leftIdx), 2);
medRF = nanmean(medData(:, rightIdx), 2);
medFAI = medLF - medRF;

ctrlLF = nanmean(ctrlData(:, leftIdx), 2);
ctrlRF = nanmean(ctrlData(:, rightIdx), 2);
ctrlFAI = ctrlLF - ctrlRF;

% Remove NaNs
medFAI = medFAI(~isnan(medFAI));
ctrlFAI = ctrlFAI(~isnan(ctrlFAI));

%% 5. Visualization
figure('Name', 'Hemispheric Asymmetry: Meditation (M1)', 'Color', 'w', 'Position', [100 100 850 600]);
hold on;

% Draw zero-line
line([0.5 2.5], [0 0], 'Color', [0.6 0.6 0.6], 'LineStyle', '--', 'LineWidth', 1.5);

% Plot Individual Points
scatter(ones(size(medFAI)) + (rand(size(medFAI))-0.5)*0.1, medFAI, 60, 'r', 'filled', 'MarkerFaceAlpha', 0.5);
scatter(2*ones(size(ctrlFAI)) + (rand(size(ctrlFAI))-0.5)*0.1, ctrlFAI, 60, 'b', 'filled', 'MarkerFaceAlpha', 0.5);

% Plot Boxplot
boxplot([medFAI; ctrlFAI], [ones(size(medFAI)); 2*ones(size(ctrlFAI))], 'Labels', {'Meditators', 'Controls'}, 'Widths', 0.4);

% Stats and Labeling
[~, p] = ttest2(medFAI, ctrlFAI);
yLimits = [min([medFAI; ctrlFAI])-1, max([medFAI; ctrlFAI])+2];
ylim(yLimits);

title(['Frontal Asymmetry (\tau_{Left} - \tau_{Right}) in ' protocol]);
ylabel('\Delta \tau (ms)');
text(1.5, yLimits(2)-1, sprintf('p = %.4f %s', p, char(repmat('*', 1, p < 0.05))), ...
     'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);
grid on;