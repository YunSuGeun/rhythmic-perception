function [data] = Saccade_Data_YL_ver02( genDir2, Sti ,pre,post,Auto,Sac_thrhold, ang,Save,subj_name)
% This function is for making eye saccade data
%  1. loading edf data 
%     -using "Edf_Tool_YL_ver03" function 
%  2. counting saccade trials  
%     -using "Saccade_Remover_YL" function
% 
 
%% -----0. Setting  
t = datetime('now');
% 
% pre = 50 ;
% post = 350; 
% ang = 2;
%  Auto = 2; % To remove saccades 2 = only auto 1 = auto and handed , 0 = only handed 
%  remove_line = 20;
%  angleoff= deg2pixel(1.5);_2
%% -------1. load data
% genDir2 = 'D:\2020 BrainX\Rhythmic_retro2\Experiment\Rhythmic_retro2\edf';
rawDir2 = fullfile(genDir2);
oldDir = pwd; 
addpath(rawDir2);
cd(rawDir2);

edf_path = [rawDir2 '/'];  
file_name = [sprintf('R_%s*.edf',subj_name)];
edf_files = dir([edf_path  file_name]);
edf_name = struct2cell(edf_files);
subName{1}=subj_name;

% disp('** 1. Select edf data(.edf data)**')
% 
% 
% edf_name = uigetfile( '*.edf', 'MultiSelect', 'on');  % Select edf data file. 
%  subName{1}= edf_name{1}(3:5);

%cd(oldDir);

    data_type = iscell(edf_name);
    if data_type == 0;
        num_data = 1;
    elseif data_type ==1;
        num_data = size(edf_name,2);
    end
    
     if Auto == 0
        rv = 0;
    elseif Auto == 1
        rv = Sac_thrhold;
     elseif Auto ==2
         rv = (-1)*Sac_thrhold;
    end
    
    
fileName =sprintf('Combine_data_%s_%s_(%d-%d)_%04d%02d%02d.mat',subName{1},num2str(rv), pre,post, t.Year, t.Month, t.Day);



cd(oldDir);
if ~exist(fullfile(oldDir,fileName))
    
    %% ------2. Using edf tool; To load edf files and exactract timepoints
    drawGraph =0;
