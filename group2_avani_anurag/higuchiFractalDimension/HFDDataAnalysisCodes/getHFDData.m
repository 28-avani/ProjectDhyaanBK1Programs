function [hfdValsST, hfdValsBL, hurstValsST, hurstValsBL, numTrials, badElectrodes] = getHFDData(subjectName,expDate,protocolNameList,folderSourceString,badEyeCondition,badTrialVersion,stRange,kMaxList,freqRangeList)

numProtocols = length(protocolNameList);
hfdValsST = cell(1,numProtocols); hfdValsBL = cell(1,numProtocols);
hurstValsST = cell(1,numProtocols); hurstValsBL = cell(1,numProtocols);
numTrials = zeros(1,numProtocols); badElectrodes = cell(1,numProtocols);

for i=1:numProtocols
    protocolName = protocolNameList{i};
    
    % --- RESTORED & ENHANCED CONSOLE UPDATE ---
    fprintf('   -> Extracting Protocol: %s (%d of %d)...\n', protocolName, i, numProtocols);
    
    [badTrials,badElectrodes{i}] = getBadTrialsAndElectrodes(subjectName,expDate,protocolName,folderSourceString,badEyeCondition,badTrialVersion);
    
    [hfdValsST{i}, hfdValsBL{i}, hurstValsST{i}, hurstValsBL{i}, numTrials(i)] = getDataSingleProtocolHFD_Hurst(subjectName,expDate,protocolName,folderSourceString,stRange,badTrials,kMaxList,freqRangeList);
end

end