function [hfdValsST, hfdValsBL, hurstValsST, hurstValsBL, numTrials] = getDataSingleProtocolHFD_Hurst(subjectName,expDate,protocolName,folderSourceString,stRange,badTrials,kMaxList,freqRangeList)
% =========================================================================
% STANDALONE HFD & HURST EXTRACTION ENGINE (Vectorized & Toolbox-Free)
% Incorporates full signal processing integrity from the Ray Lab pipeline.
% =========================================================================

% --- 1. INITIALIZATION & DIRECTORY SETUP ---
gridType = 'EEG'; 
electrodeList = 1:64;
numElectrodes = length(electrodeList);
numFreqs = length(freqRangeList);

% Locate the segmented data folder
folderSegment = fullfile(folderSourceString,'data','segmentedData',subjectName,gridType,expDate,protocolName,'segmentedData');
timingFile = fullfile(folderSegment,'LFP','lfpInfo.mat');

if exist(timingFile,'file')
    % Load timing and sampling information
    t = load(timingFile);
    timeVals = t.timeVals;
    Fs = round(1/(timeVals(2)-timeVals(1)));
    
    % --- 2. TIMING & PROTOCOL LOGIC ---
    if contains(protocolName, 'EO') || contains(protocolName, 'EC')
        stFlag = 0; blRange = [timeVals(1) timeVals(end)]; stRange = blRange;
    else
        stFlag = 1; blRange = [-diff(stRange) 0];
    end
    
    % Map ranges to specific sample indices
    rangePos = round(diff(blRange)*Fs);
    blPos = find(timeVals>=blRange(1),1) + (1:rangePos);
    stPos = find(timeVals>=stRange(1),1) + (1:rangePos);
    
    % --- 3. FILTER BANK DESIGN (Shrishty Specification) ---
    % Highpass filter (1Hz) to remove DC drift
    dHighpass = designfilt('highpassiir','FilterOrder',8, 'PassbandFrequency',1,'PassbandRipple',0.2,'SampleRate',Fs);
    
    % Bandpass and Harmonic Notch filters for each requested frequency range
    for iF = 1:numFreqs
        bBand{iF} = designfilt('bandpassiir','FilterOrder',4,'PassbandFrequency1',freqRangeList{iF}(1),'PassbandFrequency2',freqRangeList{iF}(2),'PassbandRipple',0.2,'SampleRate',Fs);
        
        iStop = 0;
        for fC = 50:50:250
            if (fC-2 < freqRangeList{iF}(2) && fC+2 > freqRangeList{iF}(1))
                iStop = iStop + 1;
                bNotch{iF}{iStop} = designfilt('bandstopiir','FilterOrder',4,'PassbandFrequency1',fC-2,'PassbandFrequency2',fC+2,'PassbandRipple',0.2,'SampleRate',Fs);
            end
        end
    end
    
    % --- 4. DATA LOADING & TRIAL REJECTION ---
    e_temp = load(fullfile(folderSegment,'LFP','elec1.mat'));
    goodTrials = setdiff(1:size(e_temp.analogData,1), badTrials);
    numTrials = length(goodTrials);
    numTotalSamples = size(e_temp.analogData,2);
    
    hfdValsST = nan(numElectrodes, numFreqs); hfdValsBL = nan(numElectrodes, numFreqs);
    hurstValsST = nan(numElectrodes, numFreqs); hurstValsBL = nan(numElectrodes, numFreqs);
    
    % --- 5. REFERENCING SCHEME (Full Integrity) ---
    refType = 'unipolar'; 
    meanElecData = [];    
    
    if strcmp(refType,'average')
        fprintf('Computing Average Reference for Subject: %s...\n', subjectName);
        allData = zeros(numElectrodes, length(goodTrials), numTotalSamples);
        for iElec = 1:numElectrodes
            tempE = load(fullfile(folderSegment,'LFP',['elec' num2str(iElec) '.mat']));
            allData(iElec, :, :) = tempE.analogData(goodTrials, :);
        end
        meanElecData = squeeze(nanmean(allData, 1))'; % [Time x Trials]
        clear allData;
    end
    
    % --- 6. MAIN ELECTRODE PROCESSING LOOP ---
    if numTrials > 0
        for iE = 1:numElectrodes
            elecFile = fullfile(folderSegment,'LFP',['elec' num2str(iE) '.mat']);
            e = load(elecFile);
            
            rawEEG = e.analogData(goodTrials, :)'; 
            
            % Apply Referencing
            if strcmp(refType,'average') && ~isempty(meanElecData)
                rawEEG = rawEEG - meanElecData;
            end
            
            % Apply Broadband Highpass
            rawEEG = filtfilt(dHighpass, rawEEG);
            
            for iF = 1:numFreqs
                % Select Dynamic kMax for this specific frequency band
                currentKMax = kMaxList(iF);
                
                % Apply Bandpass
                filtEEG = filtfilt(bBand{iF}, rawEEG);
                
                % Apply Notches
                if exist('bNotch','var') && iF <= length(bNotch) && ~isempty(bNotch{iF})
                    for n = 1:length(bNotch{iF})
                        filtEEG = filtfilt(bNotch{iF}{n}, filtEEG);
                    end
                end
                
                tHFD_BL = nan(1, numTrials); tHurst_BL = nan(1, numTrials);
                tHFD_ST = nan(1, numTrials); tHurst_ST = nan(1, numTrials);
                
                % --- 7. TRIAL-BY-TRIAL CALCULATION ---
                for iT = 1:numTrials
                    % Baseline
                    blSeg = filtEEG(blPos, iT);
                    tHFD_BL(iT) = calculateHFD_Internal(blSeg, currentKMax);
                    tHurst_BL(iT) = genhurst(blSeg);
                    
                    % Stimulus
                    if stFlag
                        stSeg = filtEEG(stPos, iT);
                        tHFD_ST(iT) = calculateHFD_Internal(stSeg, currentKMax);
                        tHurst_ST(iT) = genhurst(stSeg);
                    end
                end
                
                % Average across trials
                hfdValsBL(iE, iF)   = nanmean(tHFD_BL);
                hurstValsBL(iE, iF) = nanmean(tHurst_BL);
                if stFlag
                    hfdValsST(iE, iF)   = nanmean(tHFD_ST);
                    hurstValsST(iE, iF) = nanmean(tHurst_ST);
                end
            end
            
            clear e rawEEG filtEEG tHFD_BL tHurst_BL tHFD_ST tHurst_ST;
        end
    else
        fprintf('Subject %s has no good trials. Returning NaNs.\n', subjectName);
    end
else
    fprintf('CRITICAL ERROR: Timing file %s not found.\n', timingFile);
    hfdValsST = []; hfdValsBL = []; hurstValsST = []; hurstValsBL = []; numTrials = 0;
end
end

% =========================================================================
% LOCAL FUNCTIONS 
% =========================================================================

function hfd = calculateHFD_Internal(data, kMax)
    % Internal, toolbox-free implementation of Higuchi's algorithm.
    N = length(data);
    L = zeros(1, kMax);
    
    for k = 1:kMax
        Lk = zeros(1, k);
        for m = 1:k
            n_max = floor((N - m) / k);
            indices = m:k:(m + n_max * k);
            sum_diff = sum(abs(diff(data(indices))));
            norm_factor = (N - 1) / (n_max * k);
            Lk(m) = (sum_diff * norm_factor) / k;
        end
        L(k) = mean(Lk);
    end
    
    x_log = log(1 ./ (1:kMax));
    y_log = log(L);
    
    % Core MATLAB polyfit (bypasses Curve Fitting Toolbox error)
    coeffs = polyfit(x_log, y_log, 1);
    hfd = coeffs(1);       
end