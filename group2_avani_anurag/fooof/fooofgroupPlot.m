% =========================================================================
% FOOOF Group Paired Analysis: Meditators vs Matched Controls
% BUGFIX: Correctly routes EO1 to exponentBL instead of exponentST.
% =========================================================================
clear; clc;
basePath = '/Users/anuragsarkar/Desktop/NSPCourse';
fooofFolder = fullfile(basePath, 'meditationDataset', 'FOOOFData');
if ~exist(fooofFolder, 'dir'); fooofFolder = '/Users/anuragsarkar/Desktop/NSPCourse/FOOOFData'; end

load(fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles', 'BK1AllSubjectList.mat'));

nPairs = min(length(meditatorList), length(controlList));
medList = meditatorList(1:nPairs); ctrlList = controlList(1:nPairs);
protM1 = 4; protEO1 = 1; freqIdx = 1;

regIdx{1} = [14:16, 18:20, 32+[12:15, 17:20]];                       regName{1} = 'Occipital'; 
regIdx{2} = [6:8, 11, 12, 22, 23, 25, 28, 29, 32+[7:9, 11, 22, 24:26]]; regName{2} = 'Central'; 
regIdx{3} = [1, 3, 4, 30:32, 32+[1, 2, 4, 5, 28:31]];                regName{3} = 'Frontal'; 
regIdx{4} = 1:64;                                                    regName{4} = 'All Brain'; 
numRegs = length(regName);

[medM1, medEO1] = loadGrp_Fixed(medList, fooofFolder, protM1, protEO1, freqIdx, numRegs, regIdx);
[ctrlM1, ctrlEO1] = loadGrp_Fixed(ctrlList, fooofFolder, protM1, protEO1, freqIdx, numRegs, regIdx);

figure('Name', 'Group FOOOF Paired Analysis', 'Color', 'w', 'Position', [50 50 1450 850]);

for r = 1:numRegs
    subplot(2, 4, r); plotPaired(medM1(:,r), ctrlM1(:,r), [regName{r} ' (Raw)']);
    subplot(2, 4, r+4); plotPaired(medM1(:,r)-medEO1(:,r), ctrlM1(:,r)-ctrlEO1(:,r), [regName{r} ' (\Delta M1-EO1)']);
end
%sgtitle('Group Paired FOOOF Exponent: Meditator vs Matched Control', 'FontSize', 22, 'FontWeight', 'bold');

%% --- HELPERS ---
function [dM1, dEO1] = loadGrp_Fixed(sList, fld, pM, pE, fI, nR, rI)
    dM1 = nan(length(sList), nR); dEO1 = nan(length(sList), nR);
    for i = 1:length(sList)
        files = dir(fullfile(fld, [sList{i} '*FOOOF.mat']));
        if ~isempty(files)
            tmp = load(fullfile(fld, files(1).name), 'exponentST', 'exponentBL');
            % M1 uses ST
            if length(tmp.exponentST) >= pM && ~isempty(tmp.exponentST{pM})
                m = tmp.exponentST{pM}(:,fI);
                for r=1:nR; dM1(i,r)=nanmean(m(rI{r})); end
            end
            % EO1 uses BL
            if length(tmp.exponentBL) >= pE && ~isempty(tmp.exponentBL{pE})
                e = tmp.exponentBL{pE}(:,fI);
                for r=1:nR; dEO1(i,r)=nanmean(e(rI{r})); end
            end
        end
    end
end

function plotPaired(mD, cD, tStr)
    v = ~isnan(mD) & ~isnan(cD); mY = mD(v); cY = cD(v);
    if isempty(mY) || length(mY) < 2
        title([tStr ' - Insufficient Data']); return; 
    end
    plot([1, 2], [mY, cY]', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.8); hold on;
    bh = boxplot([mY; cY], [ones(size(mY)); 2*ones(size(cY))], 'Labels', {'Med', 'Ctrl'}, 'Colors', 'k', 'Symbol', '');
    set(bh, 'LineWidth', 1.5);
    scatter(ones(size(mY)), mY, 45, [0.8 0.2 0.2], 'filled', 'MarkerFaceAlpha', 0.6);
    scatter(2*ones(size(cY)), cY, 45, [0.2 0.2 0.8], 'filled', 'MarkerFaceAlpha', 0.6);
    [~, p] = ttest(mY, cY); 
    yMx = nanmax([mY;cY]); yMn = nanmin([mY;cY]); yR = max(0.2, yMx - yMn);
    line([1, 2], [yMx+0.1*yR, yMx+0.1*yR], 'Color', 'k', 'LineWidth', 1.2);
    star = 'n.s.'; if p<0.05; star = sprintf('p=%.3f *', p); end
    text(1.5, yMx+0.18*yR, star, 'HorizontalAlignment','center','FontWeight','bold','FontSize',11);
    ylim([yMn-0.2*yR, yMx+0.4*yR]); grid on; title(tStr, 'FontSize', 14);
end