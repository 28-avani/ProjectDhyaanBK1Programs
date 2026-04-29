% =========================================================================
% Correlation Analysis: Practice Hours vs. Intrinsic Neural Timescale (tau)
% =========================================================================

%% 1. Load Practice Hours Data
practiceHoursPath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing/ProjectDhyaanBK1Programs/commonAnalysisCodes/informationFiles/BK1PracticeHours.mat';
load(practiceHoursPath); % Loads 'practiceHours'

%% 2. Extract Data for a Specific Electrode and Protocol
targetElecIdx = 50; % As identified earlier (Highest t-value)
protoIdx = 4;      % Meditation 1 (M1)

% Initialize arrays
X_hours = [];
Y_tau = [];

% Iterate through the Meditators you have in 'medData'
for s = 1:length(medSubjects)
    subjName = medSubjects{s};
    
    % Find this subject's hours in the practiceHours cell array
    % Assuming practiceHours is a cell array like the one you shared
    rowIdx = find(strcmp(practiceHours(:, 1), subjName));
    
    if ~isempty(rowIdx)
        hrs = practiceHours{rowIdx, 2};
        tauVal = medData(s, protoIdx, targetElecIdx);
        
        % Only include if both values are valid (not NaN)
        if ~isnan(hrs) && ~isnan(tauVal)
            X_hours = [X_hours; hrs];
            Y_tau = [Y_tau; tauVal];
        end
    end
end

%% 3. Statistical Correlation
% We use Spearman correlation if the data isn't perfectly linear/normal
[r, p_val] = corr(X_hours, Y_tau, 'Type', 'Spearman');

%% 4. Plotting the Scatter Plot
figure('Color', 'w', 'Position', [200 200 600 500]);
scatter(X_hours, Y_tau, 80, 'filled', 'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerFaceAlpha', 0.6);
hold on;

% Add a trend line (Linear fit)
coeffs = polyfit(X_hours, Y_tau, 1);
fittedX = linspace(min(X_hours), max(X_hours), 100);
fittedY = polyval(coeffs, fittedX);
plot(fittedX, fittedY, 'k--', 'LineWidth', 1.5);

% Formatting
xlabel('Total Meditation Practice (Hours)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel(['\tau (ms) at ' chanlocs(targetElecIdx).labels], 'FontSize', 12, 'FontWeight', 'bold');
title(['Dose-Response: Practice Hours vs. \tau (Electrode ', num2str(targetElecIdx), ')'], 'FontSize', 14);

% Add stats to the plot
text(max(X_hours)*0.6, max(Y_tau)*0.9, ...
    sprintf('Spearman r = %.3f\np = %.4f', r, p_val), ...
    'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'k', 'BackgroundColor', 'w');

grid on;