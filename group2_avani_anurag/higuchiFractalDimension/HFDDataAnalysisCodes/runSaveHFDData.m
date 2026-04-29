% runSaveHFDData.m
folderSourceString = "/Users/anuragsarkar/Desktop/NSPCourse"; 
saveFolderName = fullfile(folderSourceString, 'HFDData'); 
if ~exist(saveFolderName, 'dir'); mkdir(saveFolderName); end

% Load Subjects
[~, meditatorList, controlList] = getGoodSubjectsBK1; 
goodSubjectList = [meditatorList; controlList]; 
badEyeCondition = 'ep'; 
badTrialVersion = 'v8'; 
stRange = [0.25 1.25];   

% Shut down any existing pools first to be safe
delete(gcp('nocreate')); 

% Start a new thread-based pool
parpool('Processes');


centerFreqs = 50:20:180; % Centers from 50Hz to 290Hz
windowWidth = 100;
numWindows = length(centerFreqs);

freqRangeList = cell(1, numWindows);
kMaxList = zeros(1, numWindows);

for w = 1:numWindows
    fMin = max(1, centerFreqs(w) - (windowWidth / 2)); 
    fMax = centerFreqs(w) + (windowWidth / 2);
    freqRangeList{w} = [fMin, fMax];
    
    
    kMaxList(w) = 5; 
end
% =========================================================================

protocolNameList = {'EO1', 'EC1', 'G1', 'M1', 'G2', 'M2'}; 

parfor i = 1:length(goodSubjectList)
    subjectName = goodSubjectList{i};
    fprintf('\n--------------------------------------------------\n');
    fprintf('PROCESSING HFD: %s (%d of %d)\n', subjectName, i, length(goodSubjectList));
    fprintf('--------------------------------------------------\n');
    
    % NOTE: You might want to change the saveFileName slightly so it doesn't 
    % overwrite your original 4-band data! (Added '_Sliding')
    saveFileName = fullfile(saveFolderName, [subjectName '_' badEyeCondition '_' badTrialVersion '_' num2str(1000*stRange(1)) '_' num2str(1000*stRange(2)) '_Sliding.mat']);
    
    if exist(saveFileName, 'file')
        fprintf('Subject %s already exists. Skipping...\n', subjectName);
        continue;
    end
    
    subjectPath = fullfile(folderSourceString, 'data', 'segmentedData', subjectName, 'EEG');
    d = dir(subjectPath); d = d(~ismember({d.name}, {'.', '..', '.DS_Store'}));
    if isempty(d); fprintf('No EEG data found.\n'); continue; end
    expDate = d(1).name; 
    
    try
        % The extraction engine will automatically adapt to the 13 windows
        [hfdValsST, hfdValsBL, hurstValsST, hurstValsBL, numTrials, badElectrodes] = getHFDData(subjectName, expDate, protocolNameList, folderSourceString, badEyeCondition, badTrialVersion, stRange, kMaxList, freqRangeList);
        save(saveFileName, 'hfdValsST', 'hfdValsBL', 'hurstValsST', 'hurstValsBL', 'numTrials', 'badElectrodes', 'stRange', 'freqRangeList', 'kMaxList');
        fprintf('SUCCESS: Saved %s\n', subjectName);
    catch ME
        fprintf('FAILED: %s - %s\n', subjectName, ME.message);
    end
    clear hfdValsST hfdValsBL hurstValsST hurstValsBL badElectrodes;
end
disp('Batch Analysis Complete.');