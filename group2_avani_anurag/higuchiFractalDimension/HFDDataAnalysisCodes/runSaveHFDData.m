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

% Dynamic kMax based on frequency band
freqRangeList{1} = [1 90];   kMaxList(1) = 10; % Broadband
freqRangeList{2} = [8 13];   kMaxList(2) = 5;  % Alpha
freqRangeList{3} = [24 34];  kMaxList(3) = 5;  % Slow Gamma
freqRangeList{4} = [35 65];  kMaxList(4) = 5;  % Fast Gamma

protocolNameList = {'EO1', 'EC1', 'G1', 'M1', 'G2', 'M2'}; 

for i = 1:length(goodSubjectList)
    subjectName = goodSubjectList{i};
    fprintf('\n--------------------------------------------------\n');
    fprintf('PROCESSING: %s (%d of %d)\n', subjectName, i, length(goodSubjectList));
    fprintf('--------------------------------------------------\n');
    
    saveFileName = fullfile(saveFolderName, [subjectName '_' badEyeCondition '_' badTrialVersion '_' num2str(1000*stRange(1)) '_' num2str(1000*stRange(2)) '.mat']);
    if exist(saveFileName, 'file')
        fprintf('Subject %s already exists. Skipping...\n', subjectName);
        continue;
    end
    
    subjectPath = fullfile(folderSourceString, 'data', 'segmentedData', subjectName, 'EEG');
    d = dir(subjectPath); d = d(~ismember({d.name}, {'.', '..', '.DS_Store'}));
    if isempty(d); fprintf('No EEG data found.\n'); continue; end
    expDate = d(1).name; 
    
    try
        [hfdValsST, hfdValsBL, hurstValsST, hurstValsBL, numTrials, badElectrodes] = getHFDData(subjectName, expDate, protocolNameList, folderSourceString, badEyeCondition, badTrialVersion, stRange, kMaxList, freqRangeList);
        save(saveFileName, 'hfdValsST', 'hfdValsBL', 'hurstValsST', 'hurstValsBL', 'numTrials', 'badElectrodes', 'stRange', 'freqRangeList', 'kMaxList');
        fprintf('SUCCESS: Saved %s\n', subjectName);
    catch ME
        fprintf('FAILED: %s - %s\n', subjectName, ME.message);
    end
    clear hfdValsST hfdValsBL hurstValsST hurstValsBL badElectrodes;
end
disp('Batch Analysis Complete.');