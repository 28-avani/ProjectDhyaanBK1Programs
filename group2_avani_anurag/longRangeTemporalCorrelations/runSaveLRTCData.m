% runSaveLRTCData
% Computes LRTC (DFA exponent) based on Pascarella (2025) & Hardstone (2012)

folderSourceString = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset'; 
goodSubjectList = getGoodSubjectsBK1; 
[allSubjectNames,expDateList] = getDemographicDetails('BK1');

ftDataFolder = fullfile(folderSourceString,'data','ftData'); 
saveFolderName = fullfile(folderSourceString, 'LRTCSavedData'); % Save local project directory
makeDirectory(saveFolderName);

badEyeCondition = 'ep'; 
badTrialVersion = 'v8';

%%%%%%%%%%%%%%%%%%%%%%%% Analysis Parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stRange = [0.25 1.25];
freqBand = [20 70]; % Gamma Band
protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M1'} {'G2'} {'EO2'} {'EC2'} {'M2'}]; 

useTheseIndices = 1:length(goodSubjectList);
subjectsToProcess = goodSubjectList(useTheseIndices);
numSubjects = length(subjectsToProcess);

%%%%%%%%%%%%%%%%%%%%%%%% Save LRTC data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parfor i = 1:numSubjects
    subjectName = subjectsToProcess{i};
    
    % Clean progress tracker
    currentTime = datestr(now, 'HH:MM:SS');
    fprintf('[%s] Worker computing LRTC for subject %s...\n', currentTime, subjectName);
    
    expDate = expDateList{strcmp(subjectName,allSubjectNames)};
    
    % Call the specialized saving function
    saveLRTCData(subjectName, protocolNameList, badEyeCondition, badTrialVersion, ftDataFolder, saveFolderName, stRange, freqBand);
end