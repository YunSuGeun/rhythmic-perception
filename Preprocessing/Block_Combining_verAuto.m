% 1. select the options
%     (1) stimulus (target, cue, or both), (2) Pre time range, (3) Post
%     time range, (4) Auto (5) Visual angle off (6) save or not 
%
% 2. load behavior data (you can select subjs)
%
% 3. combining behavior data and saccade data
% 4. sub script: (1) Saccade_Data_YL_ver02
%                    (1)-1 Edf_Tool_YL_ver03
%                    (1)-2 Saccade_Remover_YL


clear all; clc;


t = datetime('now');
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);


floor(now);
%% 1. data setting (select options,select data, setting Directory)
    disp('** 3. Please put a Folder name on Output data!**') 
    Name = inputdlg({'Ex1(1)? Ex2(2)?','Target(T)? or Target & Cue(TC)? or Cue(C)?','Before stimulus onset time range(pre;ms)','After stimulus onset time range(post;ms)','Semi auto(1)? Auto only (2) or no(0)?','remove_line(25-40)?','Remove Saccade(1)?','Visual angle','Output Folder Name'},'OutputDATA name',...
    [1 70; 1 70;1 70;1 70;1 70;1 70;1 70;1 70;1 70],{'Perception','TC','50','300','2','30','1' ,'1','CodeTest'});

Ex = Name{1}
Sti=Name{2};            % setting out which stimulus is potential saccade generator? 
pre=str2num(Name{3});   % setting the starts of time window for the onset time of saccade generator stimulus. 
post=str2num(Name{4});  % setting the end of time window for the onset time of saccade generator stimulus.
Auto=str2num(Name{5});  % 
Sac_thrhold=str2num(Name{6});   % Saccade thresholds(velocitiy) : usually 25~40 degree per sec ; Psychophysical configuration =22, Cognitive configuration = 30
                                % This reference from Eyelink 1000 User Manual p.99 (file:///Z:/younglae/Rhythmic_Attention/Rhythmic_Attention_CookBook/Analysis/Analysis_prep/EyeLinks_reference/EyeLink%201000%20User%20Manual%201.5.0.pdf)
ang=str2num(Name{8});   % Off crteria for eye gaze position (if eye gaze position is out of x degree from the fixation, will be removed)
Save=0;

rawDir = fullfile(projectRoot, '01_Data', '01_RawData', sprintf('Rhythm_%s', Ex), 'GoodData'); % Behavior data directory
Dir_edf = fullfile(projectRoot, '01_Data', '01_RawData', sprintf('Rhythm_%s', Ex), 'edf'); % edf data directory
addpath(Dir_edf);

saveDir = fullfile(projectRoot, '01_Data', '01_Preprocessed', 'CombinedData', sprintf('Rhythm_%s', Ex));

if ~exist(rawDir, 'dir')
    error('Behavior data directory not found: %s', rawDir);
end
if ~exist(Dir_edf, 'dir')
    error('EDF directory not found: %s', Dir_edf);
end


genDir2=Dir_edf;        % Directory for edf data/ used in "Saccade_Data_YL_ver02" function.  




oldDir = pwd; 

if strcmp(Ex,'WM')
    subj = {'cbu','csb','hdg','hjh','hzh','ihj','jhw','jjh','jsy','jyz','kdh','kdj','kgr','kis','kjh','kmj','ldh','lhg','lks','lms','luy','lyg','lyj','lzh','ngh','nsh','ssh','ysh','zjh'};% ex1 (31 subj)  
elseif strcmp(Ex, 'Perception')
    subj = {'bdm','chk','chw','cjm','cso','csy','djl','dwc','ghk','ghl','hwk','hys','iyz','jhp','jsi','khr','kih','Kim','kjc','kji','kjn','ksg','mjk','pby','pzh','shs','uyj','wji'}; % ex2 (29 subj)
end



NoS = length(subj); 

%% 2.  making Saving folder 

if ~exist(saveDir,'dir')
    mkdir(saveDir);
    addpath(saveDir);
end

%% 3. Combining data 
for m = 1:NoS
    subName{1}=subj{m};
    SubName_path = fullfile(rawDir,subj{m});
    cd(SubName_path); % moving to subj's behavioral data folder 
    addpath(SubName_path);
    
% 3-1 setting behavior data 
    behav_path = [SubName_path '/'];
    file_name = [sprintf('data_RetroCue_*.mat', subName{1})];
    behav_files = dir([behav_path  file_name]);
    behave_name = struct2cell(behav_files);

    
% 3-2 Extracting Saccade data using edf data     
    % whichCue = inputdlg({'Remove Saccade(1)?'},'Current Block', [1 70;],{'1'});
    Sac = str2num(Name{7});
    if Sac == 1
        subj_name = subj{m};
        cd(saveDir)
        genDir2=Dir_edf ;Sti=Name{2}; pre=str2num(Name{3});post=str2num(Name{4});Auto=str2num(Name{5});Sac_thrhold=str2num(Name{6}); ang=str2num(Name{8});Save=0;      
        Saccades =Saccade_Data_YL_ver02(genDir2, Sti ,pre,post,Auto,Sac_thrhold, ang,Save,subj_name); % [xSaccade] = Saccade_Data_YL(pre,post,Auto,remove_line, eye_angleOff,Save, subj_name)
        % This function is for making eye saccade data(loading edf data / counting saccade trials)  
        
        disp(length(find(Saccades.xSaccade>0)))
    end
    
% 3-3 combining behavior data with saccade data 
    for i = 1:size(behave_name,2)
        data = [];
        load(behave_name{1,i});
        sz_data = size(data.xAcc,2);
        Eyedata = length(fieldnames(data)) ;% data containing 13 fields
        for ii = 1:sz_data
            DATA(sz_data*(i-1)+ii,1) = data.xBlock(1,ii);
            DATA(sz_data*(i-1)+ii,2) = data.xTrial(1,ii);
            DATA(sz_data*(i-1)+ii,3) = data.xCondition1(1,ii); % Validity
            DATA(sz_data*(i-1)+ii,4) = data.xCondition2(1,ii); % Duration condition
            DATA(sz_data*(i-1)+ii,5) = data.xCondition5(1,ii); % Left Right 
            DATA(sz_data*(i-1)+ii,6) = data.xCondition4(1,ii); % whichCue  pre = 0, post =1
            DATA(sz_data*(i-1)+ii,7) = data.xDuration(1,ii);   % Duration
            DATA(sz_data*(i-1)+ii,8) = data.xAcc(1,ii);
            DATA(sz_data*(i-1)+ii,9) = data.xAbsent(1,ii);
            DATA(sz_data*(i-1)+ii,10) = 0;% data.xEndSaccad(1,ii);
            DATA(sz_data*(i-1)+ii,11) = data.xVisi(1,ii);
            DATA(sz_data*(i-1)+ii,12) = Saccades.xSaccade(1,ii);
            DATA(sz_data*(i-1)+ii,13) = Saccades.xEyeoff(1,ii);
            DATA(sz_data*(i-1)+ii,14) = data.xCondition3(1,ii); % Tar_ori
        end
    end
    
    
% 3-4 Saving 
    cd(saveDir);
    disp(sprintf('***Out put data: %s \n***Data number: %d', subName{1},m))
    save(sprintf('Combine_data_%s_%04d%02d%02d',subName{1}, t.Year, t.Month, t.Day), 'DATA');
    clear data DATA Saccades 
    rmpath(SubName_path);
end
