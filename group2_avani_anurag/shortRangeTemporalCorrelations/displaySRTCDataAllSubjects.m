function displaySRTCAllSubjects_GUI()
    % =====================================================================
    % Interactive SRTC Analysis Dashboard - IISc Neural Signal Processing
    % =====================================================================
    
    hFig = figure('Name', 'SRTC Analysis Dashboard', 'NumberTitle', 'off', ...
                  'Position', [50, 50, 1450, 850], 'Color', 'w', 'MenuBar', 'none');
              
    uiPanel = uipanel('Parent', hFig, 'Title', 'Setup Options', ...
                      'Position', [0.01, 0.01, 0.16, 0.98], 'FontSize', 12, 'FontWeight', 'bold');
                  
    labels = {'Comparison:', 'Gender:', 'Age:', 'Protocol:', 'Reference:', ...
              'Bad Eye Condition:', 'Trial Version:', 'Bad Electrode Choice:'};
          
    options{1} = {'unpaired', 'paired'};
    options{2} = {'all', 'male', 'female'}; 
    options{3} = {'all', 'young', 'mid'};
    options{4} = {'EO1', 'EC1', 'G1', 'M1', 'G2', 'EO2', 'EC2', 'M2'};
    options{5} = {'none', 'EO1', 'EC1', 'G1', 'M1', 'G2', 'EO2', 'EC2', 'M2'};
    options{6} = {'ep', 'wo'};
    options{7} = {'v8'};
    options{8} = {'Reject bad of Protocol', 'Reject common of All', 'Reject bad of G1'};
    
    hDropdowns = cell(8,1);
    yPos = 0.92;
    for i = 1:8
        uicontrol('Parent', uiPanel, 'Style', 'text', 'String', labels{i}, ...
                  'Units', 'normalized', 'Position', [0.05, yPos, 0.9, 0.03], ...
                  'HorizontalAlignment', 'left', 'FontSize', 10);
        hDropdowns{i} = uicontrol('Parent', uiPanel, 'Style', 'popupmenu', ...
                  'String', options{i}, 'Units', 'normalized', ...
                  'Position', [0.05, yPos-0.035, 0.9, 0.03], 'FontSize', 10);
        yPos = yPos - 0.09;
    end
    
    chkMedian = uicontrol('Parent', uiPanel, 'Style', 'checkbox', 'String', 'Use Median', ...
                          'Units', 'normalized', 'Position', [0.05, yPos, 0.9, 0.04], 'FontSize', 10);
    
    uicontrol('Parent', uiPanel, 'Style', 'pushbutton', 'String', 'PLOT DATA', ...
              'Units', 'normalized', 'Position', [0.05, yPos-0.08, 0.9, 0.06], ...
              'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.2 0.7 0.3], 'ForegroundColor', 'w', ...
              'Callback', @plotDataCallback);
          
    uicontrol('Parent', uiPanel, 'Style', 'pushbutton', 'String', 'CLEAR ALL', ...
              'Units', 'normalized', 'Position', [0.05, yPos-0.15, 0.9, 0.05], ...
              'FontSize', 11, 'BackgroundColor', [0.9 0.2 0.2], 'ForegroundColor', 'w', ...
              'Callback', @clearCallback);
    
    % --- Layout: 3 Topos (Top) and 3 Boxplots (Bottom) ---
    plotPanel = uipanel('Parent', hFig, 'Position', [0.18, 0.01, 0.81, 0.98], 'BackgroundColor', 'w', 'BorderType', 'none');
    
    axTopoMed  = axes('Parent', plotPanel, 'Position', [0.04, 0.58, 0.26, 0.35]);
    axTopoCtrl = axes('Parent', plotPanel, 'Position', [0.35, 0.58, 0.26, 0.35]);
    axTopoDiff = axes('Parent', plotPanel, 'Position', [0.66, 0.58, 0.26, 0.35]);
    
    axVioFT   = axes('Parent', plotPanel, 'Position', [0.04, 0.1, 0.27, 0.38]);
    axVioOcc  = axes('Parent', plotPanel, 'Position', [0.35, 0.1, 0.27, 0.38]);
    axVioAll  = axes('Parent', plotPanel, 'Position', [0.66, 0.1, 0.27, 0.38]);
    
    basePath = '/Users/avanisardana/IISc/6th_Sem/Neural_Signal_Processing';
    infoPath = fullfile(basePath, 'ProjectDhyaanBK1Programs', 'commonAnalysisCodes', 'informationFiles');
    dataFolder = fullfile(basePath, 'meditationDataset', 'SRTCsavedData');

    function plotDataCallback(~, ~)
        compType  = options{1}{get(hDropdowns{1}, 'Value')};
        protocol  = options{4}{get(hDropdowns{4}, 'Value')};
        refChoice = options{5}{get(hDropdowns{5}, 'Value')};
        eyeCond   = options{6}{get(hDropdowns{6}, 'Value')};
        trialVer  = options{7}{get(hDropdowns{7}, 'Value')};
        useMedian = get(chkMedian, 'Value');
        
        load(fullfile(infoPath, 'BK1AllSubjectList.mat'), 'meditatorList', 'controlList');
        capData = load('actiCap64_UOL.mat'); chanlocs = capData.chanlocs;
        
        if strcmp(compType, 'paired')
            pData = getPairedSubjectsBK1();
            medList = pData(:, 1); ctrlList = pData(:, 2);
        else
            medList = meditatorList; ctrlList = controlList;
        end
        
        % Robust Extraction
        medTau = extractProtocolData(medList, protocol, eyeCond, trialVer, dataFolder);
        ctrlTau = extractProtocolData(ctrlList, protocol, eyeCond, trialVer, dataFolder);
        
        % Subtraction Logic (Baseline Correction)
        if ~strcmp(refChoice, 'none')
            medRef = extractProtocolData(medList, refChoice, eyeCond, trialVer, dataFolder);
            ctrlRef = extractProtocolData(ctrlList, refChoice, eyeCond, trialVer, dataFolder);
            medTau = medTau - medRef; 
            ctrlTau = ctrlTau - ctrlRef;
        end
        
        if useMedian; mMed = nanmedian(medTau, 1); mCtrl = nanmedian(ctrlTau, 1);
        else; mMed = nanmean(medTau, 1); mCtrl = nanmean(ctrlTau, 1); end
        
        % Topoplots
        clims = [min([mMed(:); mCtrl(:)]), max([mMed(:); mCtrl(:)])];
        axes(axTopoMed); cla(axTopoMed); topoplot(mMed, chanlocs, 'maplimits', clims); colorbar; title('Meditators');
        axes(axTopoCtrl); cla(axTopoCtrl); topoplot(mCtrl, chanlocs, 'maplimits', clims); colorbar; title('Controls');
        axes(axTopoDiff); cla(axTopoDiff); topoplot(mMed-mCtrl, chanlocs, 'maplimits', 'maxmin'); colorbar; title('Difference');

        % Regional Indices
        idxFT = [1, 2, 3, 4, 5, 6, 33, 34, 35, 36]; 
        idxOcc = [28, 29, 30, 61, 62, 63, 64]; 
        
        plotVioWithStats(axVioFT, medTau(:, idxFT), ctrlTau(:, idxFT), 'Fronto-Temporal', compType);
        plotVioWithStats(axVioOcc, medTau(:, idxOcc), ctrlTau(:, idxOcc), 'Occipital', compType);
        plotVioWithStats(axVioAll, medTau, ctrlTau, 'Whole Brain', compType);
    end

    function plotVioWithStats(ax, mGroupData, cGroupData, rTitle, type)
        mSubj = nanmean(mGroupData, 2); cSubj = nanmean(cGroupData, 2);
        valid = ~isnan(mSubj) & ~isnan(cSubj);
        mY = mSubj(valid); cY = cSubj(valid);
        
        if strcmp(type, 'paired'); [~, p] = ttest(mY, cY);
        else; [~, p] = ttest2(mY, cY); end
        
        axes(ax); cla(ax, 'reset'); hold on;
        if strcmp(type, 'paired'); plot([1, 2], [mY, cY]', 'Color', [0.85 0.85 0.85]); end
        
        bh = boxplot([mY; cY], [ones(size(mY)); 2*ones(size(cY))], 'Labels', {'Med', 'Ctrl'}, 'Widths', 0.5);
        set(bh, 'LineWidth', 1.2);
        
        yMin = min([mY; cY]); yMax = max([mY; cY]); yRange = yMax - yMin;
        if yRange == 0; yRange = 1; end
        ylim([yMin - 0.15*yRange, yMax + 0.35*yRange]); 
        
        bracketY = yMax + 0.08*yRange;
        line([1, 2], [bracketY, bracketY], 'Color', 'k', 'LineWidth', 1.2);
        
        sigTxt = sprintf('p = %.4f', p);
        if p < 0.05; sigTxt = [sigTxt ' *']; end
        text(1.5, bracketY + 0.07*yRange, sigTxt, 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
        title(rTitle); ylabel('\tau (ms)'); grid on; set(ax, 'Color', 'w', 'XLim', [0.5 2.5]);
    end

    function data = extractProtocolData(subList, prot, eye, ver, folder)
        nSubj = length(subList); data = nan(nSubj, 64);
        for i = 1:nSubj
            fName = fullfile(folder, subList{i}, [prot '_' eye '_' ver '_srtc.mat']);
            if exist(fName, 'file')
                tmp = load(fName); 
                % FIX: Check size and force to row vector to match data(i,:) slice
                if isfield(tmp, 'tau_srtc') && ~isempty(tmp.tau_srtc)
                    data(i, :) = tmp.tau_srtc(:)'; 
                end
            end
        end
    end

    function clearCallback(~, ~)
        cla(axTopoMed, 'reset'); cla(axTopoCtrl, 'reset'); cla(axTopoDiff, 'reset');
        cla(axVioFT, 'reset'); cla(axVioOcc, 'reset'); cla(axVioAll, 'reset');
    end
end