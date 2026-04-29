% List of your top indices
top_indices = [63, 2, 36, 11, 50];

fprintf('--- Top Results Interpretation ---\n');
for i = 1:length(top_indices)
    idx = top_indices(i);
    label = chanlocs(idx).labels;
    p = p_Group(idx);
    t = t_vals(idx);
    
    fprintf('Rank %d | Label: %s | p=%.4f | t=%.2f\n', i, label, p, t);
end