function saveLRTCData(subjectName, protocolNameList, badEyeCondition, badTrialVersion, ftDataFolder, saveFolderName, stRange, freqBand)
    
    numProtocols = length(protocolNameList);
    for i=1:numProtocols
        protocolName = protocolNameList{i};
        saveLRTCSingleProtocol(subjectName, protocolName, badEyeCondition, badTrialVersion, ftDataFolder, saveFolderName, stRange, freqBand);
    end
end

function saveLRTCSingleProtocol(subjectName, protocolName, badEyeCondition, badTrialVersion, ftDataFolder, saveFolderName, stRange, freqBand)
    
    % Set up save directories
    outFolder = fullfile(saveFolderName, subjectName);
    if ~exist(outFolder, 'dir'); mkdir(outFolder); end
    
    analysisDetailsFileLRTC = fullfile(outFolder, [protocolName '_' badEyeCondition '_' badTrialVersion '_lrtc.mat']);
    
    % Load the pre-cleaned Fieldtrip data
    ftDataFileName = fullfile(ftDataFolder, subjectName, [protocolName '_' badEyeCondition '_' badTrialVersion '.mat']);
    if ~exist(ftDataFileName, 'file')
        return; % Skip if ftData doesn't exist for this protocol
    end
    
    tmpData = load(ftDataFileName);
    numGoodTrials = tmpData.numGoodTrials;
    
    if numGoodTrials > 0    
        data = tmpData.data;
        
        % Mute FieldTrip
        ft_warning('off', 'all');
        ft_notice('off', 'all');
        ft_info('off', 'all');
        
        % 1. Extract Amplitude Envelope (Hilbert Transform)
        cfg          = [];
        cfg.bpfilter = 'yes';
        cfg.bpfreq   = freqBand;
        cfg.hilbert  = 'abs'; % Extracts the envelope
        cfg.feedback = 'none';
        env_data = ft_preprocessing(cfg, data);
        
        % 2. Isolate the specific time window (stRange)
        cfg          = [];
        cfg.toilim   = stRange; 
        cfg.feedback = 'none';
        env_data_cropped = ft_redefinetrial(cfg, env_data);
        
        % 3. Calculate DFA parameters
        numChannels = length(env_data_cropped.label);
        alpha_lrtc = NaN(numChannels, 1);
        badElecs = data.badElecs;
        
        % Define DFA Window Sizes (n)
        % Hardstone recommends min window = 2 cycles of lowest freq
        min_win = round(data.fsample / freqBand(1) * 2); 
        max_win = floor(length(env_data_cropped.time{1}) / 4); % Max 25% of trial length
        window_sizes = unique(floor(logspace(log10(min_win), log10(max_win), 15)));
        
        % 4. Run Trial-Averaged DFA for each channel
        for c = 1:numChannels
            if ismember(c, badElecs)
                continue; % Leave as NaN if it's a bad electrode
            end
            
            F2_n_sum = zeros(length(window_sizes), 1);
            
            for t = 1:numGoodTrials
                % Get signal for this trial and channel
                sig = env_data_cropped.trial{t}(c, :);
                
                % Integrate the mean-centered signal
                y = cumsum(sig - mean(sig));
                
                F2_n_trial = zeros(length(window_sizes), 1);
                for w = 1:length(window_sizes)
                    n = window_sizes(w);
                    num_windows = floor(length(y) / n);
                    if num_windows == 0; continue; end
                    
                    y_trunc = y(1:num_windows*n);
                    y_matrix = reshape(y_trunc, n, num_windows);
                    x = (1:n)';
                    
                    rms_fluct = zeros(num_windows, 1);
                    for k = 1:num_windows
                        window_data = y_matrix(:, k);
                        p_fit = polyfit(x, window_data, 1); % Linear detrend
                        trend = polyval(p_fit, x);
                        detrended = window_data - trend;
                        rms_fluct(k) = mean(detrended.^2);
                    end
                    F2_n_trial(w) = mean(rms_fluct); % Variance for window n
                end
                F2_n_sum = F2_n_sum + F2_n_trial; % Accumulate across trials
            end
            
            % Average F^2(n) across trials, then take square root to get F(n)
            F_n = sqrt(F2_n_sum / numGoodTrials);
            
            % Calculate DFA Exponent (alpha) via log-log fit
            log_n = log10(window_sizes(:));
            log_F = log10(F_n);
            coeffs = polyfit(log_n, log_F, 1);
            alpha_lrtc(c) = coeffs(1);
        end
        
    else
        alpha_lrtc = []; freqBand = []; window_sizes = [];
    end
    
    % Save the final exponent vector just like the connectivity matrices
    save(analysisDetailsFileLRTC, 'alpha_lrtc', 'numGoodTrials', 'freqBand', 'window_sizes');
end