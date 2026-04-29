% =========================================================================
% Protocol-Specific Analysis: Meditator vs. Control (t-tests)
% =========================================================================

figure('Name', 'Group Differences (t-stat) Per Protocol', 'Color', 'w', 'Position', [50 50 1400 800]);
colormap('jet');

for p = 1:numProtocols
    t_vals = zeros(numElectrodes, 1);
    p_vals = zeros(numElectrodes, 1);
    
    for e = 1:numElectrodes
        % Extract data for this protocol and electrode
        medSubjData = medData(:, p, e);
        ctrlSubjData = ctrlData(:, p, e);
        
        % Remove NaNs for the t-test
        medSubjData = medSubjData(~isnan(medSubjData));
        ctrlSubjData = ctrlSubjData(~isnan(ctrlSubjData));
        
        % Perform Two-Sample t-test
        if ~isempty(medSubjData) && ~isempty(ctrlSubjData)
            [~, p_val, ~, stats] = ttest2(medSubjData, ctrlSubjData);
            t_vals(e) = stats.tstat;
            p_vals(e) = p_val;
        else
            t_vals(e) = 0;
            p_vals(e) = 1;
        end
    end
    
    % Subplot for each Protocol
    subplot(2, 4, p);
    
    % Option A: Plot t-values (Shows direction: Med > Ctrl or Med < Ctrl)
    topoplot(t_vals, chanlocs, 'maplimits', [-4 4], 'electrodes', 'on', 'style', 'both');
    
    % Option B: Mark significant electrodes with white dots
    hold on;
    sig_idx = find(p_vals < 0.05);
    % You can use topoplot's 'emarker' option for a cleaner look
    
    title(sprintf('%s: Med vs Ctrl', protocolList{p}), 'FontSize', 12, 'FontWeight', 'bold');
end

% Add a global colorbar
cb = colorbar('Position', [0.93 0.15 0.015 0.7]);
ylabel(cb, 't-statistic (Positive = Med > Ctrl)', 'FontSize', 12);
annotation('textbox', [0 0.9 1 0.1], 'String', 'Intrinsic Neural Timescale (\tau) Differences Per Protocol', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold');