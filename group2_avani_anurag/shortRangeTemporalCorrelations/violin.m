% Correct way to get the paired lists from your specific function
pairedData = getPairedSubjectsBK1(); 
medPaired  = pairedData(:, 1); % All rows, first column
ctrlPaired = pairedData(:, 2); % All rows, second column

% The rest of your script stays the same
targetElec = 2; 
protoIdx = 4;   

medVals = [];
ctrlVals = [];

for i = 1:length(medPaired)
    mRow = find(strcmp(medSubjects, medPaired{i}));
    cRow = find(strcmp(ctrlSubjects, ctrlPaired{i}));
    
    if ~isempty(mRow) && ~isempty(cRow)
        mV = medData(mRow, protoIdx, targetElec);
        cV = ctrlData(cRow, protoIdx, targetElec);
        
        if ~isnan(mV) && ~isnan(cV)
            medVals = [medVals; mV];
            ctrlVals = [ctrlVals; cV];
        end
    end
end

% Now plot... (use the plotting code from the previous message)

% 3. Plotting the Comparison
figure('Color', 'w', 'Position', [200 200 500 600]);
hold on;

% Draw connecting lines for the pairs
plot([1, 2], [medVals, ctrlVals]', 'Color', [0.8 0.8 0.8], 'LineWidth', 1);

% Overlay individual points
scatter(ones(size(medVals)), medVals, 80, 'filled', 'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerFaceAlpha', 0.5);
scatter(ones(size(ctrlVals))*2, ctrlVals, 80, 'filled', 'MarkerFaceColor', [0.2 0.2 0.8], 'MarkerFaceAlpha', 0.5);

% Add Boxplot for summary stats
boxplot([medVals, ctrlVals], 'Colors', 'k', 'Widths', 0.3);

set(gca, 'XTick', [1 2], 'XTickLabel', {'Meditators', 'Controls'}, 'FontSize', 12);
ylabel('\tau (Intrinsic Timescale in ms)', 'FontWeight', 'bold');
title(['Matched Pair Comparison: Electrode ', num2str(targetElec)]);
grid on;