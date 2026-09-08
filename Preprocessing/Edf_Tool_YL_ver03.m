function [hxvel_Target hxvel_Cue hyvel_Target hyvel_Cue gx_Target, gx_Cue, gy_Target,gy_Cue] = Edf_Tool_YL_ver03(rawDir2, edf_file, pre, post, drawGraph)
% This script is for extracting x, y points' velocities and position points. 


% [input variable]
% rawDir = raw data dir / edf_file = edf file name / pre, post = start and end time points of time range in which saccade could be generated / drawGraph = graph or not

% [output variable]
% x,y points' velocities and x,y position points(for Target and Cue)

% [pipeline]
% 1. loading EDF file 
% 2. Extracting Timing info from EDF 
% 3. Extracting velocities for x,y points from EDF
% 4. Setting Timepoints
% 5. Extracting Gaze data 
% 6. Saving 
 
 
	if ~exist('drawGraph', 'var') || isempty(drawGraph)
		drawGraph = false;
	end

    oldDir = pwd; 
    cd(rawDir2);
%% EDF file load
% "edfmex" function in Z:\younglae\Rhythmic_Attention\Analysis\functions\edf-converter-master\edf-converter-master
%  https://github.com/HukLab/edfmex/blob/master/edfmex.m
%  convert edf into m file  
	EDF = edfmex(edf_file); % edf file 2 mat file
    cd(oldDir);
%% Extracting Timing info 
  % Target_onset Timing 
	Trial_Target = cellfun(@(s) strcmp(s, 'Target_Onset'), {EDF.FEVENT.message});
	time_st_T = cell2mat({EDF.FEVENT.sttime});
	time_st_T = time_st_T(Trial_Target);
  % Cue_onset timing 
	Trial_PreCue = cellfun(@(s) strcmp(s, 'Pre_Cue_Onset'), {EDF.FEVENT.message});
	Trial_PosCue = cellfun(@(s) strcmp(s, 'Pos_Cue_Onset'), {EDF.FEVENT.message});
  
  % Cue timing (pre + post)
    Trial_Cue = Trial_PreCue + Trial_PosCue;
    time_st_C = cell2mat({EDF.FEVENT.sttime});
 	time_st_C = time_st_C(logical(Trial_Cue));
    
  %% - gx gy/ Gaze points x,y
    %%%% 윤수근 gy -> gx로 수정함%%%%%%
    
    % Initialize raw_gx as a copy of EDF.FSAMPLE.gx
    raw_gx = EDF.FSAMPLE.gx;
    % Get the logical index for elements that are outside the range [1, 1024] in the first row of gx
    index_gx1 = (EDF.FSAMPLE.gx(1, :) < 1 | EDF.FSAMPLE.gx(1, :) > 1024);
    % Replace those elements in raw_gx with corresponding elements from the second row
    raw_gx(1, index_gx1) = EDF.FSAMPLE.gx(2, index_gx1);
    % Get the logical index for elements that are outside the range [1, 1024] in the second row of gx
    index_gx2 = (EDF.FSAMPLE.gx(2, :) < 1 | EDF.FSAMPLE.gx(2, :) > 1024);
    % Replace those elements in raw_gx with corresponding elements from the first row
    raw_gx(2, index_gx2) = EDF.FSAMPLE.gx(1, index_gx2);
    % Compute the mean of gx and assign it to raw_gx
    raw_gx = mean(raw_gx, 1); % Average left and right

    % Initialize raw_gy as a copy of EDF.FSAMPLE.gy
    raw_gy = EDF.FSAMPLE.gy;
    % Get the logical index for elements that are outside the range [1, 768] in the first row of gy
    index_gy1 = (EDF.FSAMPLE.gy(1, :) < 1 | EDF.FSAMPLE.gy(1, :) > 768);
    % Replace those elements in raw_gy with corresponding elements from the second row
    raw_gy(1, index_gy1) = EDF.FSAMPLE.gy(2, index_gy1);
    % Get the logical index for elements that are outside the range [1, 768] in the second row of gy
    index_gy2 = (EDF.FSAMPLE.gy(2, :) < 1 | EDF.FSAMPLE.gy(2, :) > 768);
    % Replace those elements in raw_gy with corresponding elements from the first row
    raw_gy(2, index_gy2) = EDF.FSAMPLE.gy(1, index_gy2);
    % Compute the mean of gy and assign it to raw_gy
    raw_gy = mean(raw_gy, 1); % Average left and right


  
