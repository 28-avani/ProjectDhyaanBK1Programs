% --- Benjamini-Hochberg FDR Correction ---
q_level = 0.05; % Our desired false discovery rate
[p_sorted, idx] = sort(p_Group);
numTests = length(p_Group);
m = (1:numTests)' / numTests * q_level;

% Find the largest p-value that satisfies p <= (i/m)*q
max_idx = find(p_sorted <= m, 1, 'last');
if isempty(max_idx)
    p_threshold = 0;
    disp('No electrodes survived FDR correction.');
else
    p_threshold = p_sorted(max_idx);
    fprintf('FDR Corrected p-threshold: %.4f\n', p_threshold);
end

% Create a "Robust" significance mask
sigFDRMask = double(p_Group <= p_threshold);

figure;
topoplot(sigFDRMask, chanlocs, 'maplimits', [0 1], 'electrodes', 'on');
title('Robust Differences (Surviving FDR Correction)');