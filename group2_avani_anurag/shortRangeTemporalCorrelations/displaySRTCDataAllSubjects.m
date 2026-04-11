% Aggregates and displays SRTC data across all subjects for a given protocol.
% Mimics the functionality and outputs of displayPowerDataAllSubjects.m

function [srtcDataToReturn, topoplotDataToReturn] = displaySRTCDataAllSubjects(subjectNameLists, protocolName, badEyeCondition, badTrialVersion)

    if ~exist('folderSourceString','var');    folderSourceString = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset'; end
    if ~exist('protocolName','var');          protocolName='M1';            end
    if ~exist('badEyeCondition','var');       badEyeCondition='ep';         end
    if ~exist('badTrialVersion','var');       badTrialVersion='v8';         end

    capType = 'actiCap64_UOL';
    x = load([capType '.mat']); 
    montageChanlocs = x.chanlocs;
    numElectrodes = length(montageChanlocs);
    
    numSubjects = length(subjectNameLists);
    allSubjectsTau = NaN(numElectrodes, numSubjects);
    
    %%%%%%%%%%%%%%%%%%%%%% Aggregate Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(['Aggregating SRTC (\tau) data for Protocol: ' protocolName '...']);
    validSubjectCount = 0;
    
    for i = 1:numSubjects
        subjectName = subjectNameLists{i};
        dataFile = fullfile(folderSourceString, 'SRTCsavedData', subjectName, [protocolName '_' badEyeCondition '_' badTrialVersion '_srtc.mat']);
        
        if exist(dataFile, 'file')
            tmpData = load(dataFile);
            if ~isempty(tmpData.tau_srtc)
                allSubjectsTau(:, i) = tmpData.tau_srtc;
                validSubjectCount = validSubjectCount + 1;
            end
        end
    end
    
    % Compute the median across subjects (ignoring NaNs from bad electrodes)
    grandMedianTau = median(allSubjectsTau, 2, 'omitnan'); 
    
    % Data to return to workspace (just like the professor's script)
    srtcDataToReturn = allSubjectsTau;
    topoplotDataToReturn = grandMedianTau;

    %%%%%%%%%%%%%%%%%%%%%% Plot Grand Average %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    hFig = figure('Name', ['Grand Average SRTC: ' protocolName], 'NumberTitle', 'off', 'Color', 'w');
    set(hFig, 'Position', [300, 300, 500, 400]);
    
    % Plot the aggregate topoplot (Auto-scales color to the data range)
    topoplot(grandMedianTau, montageChanlocs, 'electrodes', 'on', 'style', 'map');
    title(sprintf('Grand Median \\tau\nProtocol: %s (N = %d)', protocolName, validSubjectCount), 'FontSize', 14, 'FontWeight', 'bold');
    
    cb = colorbar;
    ylabel(cb, '\tau (milliseconds)', 'FontSize', 12, 'FontWeight', 'bold');
    
    disp('SRTC Display generation complete.');
end