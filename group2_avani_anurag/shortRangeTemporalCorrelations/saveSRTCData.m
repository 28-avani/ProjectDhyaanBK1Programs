function saveSRTCData(subjectName, protocolNameList, badEyeCondition, badTrialVersion, ftDataFolder, saveFolderName, freqBand)
    numProtocols = length(protocolNameList);
    for i=1:numProtocols
        protocolName = protocolNameList{i};
        saveSRTCSingleProtocol(subjectName, protocolName, badEyeCondition, badTrialVersion, ftDataFolder, saveFolderName, freqBand);
    end
end

function saveSRTCSingleProtocol(subjectName, protocolName, badEyeCondition, badTrialVersion, ftDataFolder, saveFolderName, freqBand)
    
    % Set up save directories
    outFolder = fullfile(saveFolderName, subjectName);
    if ~exist(outFolder, 'dir'); mkdir(outFolder); end
    
    analysisDetailsFileSRTC = fullfile(outFolder, [protocolName '_' badEyeCondition '_' badTrialVersion '_srtc.mat']);
    
    % Load the pre-cleaned Fieldtrip data
    ftDataFileName = fullfile(ftDataFolder, subjectName, [protocolName '_' badEyeCondition '_' badTrialVersion '.mat']);
    if ~exist(ftDataFileName, 'file')
        return; 
    end
    
    tmpData = load(ftDataFileName);
    numGoodTrials = tmpData.numGoodTrials;
    
    if numGoodTrials > 0    
        data = tmpData.data;

        
        % 1. Extract Amplitude Envelope (Hilbert Transform)
        cfg          = [];
        cfg.bpfilter = 'yes';
        cfg.bpfreq   = freqBand;
        cfg.hilbert  = 'abs'; % Extracts the amplitude envelope
        cfg.feedback = 'none';
        env_data = ft_preprocessing(cfg, data);
        
        %We use the full 2.5s continuous epoch.
        
        numChannels = length(env_data.label);
        tau_srtc = NaN(numChannels, 1);
        badElecs = data.badElecs;
        
        % 2. Autocorrelation Parameters
        fs = data.fsample;
        max_lag_ms = 500; % Safe max lag (20% of the 2.5s window)
        max_lag_samples = round((max_lag_ms / 1000) * fs);
        lags_ms = (0:max_lag_samples)' * (1000 / fs); % X-axis for curve fitting
        
        % Options for the exponential curve fitter
        fitOptions = optimset('Display', 'off'); 
        
        % 3. Run Trial-Averaged Autocorrelation
        for c = 1:numChannels
            if ismember(c, badElecs)
                continue; % Leave as NaN if it's a bad electrode
            end
            
            acf_sum = zeros(max_lag_samples + 1, 1);
            
            % Calculate ACF for every trial independently
            for t = 1:numGoodTrials
                sig = env_data.trial{t}(c, :);
                
                % xcorr with 'coeff' normalizes the ACF so lag 0 is exactly 1.0
                [acf_trial, lags] = xcorr(sig - mean(sig), max_lag_samples, 'coeff');
                
                % We only want the positive lags (from 0 to max_lag)
                acf_pos = acf_trial(lags >= 0);
                acf_sum = acf_sum + acf_pos(:);
            end
            
            % Average the ACF curves across all trials
            acf_avg = acf_sum / numGoodTrials;
            
            % 4. Fit the Exponential Decay Equation: R(k) = A*exp(-k/tau) + B
            % Initial guess: A = 1, tau = 50ms, B = 0
            initial_guess = [1, 50, 0]; 
            
            % Objective function to minimize (Least Squares Error)
            objFun = @(p) sum(( (p(1) * exp(-lags_ms / p(2)) + p(3)) - acf_avg ).^2);
            
            % Run the optimizer
            best_params = fminsearch(objFun, initial_guess, fitOptions);
            
            % Extract Tau (the 2nd parameter)
            tau_extracted = best_params(2);
            
            % Quality control: reject physically impossible taus (negative or longer than epoch)
            if tau_extracted > 0 && tau_extracted < 2500
                tau_srtc(c) = tau_extracted;
            else
                tau_srtc(c) = NaN;
            end
        end
        
    else
        tau_srtc = []; freqBand = [];
    end
    
    % Save the final tau exponent vector (values are in milliseconds)
    save(analysisDetailsFileSRTC, 'tau_srtc', 'numGoodTrials', 'freqBand');
end