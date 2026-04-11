% Loops through subjects to display and save SRTC (Tau) data.
% Mirrors the functionality of runDisplayPowerDataSingleSubject.m

clear;
[allSubjectNames,expDateList] = getDemographicDetails('BK1');
[goodSubjectList, meditatorList, controlList] = getGoodSubjectsBK1;

folderSourceString = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/meditationDataset';
saveFolderName = 'srtcResultsSingleSubject';

saveFileFlag     = 1;

badEyeCondition = 'ep'; % use 'wo' for without, 'ep' for eye position
badTrialVersion = 'v8';

useTheseIndices = 1:length(goodSubjectList);

for i=1:length(useTheseIndices)
    fh=figure(1); clf(fh);
    fh.WindowState = 'maximized';
    
    subjectName = goodSubjectList{useTheseIndices(i)};
    disp(['Analyzing SRTC for the subject ' subjectName]);
    
    % Call the SRTC single-subject display script
    displaySRTCDataSingleSubject(subjectName, folderSourceString, badEyeCondition, badTrialVersion);
    
    % Save the figure
    if saveFileFlag
        if ~exist(saveFolderName, 'dir')
            mkdir(saveFolderName);
        end
        badTrialNameStr = ['_' badEyeCondition '_' badTrialVersion];
        fileNameTif = fullfile(saveFolderName,[subjectName badTrialNameStr '_srtc_topoplots.tif']);
        print(fh,fileNameTif,'-dtiff','-r100');
    end
end
disp('Finished saving all single-subject SRTC figures!');