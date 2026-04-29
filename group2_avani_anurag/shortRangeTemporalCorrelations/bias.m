% =========================================================================
% Bias and Covariate Analysis for Intrinsic Timescale (\tau)
% Corrected Hemispheric Asymmetry and Demographic Mapping
% =========================================================================
clear; clc;

%% 1. Setup Paths
basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');
protocol = 'M1'; 

%% 2. Embed Provided Data
% Experience Data (Practice Hours)
hoursRaw = {'006SR', 10010; '008RS', 7280; '010AK', 9100; '012GK', 8281; '013AR', 8281; '015RK', 4610.7; '017KG', 18443; '019CKa', 9464; '024SK', 2097.3; '025RK', NaN; '030SH', 4246.7; '031BK', NaN; '035SS', 9360; '036MS', 7098; '038DK', 4680; '040VS', 7488; '041AG', 10400; '042VA', 11232; '044PN', 13347; '045SP', 27027; '046ME', 4550; '050UR', 10010; '051RA', 27209; '052PR', 2730; '053DR', 21294; '054MP', 5200; '056PR', 4459; '059MS', 13923; '060GV', 5763.3; '074KS', 5824; '089AB', 30576; '090AV', 6240; '094SR', 6370; '095KM', 7674.3; '096MS', 27209};
medList = hoursRaw(:,1);
medHours = cell2mat(hoursRaw(:,2));

% Demographics Data (Age and Gender)
demoRaw = {'006SR', 41, 'F'; '008RS', 64, 'F'; '010AK', 54, 'M'; '012GK', 28, 'M'; '013AR', 35, 'F'; '015RK', 37, 'M'; '017KG', 49, 'F'; '019CKa', 23, 'M'; '024SK', 64, 'F'; '025RK', 49, 'M'; '030SH', 56, 'F'; '031BK', 24, 'F'; '035SS', 50, 'M'; '036MS', 47, 'F'; '038DK', 38, 'M'; '040VS', 27, 'M'; '041AG', 41, 'M'; '042VA', 50, 'F'; '044PN', 54, 'M'; '045SP', 47, 'M'; '046ME', 62, 'M'; '050UR', 53, 'F'; '051RA', 31, 'M'; '052PR', 31, 'F'; '053DR', 43, 'M'; '054MP', 35, 'M'; '056PR', 27, 'F'; '059MS', 34, 'F'; '060GV', 51, 'F'; '074KS', 36, 'F'; '089AB', 62, 'F'; '090AV', 32, 'M'; '094SR', 45, 'F'; '095KM', 30, 'M'; '096MS', 26, 'M'};

%% 3. Define Hemispheric Electrode Groups (Paired)
hubL{1} = [14:16, 32+[12:15]];             hubR{1} = [18:20, 32+[17:20]];            hubName{1} = 'Occipital';
hubL{2} = [6:8, 11, 12, 32+[7:9, 11]];     hubR{2} = [22, 23, 25, 28, 29, 32+[22, 24:26]]; hubName{2} = 'Central';
hubL{3} = [1, 3, 4, 32+[1, 2, 4, 5]];      hubR{3} = [30:32, 32+[28:31]];            hubName{3} = 'Frontal';

numMeds = length(medList); numHubs = length(hubName);
globalTau = nan(numMeds, 1);
tauL = nan(numMeds, numHubs); tauR = nan(numMeds, numHubs);
medAge = nan(numMeds, 1); isMale = false(numMeds, 1);

%% 4. Data Extraction
fprintf('Extracting Group Data...\n');
for i = 1:numMeds
    subj = medList{i};
    fName = fullfile(dataFolder, subj, [protocol '_ep_v8_srtc.mat']);
    if exist(fName, 'file')
        tmp = load(fName);
        if isfield(tmp, 'tau_srtc') && ~isempty(tmp.tau_srtc)
            tData = tmp.tau_srtc(:)';
            globalTau(i) = nanmean(tData);
            for h = 1:numHubs
                tauL(i, h) = nanmean(tData(hubL{h}));
                tauR(i, h) = nanmean(tData(hubR{h}));
            end
        end
    end
    % Map Demographics
    dIdx = find(strcmp(demoRaw(:,1), subj));
    if ~isempty(dIdx); medAge(i) = demoRaw{dIdx,2}; isMale(i) = strcmp(demoRaw{dIdx,3},'M'); end
end

%% 5. Visualization Dashboard
figure('Name', 'Covariate & Bias Dashboard', 'Color', 'w', 'Position', [50 50 1250 900]);

% A. AGE BIAS
subplot(2,2,1); hold on;
v = ~isnan(medAge) & ~isnan(globalTau);
scatter(medAge(v), globalTau(v), 70, 'filled', 'MarkerFaceColor', [0.3 0.6 0.8], 'MarkerEdgeColor', 'k');
[r, p] = corr(medAge(v), globalTau(v), 'Type', 'Spearman');
plot(xlim, polyval(polyfit(medAge(v), globalTau(v), 1), xlim), 'k--');
title(sprintf('Age Bias (r = %.2f, p = %.3f)', r, p));
xlabel('Age (Years)'); ylabel('Global \tau (ms)'); grid on;

% B. EXPERIENCE BIAS
subplot(2,2,2); hold on;
v = ~isnan(medHours) & ~isnan(globalTau);
scatter(medHours(v), globalTau(v), 70, 'filled', 'MarkerFaceColor', [0.2 0.7 0.3], 'MarkerEdgeColor', 'k');
[r, p] = corr(medHours(v), globalTau(v), 'Type', 'Spearman');
plot(xlim, polyval(polyfit(medHours(v), globalTau(v), 1), xlim), 'k--');
title(sprintf('Experience Bias (r = %.2f, p = %.3f)', r, p));
xlabel('Practice Hours'); ylabel('Global \tau (ms)'); grid on;

% C. GENDER BIAS
subplot(2,2,3); hold on;
mT = globalTau(isMale & ~isnan(globalTau)); fT = globalTau(~isMale & ~isnan(globalTau));
[~, pG] = ttest2(mT, fT);
boxplot([mT; fT], [ones(size(mT)); 2*ones(size(fT))], 'Labels', {'Male','Female'});
title(sprintf('Gender Comparison (p = %.3f)', pG)); ylabel('\tau (ms)'); grid on;

% D. HEMISPHERIC ASYMMETRY (SIDE BIAS)
subplot(2,2,4); hold on;
mL = nanmean(tauL, 1); mR = nanmean(tauR, 1);
b = bar([mL', mR'], 'EdgeColor', 'k');
b(1).FaceColor = [0.8 0.4 0.4]; b(2).FaceColor = [0.4 0.4 0.8];
xticks(1:numHubs); xticklabels(hubName);
ylabel('Hub \tau (ms)'); title('Hemispheric Asymmetry (L vs R)');
legend({'Left', 'Right'}, 'Location', 'northeast'); grid on;

% Add Paired P-Values
yMax = max([mL, mR]);
for h = 1:numHubs
    v = ~isnan(tauL(:,h)) & ~isnan(tauR(:,h));
    [~, pH] = ttest(tauL(v, h), tauR(v, h)); % Paired T-Test
    star = 'n.s.'; if pH < 0.05; star = sprintf('p=%.3f *', pH); end
    text(h, yMax*1.1, star, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
ylim([0 yMax*1.3]);

sgtitle('Dataset Covariate & Bias Analysis', 'FontSize', 18, 'FontWeight', 'bold');