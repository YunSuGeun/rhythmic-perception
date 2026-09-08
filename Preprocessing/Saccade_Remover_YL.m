function selectIdx = Saccade_Remover_YL(eSpd, Pre, Post,Auto,Sac_thrhold)
% This script is for counting Saccade trials 
% eSpd = 
% pre = the starts of time window for the onset time of saccade generator stimulus. 
% post = the end of time window for the onset time of saccade generator stimulus. 
% 

% This script is for removing Saccade 
% [pipline]
% 
% eSpd = = the velocity data(horizontal or vertical velocity y, time x) from Edf_Tool_YL_ver03 
% pre, post = start and end time points of time range in which saccade could be generated
% Auto = 1 and 0 (you can select the full auto(2), semi auto(1), or no auto mode(0)) 
%      When you set the Auto mode =1, the graph of velocities by each trials will be shown.
%      You should select the range by using mouse cursor. After clicking and draging the mouse button, the box line appears.
%      You can adjust the size of box. The velocity lines that are included
%      in box will be removed. Then, press the enter button for moving on the next.  
% Auto =2 (automatically remove the saccade trials according to "remove_line"
% remove_line = 20;remove_line is criterion for saccade. Usually above 20 is enough criterion for saccade  

pre = Pre/2;% /2ms 
post = Post/2;

% %% -----Automode---------
% Detecting the trials over remove_line in eSpd data
% Removing the trials
if Auto >=1 
    sac = [];
    osz = size(eSpd, 1);
    
    for i = 1:size(eSpd,1)
               % tmp = find(eSpd(i,1:pre+post) > remove_line);
                tmp = find(abs(eSpd(i,:)) > Sac_thrhold);
        sac = [sac; size(tmp,2)];
    end

    autoIdx = find(sac > 0);
    reSpd(autoIdx,:) = NaN;

    if Auto ==2
        trIdx = [1:osz];
        idxVec = zeros(1, osz);
        kDown = 1;
        idxVec(autoIdx) =1;
        outlierIdx = find(idxVec == 1);
        disp(['num of Automatically removed samples = ' num2str(length(outlierIdx))]);
         tmpIdx = trIdx;
         tmpIdx(outlierIdx) = [];
    end
end


if Auto <=1
    % Graph will be shown. the velocities of all trials are plotted in X timepoint and Y velocity graph.  
    % Selecting the trials you wants to remove by mouse. 
    %% -----Drawing Graph(x=timepoint, y= velocity)
    osz = size(eSpd, 1);
    p = plot(eSpd', 'b');    % velocities of trials 
    set(p, 'color', [0.5 0.5 0.5])
    hold on
    plot([pre pre], [0 100],'m-.', 'LineWidth',2); % Stimulus onset
    plot([pre+25 pre+25], [0 100], 'g-.', 'LineWidth',2);  % Stimulus offset
    plot([pre+100 pre+100], [0 100], 'k', 'LineWidth',2);  % Stimulus offset
    
    % plot([pre-10 pre-10], [0 60], 'b:');
    % plot([pre+1 pre+1], [0 60], 'k:');
    % plot([pre+1+100 pre+1+100], [0 60], 'k:');
    % plot([pre+1+230 pre+1+230], [0 60], 'r:');
    % plot([pre+1+250 pre+1+250], [0 60], 'cy-.');
    % plot([0 pre+post], [5 5], 'r:')
    % plot([0 pre+post], [7.5 7.5], 'g:')
    % plot([0 pre+post], [10 10], 'b:')
    hold off
    set(gca, 'tickdir', 'out', 'box', 'off');
    set(gca, 'ylim', [0 100], 'xlim', [0 post]);
    grid on
    
    sz = size(eSpd, 1);
    trIdx = [1:osz];
    idxVec = zeros(1, osz);
    kDown = 1;
    
    if Auto ==1
        idxVec(autoIdx) =1;
        outlierIdx = find(idxVec == 1);
        disp(['num of Automatically removed samples = ' num2str(length(outlierIdx))]);
    end 
    
    while(kDown)
        rge = getrect(gca);
        for i = 1:sz
            ftmp = [];
            tmpMat = [];
            tmpMat = eSpd(i, [round(rge(1)):round(rge(1))+round(rge(3))]);
            ftmp = find(tmpMat > rge(2) & tmpMat < rge(2)+rge(4));
            if ~isempty(ftmp)
                idxVec(i) = 1;
            end
        end
        outlierIdx = find(idxVec == 1);
        disp(['num of removed samples = ' num2str(length(outlierIdx))]);
         tmpIdx = trIdx;
         tmpIdx(outlierIdx) = [];
        p = plot(eSpd(tmpIdx, :)', 'b');
        set(p, 'color', [0.5 0.5 0.5])
        hold on
        plot([pre pre], [0 100],'m-.', 'LineWidth',2); % Stimulus onset
        plot([pre+25 pre+25], [0 100], 'g-.', 'LineWidth',2);  % Stimulus offset
        plot([pre+100 pre+100], [0 100], 'k', 'LineWidth',2);  % Stimulus offset
        %     plot([pre-10 pre-10], [0 60], 'b:');
        %     plot([pre+1 pre+1], [0 60], 'k:');
        %     plot([pre+1+100 pre+1+100], [0 60], 'k:');
        %     plot([pre+1+230 pre+1+230], [0 60], 'r:');
        %     plot([pre+1+250 pre+1+250], [0 60], 'cy-.');
        %     plot([0 pre+post], [5 5], 'r:')
        %     plot([0 pre+post], [7.5 7.5], 'g:')
        %     plot([0 pre+post], [10 10], 'b:')
        hold off
        set(gca, 'tickdir', 'out', 'box', 'off');
        set(gca, 'ylim', [0 100], 'xlim', [0 post]);
        grid on
        
        keydown = waitforbuttonpress;
        if (keydown == 1)
            kDown= 0;
            continue
        elseif (keydown == 0)
            continue;
        end
        continue;
    end
end
% trIdx = transpose([1:osz]);
% trIdx(autoIdx) = [];

selectIdx = tmpIdx;