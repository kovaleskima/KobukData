%%%%%%%%%%%%%%%
% ORIENTATION %
%%%%%%%%%%%%%%%
% computes the orientation of a line segment (crack) in degrees
% p1 and p2 are points in a line segment of the form [lat, lon]
function o = orientation(p1, p2)
    diff = p2 - p1;
    o = atan(diff(1),diff(2));
end

%%%%%%%%%%%%%
% LOAD DATA %
%%%%%%%%%%%%%
% Provide the path to data txt file from nccut containing crack segments
% Convert to JSON format for easy parsing in MATLAB
% Display keys to confirm the file contents
% Convert crack coordinates to Nx2 [lat, lon] arrays

filename = './Data/2022-06-04.txt';

fid = fopen(filename, 'r');
raw_text = fread(fid, '*char')';
fclose(fid);

json_like = raw_text;
json_like = strrep(json_like, '''', '"');
json_like = regexprep(json_like, '\(([^)]+)\)', '[$1]');

try
    data = jsondecode(json_like);
catch ME
    error('Failed to parse dictionary. Check input formatting.\n\n%s', ME.message);
end

keys = fieldnames(data);
n = length(keys);
disp('Loaded keys:');
disp(keys);

crack_coords = cell(n, 1);
for i = 1:n
    coords = data.(keys{i});
    if iscell(coords)
        crack_coords{i} = cell2mat(coords); % Nx2 [lat lon]
    else
        crack_coords{i} = coords;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ORIENTATION AND PLOTTING %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

crack_orientations = cell(n,1);
for i = 1:n-1
    A = crack_coords{i};
    p1 = A(1);
    p2 = A(length(A));
    crack_orientations{i} = orientation(p1, p2);
end

