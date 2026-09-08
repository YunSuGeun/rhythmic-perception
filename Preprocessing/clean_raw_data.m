%clean-rawdata

function clean_rawdata = clean_raw_data(DATA)
    % Initialize an empty array to hold the clean data
    clean_rawdata = [];

    % Iterate through each row in DATA
    for i = 1:size(DATA, 1)
        % Check if the 12th and 13th columns are both 0 %% 12th - sacccade
        % / 13th visual angle
%         if DATA(i, 12) == 0 && DATA(i, 13) == 0
%         if DATA(i, 12) == 0 
        if DATA(i, 13) == 0
            % Append the row to clean_rawdata
            clean_rawdata = [clean_rawdata; DATA(i, :)];
        end
    end
end

% Example usage:
% Assume DATA is already defined as a 984x14 array
% cleaned_data = clean_raw_data(DATA);
% disp(cleaned_data);
