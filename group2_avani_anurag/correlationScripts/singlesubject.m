% =========================================================================
% Final Multimodal Fingerprint: Subject 013AR (Protocol M1)
% =========================================================================
clear; clc;

%% 1. Paths & Setup
basePath   = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset';
srtcFolder = fullfile(basePath, 'SRTCsavedData');
connFolder = fullfile(basePath, 'data', 'ftData', 'connSavedData');
fooofFolder= fullfile(basePath, 'FOOOFData');
hfdFolder  = fullfile(basePath, 'HFDData');
psdFolder  = fullfile(basePath, 'savedData');

subj = '013AR';
prot = 'M1'; eye = 'ep'; ver = 'v8';
fRange = [30 50]; 

% Initialize 64x1 vectors
tau_vals = nan(64,1); fc_vals = nan(64,1); fooof_exp = nan(64,1); hfd_vals = nan(64,1); psd_vals = nan(64,1);

%% 2. Extraction Logic (Protocol-based)
disp(['--- Processing Subject: ' subj ' ---']);

% A. SRTC
sFile = fullfile(srtcFolder, subj, [prot '_' eye '_' ver '_srtc.mat']);
if exist(sFile, 'file')
    tmp = load(sFile); tau_vals = tmp.tau_srtc(:); 
    % Match protocol index for teammate's 1x6 cells
    if isfield(tmp, 'allProtocols'); pIdx = find(strcmp(tmp.allProtocols, prot)); else; pIdx = 4; end
    disp('✓ SRTC Loaded');
else; error('SRTC File Missing!'); end

% B. Connectivity
cFile = fullfile(connFolder, subj, [prot '_' eye '_' ver '_ppc.mat']);
if exist(cFile, 'file')
    tmp = load(cFile);
    fIdx = find(tmp.freqPost >= fRange(1) & tmp.freqPost <= fRange(2));
    if ~isempty(fIdx)
        fc_vals = squeeze(mean(mean(tmp.connPost(:,:,fIdx),3,'omitnan'),1,'omitnan'))';
        fc_vals = fc_vals(:); disp('✓ FC Loaded');
    end
end

% C. FOOOF (Variable: exponentST)
fDir = dir(fullfile(fooofFolder, [subj '*FOOOF.mat']));
if ~isempty(fDir)
    tmp = load(fullfile(fooofFolder, fDir(1).name));
    if isfield(tmp, 'exponentST'); fooof_exp = mean(tmp.exponentST{pIdx}, 2, 'omitnan'); disp('✓ FOOOF Loaded'); end
end

% D. HFD (Variable: hfdValsST)
hDir = dir(fullfile(hfdFolder, [subj '*.mat']));
if ~isempty(hDir)
    tmp = load(fullfile(hfdFolder, hDir(1).name));
    if isfield(tmp, 'hfdValsST'); hfd_vals = mean(tmp.hfdValsST{pIdx}, 2, 'omitnan'); disp('✓ HFD Loaded'); end
end

% E. PSD (Variable: psdValsST)
pFileName = fullfile(psdFolder, [subj '_' eye '_' ver '_250_1250.mat']);
if exist(pFileName, 'file')
    tmp = load(pFileName);
    fIdx = find(tmp.freqVals >= fRange(1) & tmp.freqVals <= fRange(2));
    if ~isempty(fIdx); psd_vals = log10(sum(tmp.psdValsST{pIdx}(:, fIdx), 2, 'omitnan'))'; disp('✓ PSD Loaded'); end
end

%% 3. Multimodal Correlation Plotting
figure('Name', ['Fingerprint: ' subj], 'Color', 'w', 'Position', [100 100 1200 900]);

subplot(2,2,1); plotCorr(tau_vals, fc_vals, '\tau (ms)', 'Global FC (PPC)', [0.2 0.7 0.2]);
subplot(2,2,2); plotCorr(tau_vals, fooof_exp, '\tau (ms)', 'FOOOF Exponent', [1 0.5 0]);
subplot(2,2,3); plotCorr(tau_vals, hfd_vals, '\tau (ms)', 'Higuchi FD', [0 0.4 1]);
subplot(2,2,4); plotCorr(tau_vals, psd_vals, '\tau (ms)', 'Gamma Power (log)', [0.7 0.2 0.6]);

sgtitle(['Multimodal Spatial Correlation for Subject ' subj ' (Protocol M1)'], 'FontSize', 18, 'FontWeight', 'bold');

function plotCorr(x, y, xL, yL, col)
    % Force column vectors to fix "array bounds" error
    x = x(:); y = y(:); 
    v = ~isnan(x) & ~isnan(y);
    
    if sum(v) < 5; text(0.5,0.5,'Insufficient Data','H','C'); return; end
    
    xc = x(v); yc = y(v);
    scatter(xc, yc, 70, 'filled', 'MarkerFaceColor', col, 'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'k'); hold on;
    
    % Statistics
    [r, p] = corr(xc, yc, 'Type', 'Spearman');
    coeffs = polyfit(xc, yc, 1);
    slope = coeffs(1);
    
    % Labeling Slope and Significance
    sigStr = ' (n.s.)';
    if p < 0.001; sigStr = ' ***'; elseif p < 0.01; sigStr = ' **'; elseif p < 0.05; sigStr = ' *'; end
    
    % Regression Line
    xRange = [min(xc) max(xc)];
    plot(xRange, polyval(coeffs, xRange), 'k-', 'LineWidth', 2);
    
    % Annotations
    statsStr = {sprintf('r = %.3f%s', r, sigStr), ...
                sprintf('p = %.4f', p), ...
                sprintf('\\beta (Slope) = %.4f', slope)};
    
    text(0.05, 0.9, statsStr, 'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'w', 'EdgeColor', col);
    
    xlabel(xL, 'FontWeight', 'bold'); ylabel(yL, 'FontWeight', 'bold'); 
    grid on; box on;
end