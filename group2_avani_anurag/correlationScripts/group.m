% =========================================================================
% Group-Level Multimodal Hub Correlation: Meditators (Protocol M1)
% Correlating SRTC, FC, FOOOF, HFD, and Gamma PSD Hubs
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

% Protocol and Frequency Setup
prot = 'M1'; eye = 'ep'; ver = 'v8';
fRange = [30 50]; 

% Load Subject List
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'meditatorList');
subList = meditatorList;
nSubj = length(subList);

% Storage for 64-electrode maps per subject (Subjects x 5 Metrics x 64 Elecs)
allMaps = nan(nSubj, 5, 64); 

%% 2. Extraction Loop
fprintf('Starting Group Extraction for %d Meditators...\n', nSubj);

for i = 1:nSubj
    subj = subList{i};
    fprintf('Processing [%d/%d]: %s... ', i, nSubj, subj);
    
    % --- A. SRTC & Protocol Index Finder ---
    sFile = fullfile(srtcFolder, subj, [prot '_' eye '_' ver '_srtc.mat']);
    if exist(sFile, 'file')
        tmp = load(sFile);
        allMaps(i, 1, :) = tmp.tau_srtc(:);
        if isfield(tmp, 'allProtocols'); pIdx = find(strcmp(tmp.allProtocols, prot)); else; pIdx = 4; end
    else
        fprintf('SRTC Missing. '); continue;
    end

    % --- B. Connectivity (PPC) ---
    cFile = fullfile(connFolder, subj, [prot '_' eye '_' ver '_ppc.mat']);
    if exist(cFile, 'file')
        tmp = load(cFile);
        fIdx = find(tmp.freqPost >= fRange(1) & tmp.freqPost <= fRange(2));
        if ~isempty(fIdx)
            fc = squeeze(mean(mean(tmp.connPost(:,:,fIdx), 3, 'omitnan'), 1, 'omitnan'));
            allMaps(i, 2, :) = fc(:);
        end
    end

    % --- C. FOOOF (Aperiodic Exponent) ---
    fDir = dir(fullfile(fooofFolder, [subj '*FOOOF.mat']));
    if ~isempty(fDir)
        tmp = load(fullfile(fooofFolder, fDir(1).name));
        if isfield(tmp, 'exponentST') && length(tmp.exponentST) >= pIdx
            allMaps(i, 3, :) = mean(tmp.exponentST{pIdx}, 2, 'omitnan');
        end
    end

    % --- D. HFD (Fractal Dimension) ---
    hDir = dir(fullfile(hfdFolder, [subj '*.mat']));
    if ~isempty(hDir)
        tmp = load(fullfile(hfdFolder, hDir(1).name));
        if isfield(tmp, 'hfdValsST') && length(tmp.hfdValsST) >= pIdx
            allMaps(i, 4, :) = mean(tmp.hfdValsST{pIdx}, 2, 'omitnan');
        end
    end

    % --- E. PSD (Gamma Power) ---
    pFileName = fullfile(psdFolder, [subj '_' eye '_' ver '_250_1250.mat']);
    if exist(pFileName, 'file')
        tmp = load(pFileName);
        fIdx = find(tmp.freqVals >= fRange(1) & tmp.freqVals <= fRange(2));
        if ~isempty(fIdx) && length(tmp.psdValsST) >= pIdx
            psd = log10(sum(tmp.psdValsST{pIdx}(:, fIdx), 2, 'omitnan'));
            allMaps(i, 5, :) = psd(:);
        end
    end
    fprintf('Done.\n');
end

%% 3. Calculate Group Average Topographies
% We average across subjects to get one 64-electrode map per metric
avgMaps = squeeze(nanmean(allMaps, 1)); 

%% 4. Spatial Hub Correlation Visualization
figure('Name', 'Group-Level Multimodal Hub Correlations', 'Color', 'w', 'Position', [100 100 1200 900]);

metrics = {'SRTC (\tau)', 'Functional Conn', 'FOOOF Exp', 'Higuchi FD', 'Gamma Power'};
colors = {[0.2 0.7 0.2], [1 0.5 0], [0 0.4 1], [0.7 0.2 0.6]};

for m = 2:5
    subplot(2,2,m-1);
    
    x = squeeze(avgMaps(1, :))'; % SRTC Hubs
    y = squeeze(avgMaps(m, :))'; % Target Hubs
    
    v = ~isnan(x) & ~isnan(y);
    xc = x(v); yc = y(v);
    
    % Scatter
    scatter(xc, yc, 80, 'filled', 'MarkerFaceColor', colors{m-1}, 'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'k');
    hold on;
    
    % Statistics
    [r, p] = corr(xc, yc, 'Type', 'Spearman');
    coeffs = polyfit(xc, yc, 1);
    slope = coeffs(1);
    
    % Significance Stars
    sig = ' (n.s.)';
    if p < 0.001; sig = ' ***'; elseif p < 0.01; sig = ' **'; elseif p < 0.05; sig = ' *'; end
    
    % Regression
    plot(xlim, polyval(coeffs, xlim), 'k-', 'LineWidth', 2);
    
    % Labels
    statsText = {sprintf('r = %.3f%s', r, sig), ...
                 sprintf('p = %.4f', p), ...
                 sprintf('\\beta (Slope) = %.4f', slope)};
    text(0.05, 0.85, statsText, 'Units', 'normalized', 'FontSize', 11, 'BackgroundColor', 'w', 'EdgeColor', colors{m-1});
    
    xlabel(metrics{1}, 'FontWeight', 'bold'); ylabel(metrics{m}, 'FontWeight', 'bold');
    title(['Hub Overlap: ' metrics{1} ' vs ' metrics{m}]);
    grid on; box on;
end

sgtitle(['Meditator Group: Multimodal Spatial Hub Correlations (N = ' num2str(nSubj) ')'], 'FontSize', 18, 'FontWeight', 'bold');