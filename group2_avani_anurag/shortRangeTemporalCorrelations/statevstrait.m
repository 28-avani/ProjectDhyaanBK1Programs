% =========================================================================
% Subtractive Analysis: Meditation (M1) vs. Baseline (EO1)
% =========================================================================

% 1. Define Protocol Indices
baselineIdx = 1; % EO1
meditationIdx = 4; % M1

% 2. Calculate Delta Tau (State Change) for each subject
% Formula: Delta = Meditation - Baseline
medDeltaTau = squeeze(medData(:, meditationIdx, :) - medData(:, baselineIdx, :));
ctrlDeltaTau = squeeze(ctrlData(:, meditationIdx, :) - ctrlData(:, baselineIdx, :));

% 3. Statistical Comparison (Are the shifts different between groups?)
p_Delta = nan(numElectrodes, 1);
t_Delta = nan(numElectrodes, 1);

for e = 1:numElectrodes
    mD = medDeltaTau(:, e);
    cD = ctrlDeltaTau(:, e);
    
    % Remove NaNs
    mD = mD(~isnan(mD));
    cD = cD(~isnan(cD));
    
    if ~isempty(mD) && ~isempty(cD)
        [~, p, ~, stats] = ttest2(mD, cD);
        p_Delta(e) = p;
        t_Delta(e) = stats.tstat;
    end
end

% 4. Visualization of the Meditation Effect
figure('Name', 'State-Specific Meditation Effect (\Delta\tau)', 'Color', 'w', 'Position', [100 100 1200 450]);

subplot(1,3,1);
topoplot(nanmean(medDeltaTau, 1), chanlocs, 'maplimits', 'maxmin', 'electrodes', 'on');
title('Meditators: Avg Change (\tau_{M1} - \tau_{EO1})'); colorbar;

subplot(1,3,2);
topoplot(nanmean(ctrlDeltaTau, 1), chanlocs, 'maplimits', 'maxmin', 'electrodes', 'on');
title('Controls: Avg Change (\tau_{M1} - \tau_{EO1})'); colorbar;

subplot(1,3,3);
% Plot t-stat of the difference in shifts
topoplot(t_Delta, chanlocs, 'maplimits', [-3 3], 'electrodes', 'on');
title('Group Diff in State Change (t-stat)'); colorbar;

% 5. Bonus: Correlate this Shift with Practice Hours
% (Maybe the baseline is the same, but experts "shift" deeper?)
X_hours = [];
Y_delta = [];
targetElec = 50; % Check your top electrode again

for s = 1:length(medSubjects)
    subjName = medSubjects{s};
    rowIdx = find(strcmp(practiceHours(:, 1), subjName));
    if ~isempty(rowIdx)
        hrs = practiceHours{rowIdx, 2};
        dVal = medDeltaTau(s, targetElec);
        if ~isnan(hrs) && ~isnan(dVal)
            X_hours = [X_hours; hrs];
            Y_delta = [Y_delta; dVal];
        end
    end
end

if ~isempty(X_hours)
    [r_d, p_d] = corr(X_hours, Y_delta, 'Type', 'Spearman');
    fprintf('Correlation (Hours vs. Delta tau) at Elec %d: r = %.3f, p = %.4f\n', targetElec, r_d, p_d);
end