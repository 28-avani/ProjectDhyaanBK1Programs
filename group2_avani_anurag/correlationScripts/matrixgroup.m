% =========================================================================
% Group-Level 5x5 Hub Correlation Matrix (Protocol M1)
% =========================================================================
clear; clc;

%% 1. Paths & Setup
basePath   = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset';
infoPath   = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/ProjectDhyaanBK1Programs/commonAnalysisCodes/informationFiles';
srtcFolder = fullfile(basePath, 'SRTCsavedData');
connFolder = fullfile(basePath, 'data', 'ftData', 'connSavedData');
fooofFolder= fullfile(basePath, 'FOOOFData');
hfdFolder  = fullfile(basePath, 'HFDData');
psdFolder  = fullfile(basePath, 'savedData');

prot = 'M1'; eye = 'ep'; ver = 'v8'; fRange = [30 50]; 

load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'meditatorList');
subList = meditatorList; nSubj = length(subList);

% Storage: Subjects x 5 Metrics x 64 Electrodes
allMaps = nan(nSubj, 5, 64); 

%% 2. Extraction Loop (Group)
fprintf('Extracting Group Data...\n');
for i = 1:nSubj
    subj = subList{i};
    
    % A. SRTC
    sFile = fullfile(srtcFolder, subj, [prot '_' eye '_' ver '_srtc.mat']);
    if exist(sFile, 'file')
        tmp = load(sFile); allMaps(i, 1, :) = tmp.tau_srtc(:);
        if isfield(tmp, 'allProtocols'); pIdx = find(strcmp(tmp.allProtocols, prot)); else; pIdx = 4; end
    else; continue; end

    % B. Connectivity (PPC)
    cFile = fullfile(connFolder, subj, [prot '_' eye '_' ver '_ppc.mat']);
    if exist(cFile, 'file')
        tmp = load(cFile); fIdx = find(tmp.freqPost >= fRange(1) & tmp.freqPost <= fRange(2));
        if ~isempty(fIdx); allMaps(i, 2, :) = squeeze(mean(mean(tmp.connPost(:,:,fIdx),3,'omitnan'),1,'omitnan')); end
    end

    % C. FOOOF
    fDir = dir(fullfile(fooofFolder, [subj '*FOOOF.mat']));
    if ~isempty(fDir)
        tmp = load(fullfile(fooofFolder, fDir(1).name));
        if isfield(tmp, 'exponentST') && length(tmp.exponentST) >= pIdx; allMaps(i, 3, :) = mean(tmp.exponentST{pIdx}, 2, 'omitnan'); end
    end

    % D. HFD
    hDir = dir(fullfile(hfdFolder, [subj '*.mat']));
    if ~isempty(hDir)
        tmp = load(fullfile(hfdFolder, hDir(1).name));
        if isfield(tmp, 'hfdValsST') && length(tmp.hfdValsST) >= pIdx; allMaps(i, 4, :) = mean(tmp.hfdValsST{pIdx}, 2, 'omitnan'); end
    end

    % E. PSD
    pFileName = fullfile(psdFolder, [subj '_' eye '_' ver '_250_1250.mat']);
    if exist(pFileName, 'file')
        tmp = load(pFileName); fIdx = find(tmp.freqVals >= fRange(1) & tmp.freqVals <= fRange(2));
        if ~isempty(fIdx) && length(tmp.psdValsST) >= pIdx; allMaps(i, 5, :) = log10(sum(tmp.psdValsST{pIdx}(:, fIdx), 2, 'omitnan')); end
    end
end
fprintf('Extraction Complete.\n');

%% 3. Calculate Group Average Topographies & Correlate
avgMaps = squeeze(nanmean(allMaps, 1))'; % Transpose to get 64 x 5 matrix

% Remove rows with NaNs
validRows = ~any(isnan(avgMaps), 2);
cleanAvgMaps = avgMaps(validRows, :);
nValid = size(cleanAvgMaps, 1);

[R, P] = corr(cleanAvgMaps, 'Type', 'Spearman');
metricNames = {'\tau (SRTC)', 'FC (PPC)', 'FOOOF Exp', 'HFD', 'Gamma PSD'};
numMetrics = length(metricNames);

%% 4. Visualization: Correlation Heatmap
figure('Name', 'Group-Level Hub Correlation Matrix', 'Color', 'w', 'Position', [150 150 800 700]);

cmap = [linspace(0,1,128)', linspace(0,1,128)', ones(128,1); ones(128,1), linspace(1,0,128)', linspace(1,0,128)'];
colormap(cmap);

imagesc(R); clim([-1 1]); colorbar;
xticks(1:numMetrics); xticklabels(metricNames);
yticks(1:numMetrics); yticklabels(metricNames);
title(sprintf('Group-Level Hub Correlation Matrix (N = %d Meditators)\nAre the spatial networks structurally identical?', nSubj), 'FontSize', 15);

for i = 1:numMetrics
    for j = 1:numMetrics
        r_val = R(i,j); p_val = P(i,j);
        if i == j; txt = '1.00'; 
        else
            sigStr = '';
            if p_val < 0.001; sigStr = '***'; elseif p_val < 0.01; sigStr = '**'; elseif p_val < 0.05; sigStr = '*'; end
            txt = sprintf('%.2f\n%s', r_val, sigStr);
        end
        if abs(r_val) > 0.6; tColor = 'w'; else; tColor = 'k'; end
        text(j, i, txt, 'HorizontalAlignment', 'center', 'Color', tColor, 'FontWeight', 'bold', 'FontSize', 12);
    end
end
axis square; set(gca, 'FontSize', 12);