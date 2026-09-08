%% perform hilbert transformation
clear;clc;close all;
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

fieldtripRoot = getenv('FIELDTRIP_ROOT');
if ~isempty(fieldtripRoot)
    addpath(fieldtripRoot);
end
ft_defaults;

%% Data loading

rawDir = fullfile(projectRoot, '01_Data', '02_BehavioralData');
dataDir = fullfile(projectRoot, '01_Data', '06_PhaseAlign');

if (~exist(dataDir,'dir'))
    mkdir(dataDir)
end

data_selected = uigetfile(fullfile(rawDir, '*.mat'), ...
    'Select behavior rawdata_anl file.', 'MultiSelect', 'on');
if isequal(data_selected, 0)
    return;
end
if ischar(data_selected)
    data_selected = {data_selected};
end


for i = 1: length(data_selected)
    data_name = data_selected{i};
    load(fullfile(rawDir, data_name));


    %% Hilbert
    [nSubj, nTimepoint] = size(Group_data);
    padding_length = nTimepoint;
    time = 1:nTimepoint; % Adjust time axis based on actual sampling frequency

    % Initialize storage for instantaneous phase
    instantaneous_phase = zeros(size(Group_data));

    % Loop through each subject
    for subj = 1:nSubj
        % Extract the signal for the current subject        
        signal = Group_data(subj, :);
        p = polyfit(time, signal, 2);
        trend = polyval(p, time);
        signal = signal - trend;        
        flip_signal = flip(signal);
        
        % Add zero-padding to the signal
        padded_signal = [flip_signal signal flip_signal signal flip_signal signal flip_signal];

        % Apply bandpass filter using ft_preproc_bandpassfilter
        filtered_padded_signal = ft_preproc_bandpassfilter(padded_signal, 100, [2.8 7.2]);
    
        % Remove the padding after filtering
        filtered_signal = filtered_padded_signal(padding_length*3 +1:end-padding_length*3);

    
        % Compute the analytic signal using ft_preproc_hilbert
        analytic_padded_signal = ft_preproc_hilbert(filtered_padded_signal, 'complex');
        
        analytic_signal = analytic_padded_signal(padding_length*3 +1:end-padding_length*3);


        % Compute the instantaneous phase
        instantaneous_phase(subj, :) = angle(analytic_signal);
       
    end
    close all
    save(fullfile(dataDir,data_name),'instantaneous_phase');
end

