% =========================================================================
% Spatial Correlation: Intrinsic Timescale (tau) vs. Global Connectivity (PPC)
% =========================================================================

clear; clc;

%% 1. Define Paths and Parameters
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
srtcFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');
connFolder = fullfile(basePath, 'meditationDataset', 'data', 'ftData', 'connSavedData');

% Analysis Parameters
protocol = 'M1';
eyeCond = 'ep';
trialVer = 'v8';
freqRange = [30 50]; % Gamma band matching your SRTC data
numElectrodes = 64;

% Load Metadata
load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'meditatorList', 'controlList');
capData = load('actiCap64_UOL.mat'); chanlocs = capData.chanlocs;

% Use Good Subjects only (using your lab's convention)
try
    goodSubjects = getGoodSubjectsBK1();
    medList = intersect(meditatorList, goodSubjects, 'stable');
    ctrlList = intersect(controlList, goodSubjects, 'stable');
catch
    medList = meditatorList; ctrlList = controlList;
end

%% 2. Data Extraction Function
% Helper to pull both Tau and PPC for a list of subjects
function [grpTau, grpConn] = extractPairedData(subList, prot, eye, ver, sFolder, cFolder, fRange, nElec)
    nSubj = length(subList);
    grpTau = nan(nSubj, nElec);
    grpConn = nan(nSubj, nElec);
    
    for i = 1:nSubj
        subj = subList{i};
        
        % A. Load SRTC
        sFile = fullfile(sFolder, subj, [prot '_' eye '_' ver '_srtc.mat']);
        tauValid = false;
        if exist(sFile, 'file')
            sData = load(sFile);
            if isfield(sData, 'tau_srtc') && ~isempty(sData.tau_srtc)
                grpTau(i, :) = sData.tau_srtc;
                tauValid = true;
            end
        end
        
        % B. Load Connectivity (PPC)
        cFile = fullfile(cFolder, subj, [prot '_' eye '_' ver '_ppc.mat']);
        if tauValid && exist(cFile, 'file')
            cData = load(cFile);
            
            % Find frequency indices for 30-50 Hz
            freqIdx = find(cData.freqPost >= fRange(1) & cData.freqPost <= fRange(2));
            
            if isfield(cData, 'connPost') && ~isempty(freqIdx)
                % connPost is typically [Elec x Elec x Freq]
                % 1. Average across the frequency band
                bandConn = squeeze(mean(cData.connPost(:, :, freqIdx), 3, 'omitnan'));
                
                % 2. Calculate Global Node Strength (Average connectivity to all other electrodes)
                nodeStrength = squeeze(mean(bandConn, 1, 'omitnan')); 
                grpConn(i, :) = nodeStrength;
            end
        end
    end
end

disp('Extracting and merging SRTC and Connectivity Data...');
[medTau, medConn] = extractPairedData(medList, protocol, eyeCond, trialVer, srtcFolder, connFolder, freqRange, numElectrodes);
[ctrlTau, ctrlConn] = extractPairedData(ctrlList, protocol, eyeCond, trialVer, srtcFolder, connFolder, freqRange, numElectrodes);

%% 3. Calculate Group Spatial Averages
% We want the average Tau and average Conn for each electrode across the group
avgMedTau  = squeeze(nanmean(medTau, 1))';
avgMedConn = squeeze(nanmean(medConn, 1))';

avgCtrlTau  = squeeze(nanmean(ctrlTau, 1))';
avgCtrlConn = squeeze(nanmean(ctrlConn, 1))';

% Remove electrodes that are entirely NaN in either metric
validMed = ~isnan(avgMedTau) & ~isnan(avgMedConn);
validCtrl = ~isnan(avgCtrlTau) & ~isnan(avgCtrlConn);

%% 4. Statistical Correlation
[rMed, pMed] = corr(avgMedConn(validMed), avgMedTau(validMed), 'Type', 'Spearman');
[rCtrl, pCtrl] = corr(avgCtrlConn(validCtrl), avgCtrlTau(validCtrl), 'Type', 'Spearman');

%% 5. Visualization Setup
figure('Name', 'Spatial Network Hubs: SRTC vs. Connectivity', 'Color', 'w', 'Position', [50 50 1200 800]);
colormap('jet');

% --- Scatter Plots (Node vs Node) ---
function plotScatter(ax, xData, yData, rVal, pVal, groupName, dotColor)
    axes(ax); hold on;
    scatter(xData, yData, 70, 'filled', 'MarkerFaceColor', dotColor, 'MarkerFaceAlpha', 0.7);
    
    % Trendline
    coeffs = polyfit(xData, yData, 1);
    xFit = linspace(min(xData), max(xData), 100);
    plot(xFit, polyval(coeffs, xFit), 'k--', 'LineWidth', 1.5);
    
    xlabel('Global Connectivity (PPC Node Strength)', 'FontWeight', 'bold');
    ylabel('Intrinsic Timescale \tau (ms)', 'FontWeight', 'bold');
    title([groupName, ' (SRTC vs. FC)']);
    
    % Stats Text
    sigTxt = sprintf('r = %.3f\np = %.4f', rVal, pVal);
    text(min(xData) + 0.05*(max(xData)-min(xData)), max(yData)*0.95, sigTxt, ...
        'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');
    grid on;
end

subplot(2, 2, 1); plotScatter(gca, avgMedConn(validMed), avgMedTau(validMed), rMed, pMed, 'Meditators', [0.8 0.2 0.2]);
subplot(2, 2, 2); plotScatter(gca, avgCtrlConn(validCtrl), avgCtrlTau(validCtrl), rCtrl, pCtrl, 'Controls', [0.2 0.2 0.8]);

% --- Topoplot Comparison for Meditators (Visualizing the Hubs) ---
subplot(2, 2, 3);
topoplot(avgMedConn, chanlocs, 'maplimits', 'maxmin', 'electrodes', 'on');
title('Meditators: High Connectivity Hubs (PPC)'); colorbar;

subplot(2, 2, 4);
topoplot(avgMedTau, chanlocs, 'maplimits', 'maxmin', 'electrodes', 'on');
title('Meditators: Long Timescale Regions (\tau)'); colorbar;

annotation('textbox', [0 0.93 1 0.05], 'String', 'Are long-timescale regions also network hubs?', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 15, 'FontWeight', 'bold');