%    drawGraph =1;
    
    hxvel_Target_W = []; hxvel_Cue_W =[]; hyvel_Target_W = []; hyvel_Cue_W =[];
    gx_Target_W=[]; gx_Cue_W=[]; gy_Target_W=[]; gy_Cue_W=[];
    for i = 1:num_data
        edf_file=edf_name{1,i};
        [hxvel_Target hxvel_Cue hyvel_Target hyvel_Cue gx_Target, gx_Cue, gy_Target,gy_Cue] = Edf_Tool_YL_ver03(rawDir2,edf_file,pre, post, drawGraph);
        hxvel_Target_W =[hxvel_Target_W; hxvel_Target];
        hxvel_Cue_W = [hxvel_Cue_W; hxvel_Cue];
        hyvel_Target_W =[hyvel_Target_W; hyvel_Target];
        hyvel_Cue_W = [hyvel_Cue_W; hyvel_Cue];
        gx_Target_W=[gx_Target_W;gx_Target]; gx_Cue_W=[gx_Cue_W;gx_Cue]; gy_Target_W=[gy_Target_W;gy_Target]; gy_Cue_W=[gy_Cue_W;gy_Cue];
        %     if data_type == 0;
        %         load(edf_name(1,:));
        %     elseif data_type ==1;
        %         load(edf_name{1,i});
        %     end
        %
        %            sz_data = size(data.xAcc,2);
        %            Eyedata = length(fieldnames(data)) ;% data containing 13 fields
        %     for ii = 1:sz_data
        %         DATA(sz_data*(i-1)+ii,1) = data.xBlock(1,ii);
        %         DATA(sz_data*(i-1)+ii,2) = data.xTrial(1,ii);
        %         DATA(sz_data*(i-1)+ii,3) = data.xCondition1(1,ii); % Validity
        %         DATA(sz_data*(i-1)+ii,4) = data.xCondition2(1,ii); % Duration condition
        %         DATA(sz_data*(i-1)+ii,5) = data.xCondition3(1,ii); % Not use
        %         DATA(sz_data*(i-1)+ii,6) = data.xCondition4(1,ii); % Not use
        %         DATA(sz_data*(i-1)+ii,7) = data.xDuration(1,ii);   % Duration
        %         DATA(sz_data*(i-1)+ii,8) =  data.xAcc(1,ii);
        %         DATA(sz_data*(i-1)+ii,9) = data.xAbsent(1,ii);
        %         if length(fieldnames(data)) == 13
        %             DATA(sz_data*(i-1)+ii,10) = data.xEndSaccad(1,ii);
        %             DATA(sz_data*(i-1)+ii,11) = data.xVisi(1,ii);
        %         end
        %     end
    end
    
    %% -------3. remove saccade
    disp(sprintf('\nhxvel Target'))
    tmpId_x_Target = Saccade_Remover_YL(hxvel_Target_W, pre, post,Auto,Sac_thrhold);
    disp('hxvel Cue')
    tmpId_x_Cue = Saccade_Remover_YL(hxvel_Cue_W, pre, post,Auto,Sac_thrhold);
    disp('hyvel Target')
    tmpId_y_Target = Saccade_Remover_YL(hyvel_Target_W, pre, post,Auto,Sac_thrhold);
    disp('hyvel Cue')
    tmpId_y_Cue = Saccade_Remover_YL(hyvel_Cue_W, pre, post,Auto,Sac_thrhold);
    close all;
    
    %% --- :수정 중 6/30 --> gx gy 좌표로 Visual angle 1도 벗어나는 것만 찾기. 
   %   필요한거: 정가운데 좌표 (Center x, Center Y) = (512,384) ( -->  if x > deg2pixel(1) &&  y > deg2pixel(1)   
   %                                        angleoff = 1;
   %                                    end 
    
      if ang > 0
            sac = [];
            Trials = size(gx_Target_W, 1);
            TimePoints = size(gx_Target_W, 2);
            eyelink_Center = [1024/2 ,768/2];
            angleoff=deg2pixel(ang);
            for tri = 1:Trials
                        TriOff =0;
               for t_p = 1:TimePoints
%                          eyedist_Tar = round(pdist([eyelink_Center; gx_Target_W(tri,t_p), gy_Target_W(tri,t_p)], 'euclidean'));
%                          eyedist_Cue = round(pdist([eyelink_Center; gx_Cue_W(tri,t_p), gy_Cue_W(tri,t_p)], 'euclidean'));
                         eyedist_Tar = round(pdist([eyelink_Center; gx_Target_W(tri,t_p), 768/2], 'euclidean')); %% horizontal angle만 생각하는 경우
                         eyedist_Cue = round(pdist([eyelink_Center; gx_Cue_W(tri,t_p), 768/2], 'euclidean'));
                         %%% horizontal angle만 생각하는 경우
                                   if  eyedist_Tar >  angleoff | eyedist_Cue >  angleoff % 1 degree off
                                       TriOff = 1;   
                                   end
                        data.xEyeoff(1,tri) = TriOff;

               end
            end 
        end

 
    %% -------------
    
    xSaccade_T = ones(1,size(hxvel_Target_W,1));
    xSaccade_T(tmpId_x_Target) = 0;
    sum(xSaccade_T);
    xSaccade_C = ones(1,size(hxvel_Cue_W,1));
    xSaccade_C(tmpId_x_Cue) = 0;
    sum(xSaccade_C);
    
    ySaccade_T = ones(1,size(hyvel_Target_W,1));
    ySaccade_T(tmpId_y_Target) = 0;
    sum(ySaccade_T);
    
    ySaccade_C = ones(1,size(hyvel_Cue_W,1));
    ySaccade_C(tmpId_y_Cue) = 0;
    sum(ySaccade_C);
    if Sti == 'TC'
        data.xSaccade1 = xSaccade_C+xSaccade_T;
        %disp(find(data.xSaccade1 >=1));
        data.xSaccade2 = ySaccade_C+ySaccade_T;
        %disp(find(data.xSaccade2 >=1));
        data.xSaccade = xSaccade_C+xSaccade_T+ySaccade_C+ySaccade_T;
        xSaccade= data.xSaccade ;
        disp(length(find(data.xSaccade >=1)));
        disp(length(find(data.xSaccade >=1))/984);
    elseif Sti =='T'
        data.xSaccade1 = xSaccade_T;
        %disp(find(data.xSaccade1 >=1));
        data.xSaccade2 = ySaccade_T;
        %disp(find(data.xSaccade2 >=1));
        data.xSaccade = xSaccade_T+ySaccade_T;
        xSaccade= data.xSaccade ;
        disp(length(find(data.xSaccade >=1)));
        disp(length(find(data.xSaccade >=1))/984);            
    elseif Sti == 'C' 
        data.xSaccade1 = xSaccade_C;
        %disp(find(data.xSaccade1 >=1));
        data.xSaccade2 = ySaccade_C;
        %disp(find(data.xSaccade2 >=1));
        data.xSaccade = xSaccade_C+ySaccade_C;
        xSaccade= data.xSaccade ;
        disp(length(find(data.xSaccade >=1)));
        disp(length(find(data.xSaccade >=1))/984);   
    end 

    %% ------4. Save DATA -----------
    if Save ==1
        if Auto == 0
            rv = 0;
        elseif Auto == 1
            rv = Sac_thrhold;
        elseif Auto ==2
            rv = (-1)*Sac_thrhold;
        end
        
%         cd(outDir);
        disp('** 3. Please put a subject name on Output data!**')
        %subName = inputdlg({'Subject Name'},'OutputDATA name',[1 50]);
        sprintf('Data name: Combine_edf_%s_%s_(%d-%d)_%04d%02d%02d',subName{1},num2str(rv), pre,post, t.Year, t.Month, t.Day)
        save(sprintf('Combine_edf_%s_%s_(%d-%d)_%04d%02d%02d',subName{1},num2str(rv), pre,post, t.Year, t.Month, t.Day), 'data');
        
    end
    cd(oldDir);
else
%     cd(outDir);
    disp('saccade data already exist')
    %disp(sprintf('Data name: Combine_edf_%s_%d_(%d-%d)_%04d%02d%02d',subName{1},rv, pre,post, t.Year, t.Month, t.Day));
    load(sprintf('Combine_edf_%s_%s_(%d-%d)_%04d%02d%02d',subName{1},num2str(rv), pre,post, t.Year, t.Month, t.Day));
    cd(oldDir);
    
end


