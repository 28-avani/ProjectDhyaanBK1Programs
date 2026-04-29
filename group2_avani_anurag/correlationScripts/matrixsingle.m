% =========================================================================
% Single-Subject (013AR) 5x5 Correlation Matrix (Protocol M1)
% =========================================================================
clear; clc;

%% 1. Paths & Setup
basePath   = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset';
srtcFolder = fullfile(basePath, 'SRTCsavedData');
connFolder = fullfile(basePath, 'data', 'ftData', 'connSavedData');
fooofFolder= fullfile(basePath, 'FOOOFData');
hfdFolder  = fullfile(basePath, 'HFDData');
psdFolder  = fullfile(basePath, 'savedData');

subj = '013AR'; prot = 'M1'; eye = 'ep'; ver = 'v8';
fRange = [30 50]; 

tau = nan(64,1); fc = nan(64,1); fooof = nan(64,1); hfd = nan(64,1); psd = nan(64,1);

%% 2. Extraction Logic (Robust Column Enforcement)
disp(['--- Extracting Data for: ' subj ' ---']);

% A. SRTC
sFile = fullfile(srtcFolder, subj, [prot '_' eye '_' ver '_srtc.mat']);
if exist(sFile, 'file')
    tmp = load(sFile); tau = tmp.tau_srtc(:); 
    if isfield(tmp, 'allProtocols'); pIdx = find(strcmp(tmp.allProtocols, prot)); else; pIdx = 4; end
end

% B. Connectivity
cFile = fullfile(connFolder, subj, [prot '_' eye '_' ver '_ppc.mat']);
if exist(cFile, 'file')
    tmp = load(cFile); fIdx = find(tmp.freqPost >= fRange(1) & tmp.freqPost <= fRange(2));
    if ~isempty(fIdx); fc = squeeze(mean(mean(tmp.connPost(:,:,fIdx),3,'omitnan'),1,'omitnan'))'; fc = fc(:); end
end

% C. FOOOF
fDir = dir(fullfile(fooofFolder, [subj '*FOOOF.mat']));
if ~isempty(fDir)
    tmp = load(fullfile(fooofFolder, fDir(1).name));
    if isfield(tmp, 'exponentST'); fooof = mean(tmp.exponentST{pIdx}, 2, 'omitnan'); fooof = fooof(:); end
end

% D. HFD
hDir = dir(fullfile(hfdFolder, [subj '*Sliding.mat']));
if ~isempty(hDir)
    tmp = load(fullfile(hfdFolder, hDir(1).name));
    if isfield(tmp, 'hfdValsST'); hfd = mean(tmp.hfdValsST{pIdx}, 2, 'omitnan'); hfd = hfd(:); end
end

% E. PSD
pFileName = fullfile(psdFolder, [subj '_' eye '_' ver '_250_1250.mat']);
if exist(pFileName, 'file')
    tmp = load(pFileName); fIdx = find(tmp.freqVals >= fRange(1) & tmp.freqVals <= fRange(2));
    if ~isempty(fIdx); psd = log10(sum(tmp.psdValsST{pIdx}(:, fIdx), 2, 'omitnan'))'; psd = psd(:); end
end

%% 3. Calculate 5x5 Correlation Matrix
% Combine all metrics into a 64x5 matrix
dataMat = [tau, fc, fooof, hfd, psd];
metricNames = {'\tau (SRTC)', 'FC (PPC)', 'FOOOF Exp', 'HFD', 'Gamma PSD'};
numMetrics = length(metricNames);

% Remove rows (electrodes) that have ANY missing data
validRows = ~any(isnan(dataMat), 2);
cleanData = dataMat(validRows, :);
nValid = size(cleanData, 1);

if nValid < 5; error('Not enough overlapping valid electrodes to compute a matrix.'); end

% Compute Spearman Correlation and P-values
[R, P] = corr(cleanData, 'Type', 'Spearman');

%% 4. Visualization: Correlation Heatmap
figure('Name', 'Single Subject Correlation Matrix', 'Color', 'w', 'Position', [100 100 800 700]);

% Custom Red-White-Blue Colormap for correlations
cmap = [linspace(0,1,128)', linspace(0,1,128)', ones(128,1); 
        ones(128,1), linspace(1,0,128)', linspace(1,0,128)'];
colormap(cmap);

imagesc(R); clim([-1 1]); colorbar;
xticks(1:numMetrics); xticklabels(metricNames);
yticks(1:numMetrics); yticklabels(metricNames);
title(sprintf('Subject %s: Cross-Metric Correlation Matrix\n(Based on %d valid electrodes)', subj, nValid), 'FontSize', 16);

% Overlay R values and Significance Stars
for i = 1:numMetrics
    for j = 1:numMetrics
        r_val = R(i,j); p_val = P(i,j);
        
        if i == j; txt = '1.00'; % Diagonal is always 1
        else
            sigStr = '';
            if p_val < 0.001; sigStr = '***'; elseif p_val < 0.01; sigStr = '**'; elseif p_val < 0.05; sigStr = '*'; end
            txt = sprintf('%.2f\n%s', r_val, sigStr);
        end
        
        % Adjust text color based on background darkness
        if abs(r_val) > 0.6; tColor = 'w'; else; tColor = 'k'; end
        text(j, i, txt, 'HorizontalAlignment', 'center', 'Color', tColor, 'FontWeight', 'bold', 'FontSize', 12);
    end
end
axis square; set(gca, 'FontSize', 12);