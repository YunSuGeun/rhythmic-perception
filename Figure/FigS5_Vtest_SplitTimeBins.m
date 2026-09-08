%% Instantaneous Phase Check between Perf and Visi
clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

rawDir = fullfile(projectRoot, '01_Data', '06_PhaseAlign');
cd(rawDir)
figDir = fullfile(projectRoot, '03_Figure', 'FigureS5');

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file.
    
comparison = {'L','R'};
binCounts = [2,3,4]; % 1 = whole time points, others = split bins
for v = 1:2
    ver = comparison{v}
        
    % Define indices and offset
    if strcmp(ver, 'L')
        indices = [1, 3];
        offset = 4;
    elseif strcmp(ver, 'R')
        indices = [2, 4];
        offset = 4;
    end
    
    phaseDiffAll = cell(1, length(indices));
    condLabelAll = cell(1, length(indices));
    TiTBase = '';
    
    % Load both condition pairs first, then overlay in one plot
    for i = 1:length(indices)
        first_ind = indices(i);
        second_ind = first_ind + offset;
        
        first_name = data_selected{1,first_ind};
        conds = split(first_name); % Adjust delimiter as needed
        second_name = data_selected{1,second_ind};
    
        load(first_name);
        phase1 = instantaneous_phase; % Perf
    
        load(second_name);
        phase2 = instantaneous_phase; % Visi
        
        phaseDiffAll{i} = wrapToPi(phase1 - phase2);
        condLabelAll{i} = conds{5}; % 'Valid' or 'Invalid'
        
        if isempty(TiTBase)
            TiTBase = sprintf('%s %s', conds{3}, conds{6});
        end
    end
    
    saveDir = fullfile(figDir, ver);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    
    [nSubj, nTimepoint] = size(phaseDiffAll{1});
    for bc = 1:length(binCounts)
        nBins = binCounts(bc);
        binEdges = round(linspace(0, nTimepoint, nBins + 1));
        defPos = get(groot, 'DefaultFigurePosition');
        Figure1 = figure('Position', [defPos(1), defPos(2), defPos(3)*2, defPos(4)]);
        tiledlayout(1, nBins, 'TileSpacing', 'compact', 'Padding', 'compact');
        
        for b = 1:nBins
            idxStart = binEdges(b) + 1;
            idxEnd = binEdges(b + 1);
            
            nexttile;
            polarplot(0, 0, 'k', 'HandleVisibility', 'off');
            hold on;
            pax = gca;
            pax.ThetaTick = [0 90 180 270];
            pax.RTickLabel = {};
            
            titleParts = {};
            for i = 1:length(indices)
                phase_diff = phaseDiffAll{i};
                avg_angle_all = [];
                pvals = [];
                z_all = [];
                
                for subj = 1:nSubj
                    subj_phase_diff = phase_diff(subj, idxStart:idxEnd);
                    [pval, z] = circ_rtest(subj_phase_diff);
                    pvals = [pvals; pval];
                    z_all = [z_all, z];
                    avg_angle = circ_mean(subj_phase_diff, [], 2);
                    avg_angle_all = [avg_angle_all, avg_angle];
                end
                
                alpha = 0.05;
                h = fdr_bh(pvals, alpha, 'pdep', 'no');
                sig_avg_angle = avg_angle_all(logical(h(:)'));
                sig_z = z_all(logical(h(:)'));
                nSig = numel(sig_avg_angle);
                
                condStr = string(condLabelAll{i});
                if contains(lower(condStr), "i")
                    condName = 'Invalid';
                    lineColor = [1, 0, 0];
                else
                    condName = 'Valid';
                    lineColor = [0, 0.4470, 0.7410];
                end
                
                if nSig > 0
                    % Plot subject-wise vectors (length = Rayleigh z) with arrow heads
                    for s = 1:nSig
                        th = sig_avg_angle(s);
                        rr = sig_z(s);
                        % polarplot([0, th], [0, rr], ...
                            % 'Color', lineColor, 'LineWidth', 0.75, 'HandleVisibility', 'off');
                        
                        % Arrow head (two short wings at the tip)
                        wing = deg2rad(9);
                        headFrac = 0.06;
                        rBack = rr * (1 - headFrac);
                        % polarplot([th, th + wing], [rr, rBack], ...
                            % 'Color', lineColor, 'LineWidth', 0.75, 'HandleVisibility', 'off');
                        % polarplot([th, th - wing], [rr, rBack], ...
                            % 'Color', lineColor, 'LineWidth', 0.75, 'HandleVisibility', 'off');
                    end
                    
                    pval_v = circ_vtest(sig_avg_angle, 0);
                    mu = circ_mean(sig_avg_angle, [], 2);
                    mu = wrapToPi(mu);
                    rl = rlim;
                    polarplot([0, mu], rl, 'Color', lineColor, 'LineWidth', 4, 'DisplayName', condName);
                else
                    pval_v = NaN;
                end
                
                titleParts{end+1} = sprintf('%s p=%.3g', condName, pval_v);
            end
            
            % title(sprintf('Bin %d/%d | %s', b, nBins, strjoin(titleParts, ' | ')));
            % legend('Location', 'southoutside');
            hold off;
        end
        
        % sgtitle(sprintf('%s | %d time bin(s)', TiTBase, nBins));
        saveas(Figure1, fullfile(saveDir, sprintf('%s_bins%d.jpg', TiTBase, nBins)));
    end
    % close all
end
