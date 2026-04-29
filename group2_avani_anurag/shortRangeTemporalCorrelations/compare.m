% --- Grand Average Comparison ---
% 1. Calculate means across subjects for each group
meanMed  = squeeze(nanmean(medData, 1));  % [numProtocols x 64]
meanCtrl = squeeze(nanmean(ctrlData, 1)); % [numProtocols x 64]

% 2. Use a specific protocol (e.g., M1 = Protocol 4)
p_idx = 4; 

% 3. Set global limits so the colors are comparable
clim = [min([meanMed(p_idx,:), meanCtrl(p_idx,:)]) max([meanMed(p_idx,:), meanCtrl(p_idx,:)])];

figure('Name', 'Grand Average Tau: Med vs Ctrl', 'Color', 'w', 'Position', [100 100 1000 450]);

subplot(1,2,1);
topoplot(meanMed(p_idx,:), chanlocs, 'maplimits', clim, 'electrodes', 'on');
title('Meditators: Avg \tau (M1)'); colorbar;

subplot(1,2,2);
topoplot(meanCtrl(p_idx,:), chanlocs, 'maplimits', clim, 'electrodes', 'on');
title('Controls: Avg \tau (M1)'); colorbar;