% runSaveSRTCData.m
% Computes Intrinsic Neural Timescales (tau) via Trial-Averaged Autocorrelation
% Follows methodology from Murray (2014) and Golesorkhi (2021)

folderSourceString = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset'; 
goodSubjectList = getGoodSubjectsBK1; 
[allSubjectNames,expDateList] = getDemographicDetails('BK1');

ftDataFolder = fullfile(folderSourceString,'data','ftData'); 

% Create the new dedicated output directory
saveFolderName = fullfile(folderSourceString, 'SRTCsavedData'); 
if ~exist(saveFolderName, 'dir')
    mkdir(saveFolderName);
end

badEyeCondition = 'ep'; 
badTrialVersion = 'v8';

%%%%%%%%%%%%%%%%%%%%%%%% Analysis Parunrameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are using the FULL 2.5 second trial
freqBand = [30 50]; % Low Gamma Band
protocolNameList = [{'EO1'} {'EC1'} {'G1'} {'M1'} {'G2'} {'EO2'} {'EC2'} {'M2'}]; 

useTheseIndices = 1:length(goodSubjectList);
subjectsToProcess = goodSubjectList(useTheseIndices);
numSubjects = length(subjectsToProcess);

%%%%%%%%%%%%%%%%%%%%%%%% Save SRTC data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parfor i = 1:numSubjects
    subjectName = subjectsToProcess{i};
    
    currentTime = datestr(now, 'HH:MM:SS');
    fprintf('[%s] Worker computing SRTC (Tau) for subject %s...\n', currentTime, subjectName);
    
    expDate = expDateList{strcmp(subjectName,allSubjectNames)};
    
    % Call the specialized compute function
    saveSRTCData(subjectName, protocolNameList, badEyeCondition, badTrialVersion, ftDataFolder, saveFolderName, freqBand);
end

disp('All SRTC computations finished successfully!');