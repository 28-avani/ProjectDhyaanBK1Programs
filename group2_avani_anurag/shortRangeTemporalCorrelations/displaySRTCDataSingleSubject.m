% Displays SRTC (Intrinsic Neural Timescale / Tau) data for a single subject.
% Features Global Auto-Scaling to ensure Min = Blue and Max = Red across all plots.

function displaySRTCDataSingleSubject(subjectName, folderSourceString, badEyeCondition, badTrialVersion)

    if ~exist('folderSourceString','var');    folderSourceString = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset'; end
    if ~exist('badEyeCondition','var');       badEyeCondition='ep';         end
    if ~exist('badTrialVersion','var');       badTrialVersion='v8';         end

    capType = 'actiCap64_UOL';
    protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M1'} {'G2'} {'EO2'} {'EC2'} {'M2'}];
    numProtocols = length(protocolNameList);
    
    savedDataFolder = fullfile(folderSourceString, 'SRTCsavedData', subjectName);
    x = load([capType '.mat']); 
    montageChanlocs = x.chanlocs;

    % --- NEW: Step 1. Scan all 8 protocols to find the Global Min and Max ---
    globalMin = Inf;
    globalMax = -Inf;
    loadedData = cell(numProtocols, 1);
    
    for p = 1:numProtocols
        dataFile = fullfile(savedDataFolder, [protocolNameList{p} '_' badEyeCondition '_' badTrialVersion '_srtc.mat']);
        if exist(dataFile, 'file')
            tmpData = load(dataFile);
            loadedData{p} = tmpData;
            
            % Find min/max ignoring the NaNs from bad electrodes
            currentMin = min(tmpData.tau_srtc, [], 'omitnan');
            currentMax = max(tmpData.tau_srtc, [], 'omitnan');
            
            if currentMin < globalMin; globalMin = currentMin; end
            if currentMax > globalMax; globalMax = currentMax; end
        end
    end
    
    % Fallback just in case there is completely zero data
    if isinf(globalMin); colorLimits = [20 120]; else; colorLimits = [globalMin globalMax]; end

    % --- Step 2. Generate the UI and Plot with Global Limits ---
    hFig = figure('Name', ['SRTC (\tau) for Subject: ' subjectName], 'NumberTitle', 'off', 'Color', 'w');
    set(hFig, 'Position', [100, 100, 1200, 600]); 
    colormap('jet'); % Forces the Blue -> Red spectrum

    for p = 1:numProtocols
        subplot(2, 4, p);
        if ~isempty(loadedData{p})
            tmpData = loadedData{p};
            tau_vals = tmpData.tau_srtc;
            
            % Plot using the perfectly scaled dynamic limits
            topoplot(tau_vals, montageChanlocs, 'maplimits', colorLimits, 'electrodes', 'on', 'style', 'map');
            title(sprintf('%s (n=%d)', protocolNameList{p}, tmpData.numGoodTrials), 'FontSize', 12, 'FontWeight', 'bold');
        else
            title(sprintf('%s (No Data)', protocolNameList{p}), 'FontSize', 12, 'Color', [0.5 0.5 0.5]);
            axis off;
        end
    end
    
% Add Colorbar (using safe, absolute figure coordinates)
    cb = colorbar('Position', [0.93  0.15  0.015  0.7]); 
    ylabel(cb, '\tau (milliseconds)', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Add Title
    annotation('textbox', [0 0.9 1 0.1], 'String', ['Gamma Band Intrinsic Neural Timescales (\tau) - Subject: ' subjectName], ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');
end