%     for i = 1:2
%         if any(raw_gx(i,:) == 0)
%             disp(sprintf('x value = 0, %d, %s', i, edf_file))
%         end
%          if any(raw_gy(i,:) == 0)
%             disp(sprintf('y value = 0, %d, %s',i, edf_file))
%         end   
%         if any(raw_gx(i,:) == -32768)
%             disp(sprintf('\n x value = -32768, %d, %s',i, edf_file))
%         end
%         if any(raw_gy(i,:) == -32768)
%             disp(sprintf('\n y value = -32768, %d, %s',i, edf_file))
%         end    
%     end
    
    
    Time_vel = EDF.FSAMPLE.time;
    
    total_time = pre + post;
    total_timePo = (1:total_time/2) - 1;
	pos_timePo = (1:post/2) - 1;
    pre_timePo = pre/2 ; % pre/2ms = timepoint (ex) 50ms/2ms = 25 timepoint 
    
	gx_Target = zeros(length(time_st_T), total_time/2);
    gx_Cue = zeros(length(time_st_C), total_time/2);
	gy_Target = zeros(length(time_st_T), total_time/2);
    gy_Cue = zeros(length(time_st_C), total_time/2);
	for i = 1:length(time_st_T)
		gx_Target(i, :) = raw_gx(find(Time_vel >= time_st_T(i)-pre_timePo, 1) + total_timePo);
        gx_Cue(i, :) = raw_gx(find(Time_vel >= time_st_C(i)-pre_timePo, 1) + total_timePo);
        gy_Target(i, :) = raw_gy(find(Time_vel >= time_st_T(i)-pre_timePo, 1) + total_timePo);
        gy_Cue(i, :) = raw_gy(find(Time_vel >= time_st_C(i)-pre_timePo, 1) + total_timePo);
    end  
    
	if drawGraph
		figure;
		%subplot(1, 2, 1);
        plot(gx_Cue(:,:)');
        figure;
		%subplot(1, 2, 2);
        plot(gx_Target(:,:)');
		figure;
		%subplot(1, 2, 1);
        plot(gy_Cue(:,:)');
        figure;
		%subplot(1, 2, 2);
        plot(gy_Target(:,:)');        
	end
    
    
    
    
    %% -- Extracting gxvel gyvel / gaze position x,y points's velocities 

    % Initialize raw_hxvel as a copy of EDF.FSAMPLE.gxvel
    raw_hxvel = EDF.FSAMPLE.gxvel;
    % Replace those elements in raw_hxvel with corresponding elements from the second row
    raw_hxvel(1, index_gx1) = EDF.FSAMPLE.gxvel(2, index_gx1);
    % Replace those elements in raw_hxvel with corresponding elements from the first row
    raw_hxvel(2, index_gx2) = EDF.FSAMPLE.gxvel(1, index_gx2);
    % Compute the mean of gxvel and assign it to raw_hxvel
    raw_hxvel = mean(raw_hxvel, 1); % Average left and right

    % Initialize raw_hyvel as a copy of EDF.FSAMPLE.gyvel
    raw_hyvel = EDF.FSAMPLE.gyvel;
    % Replace those elements in raw_hyvel with corresponding elements from the second row
    raw_hyvel(1, index_gy1) = EDF.FSAMPLE.gyvel(2, index_gy1);
    % Replace those elements in raw_hyvel with corresponding elements from the first row
    raw_hyvel(2, index_gy2) = EDF.FSAMPLE.gyvel(1, index_gy2);
    % Compute the mean of gyvel and assign it to raw_hyvel
    raw_hyvel = mean(raw_hyvel, 1); % Average left and right


%     raw_hxvel = rawvel(raw_gx);
%     raw_hxvel = mean(raw_hxvel,1);
%     raw_hyvel = mean(rawvel(raw_gy),1);
    
    
    %% --Extracting hxvel hyvel / head-referenced position x,y's velocities (HREF; head-referenced position data); eye rotation angles relative to the head / if you want to use it, Please remove % .
     % - x = horizontal, y = vertical 
     
% 	raw_hxvel = mean(EDF.FSAMPLE.hxvel, 1);
% 	raw_hxvel(EDF.FSAMPLE.hxvel(1, :) == 0) = EDF.FSAMPLE.hxvel(2, EDF.FSAMPLE.hxvel(1, :) == 0);
% 	raw_hxvel(EDF.FSAMPLE.hxvel(2, :) == 0) = EDF.FSAMPLE.hxvel(1, EDF.FSAMPLE.hxvel(2, :) == 0);
% 	raw_hxvel =EDF.FSAMPLE.gxvel(1,:); %mean(EDF.FSAMPLE.gxvel, 1); % WHAT????????
% 	raw_hxvel = mean(EDF.FSAMPLE.hxvel, 1);
%  	raw_hxvel(EDF.FSAMPLE.hyvel(1, :) == 0) = EDF.FSAMPLE.hyvel(2, EDF.FSAMPLE.hyvel(1, :) == 0);
%  	raw_hxvel(EDF.FSAMPLE.hyvel(2, :) == 0) = EDF.FSAMPLE.hyvel(1, EDF.FSAMPLE.hyvel(2, :) == 0);
% 	raw_hyvel = mean(EDF.FSAMPLE.hxvel, 1);
%  	raw_hyvel(EDF.FSAMPLE.hyvel(1, :) == 0) = EDF.FSAMPLE.hyvel(2, EDF.FSAMPLE.hyvel(1, :) == 0);
%  	raw_hyvel(EDF.FSAMPLE.hyvel(2, :) == 0) = EDF.FSAMPLE.hyvel(1, EDF.FSAMPLE.hyvel(2, :) == 0);    

    %%  --- Setting time points  and  Extracting velocities of Head corrected x,y from EDF file 
    % you should remind that Saccade usually generates 200ms~300ms after stumulus onset. You can determine the time range which saccade is generated in.
    % In here, pos(t) is the end of time range after stimulus onset. pre is the start of time range before stimulus onset. 
    % The one data point for time is 2ms
    
    Time_vel = EDF.FSAMPLE.time;
    total_time = pre + post;
    total_timePo = (1:total_time/2) - 1;
    
	pos_timePo = (1:post/2) - 1;
    pre_timePo = pre/2 ; % pre/2ms = timepoint (ex) 50ms/2ms = 25 timepoint 
    
	hxvel_Target = zeros(length(time_st_T), total_time/2);
    hxvel_Cue = zeros(length(time_st_C), total_time/2);
	hyvel_Target = zeros(length(time_st_T), total_time/2);
    hyvel_Cue = zeros(length(time_st_C), total_time/2);
	for i = 1:length(time_st_T)
		hxvel_Target(i, :) = raw_hxvel(find(Time_vel >= time_st_T(i)-pre_timePo, 1) + total_timePo);
        hxvel_Cue(i, :) = raw_hxvel(find(Time_vel>= time_st_C(i)-pre_timePo, 1) + total_timePo);
        hyvel_Target(i, :) = raw_hyvel(find(Time_vel >= time_st_T(i)-pre_timePo, 1) + total_timePo);
        hyvel_Cue(i, :) = raw_hyvel(find(Time_vel >= time_st_C(i)-pre_timePo, 1) + total_timePo);
  	end
% 	pamat_Target = pamat_Target(emat(:, 1), :);
% 	pamat_Cue = pamat_Cue(emat(:, 1), :);    
    
    
    
	if drawGraph
		figure;
		%subplot(1, 2, 1);
        plot(hxvel_Cue(:,:)');
        figure;
		%subplot(1, 2, 2);
        plot(hxvel_Target(:,:)');
		figure;
		%subplot(1, 2, 1);
        plot(hyvel_Cue(:,:)');
        figure;
		%subplot(1, 2, 2);
        plot(hyvel_Target(:,:)');        
	end


end