clear all; clc;

t = datetime('now');
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);

experimentName = 'Perception';
input_folder = fullfile(projectRoot, '01_Data', '01_Preprocessed', 'CombinedData', sprintf('Rhythm_%s', experimentName));
output_folder = fullfile(projectRoot, '01_Data', '01_Preprocessed');

if ~exist(input_folder, 'dir')
    error('Input folder not found: %s', input_folder);
end
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

files = dir(fullfile(input_folder, '*.mat'));
if isempty(files)
    warning('No .mat files found in %s', input_folder);
end

for i = 1:length(files)
    file_path = fullfile(input_folder, files(i).name);
    data_struct = load(file_path);

    if isfield(data_struct, 'DATA')
        cleaned_data = clean_raw_data(data_struct.DATA);

        [~, name, ~] = fileparts(files(i).name);
        subjectToken = regexp(name, '^Combine_data_([^_]+)_', 'tokens', 'once');
        if isempty(subjectToken)
            subjectName = name;
        else
            subjectName = subjectToken{1};
        end

        outputName = sprintf('%s_%04d%02d%02d_cleaned.mat', subjectName, t.Year, t.Month, t.Day);
        output_file_path = fullfile(output_folder, outputName);
        save(output_file_path, 'cleaned_data');
    else
        warning('File %s does not contain a variable named DATA', files(i).name);
    end
end
