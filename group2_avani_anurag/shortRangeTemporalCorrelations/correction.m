% Use your existing t_vals and p_vals from the previous t-test loop
fdrThreshold = 0.0255; 

figure('Name', 'FDR-Corrected Significant Electrodes', 'Color', 'w');
% We mask the T-values: anything not significant becomes 0
robustT = t_vals .* (p_vals <= fdrThreshold); 

topoplot(robustT, chanlocs, 'maplimits', [-4 4], 'electrodes', 'on', 'style', 'both');
title(['Robust Group Differences (FDR p < ', num2str(fdrThreshold), ')']);
colorbar;