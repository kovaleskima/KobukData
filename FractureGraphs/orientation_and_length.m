%%%%%%%%%%%%%%%
% ORIENTATION %
%%%%%%%%%%%%%%%
% computes the orientation of a line segment spanning the first and last coordinates of a crack in degrees
% p1 and p2 are points in a line segment of the form [lat, lon]
function o = orientation(p1, p2)
    x = haversine(p1, [p1(1), p2(2)]); %lon changes
    y = haversine(p1, [p2(1), p1(2)]); %lat changes
    o = atan2(y,x); 
end

%%%%%%%%%%
% LENGTH %
%%%%%%%%%%
% computes the length of a crack by summing the length of its line segments
% A is a crack consisting of [lat,lon] coordinate pairs
function l = length_sum(A)
    n = length(A);
    l = 0;
    for i = 1:n-1
        p1 = A(i,:);
        p2 = A(i+1,:);
        l = l  + haversine(p1, p2);
    end
end

%%%%%%%%%%%%%%%%%%%%%
% HAVERSINE FORMULA %
%%%%%%%%%%%%%%%%%%%%%
% computes the distance between two points of the form [lat,lon]
% returns d in km
function d = haversine(p1, p2)
    R = 6371; %km
    a = sin((p2(1)-p1(1))/2).^2 + cos(p1(1))*cos(p2(1)) * sin((p2(2)-p1(2))/2).^2;
    d = 2 * R * a * sin(sqrt(a));
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
    coords = fliplr(data.(keys{i}));
    if iscell(coords)
        crack_coords{i} = cell2mat(coords); % Nx2 [lat lon]
    else
        crack_coords{i} = coords;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ORIENTATION, LENGTH AND PLOTTING %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% computes crack orientations in degrees for all cracks in dataset
% plots these on a scatterplot where x is the crack index, y is orientation
% computes crack lengths as a sum of the length of line segments in crack
% plots these on a scatterplot where x is the crack index, y is the length

crack_orientations = zeros(1,n);
crack_lengths = zeros(1,n);
for i = 1:n
    A = crack_coords{i};
    crack_lengths(i) = length_sum(A);
    p1 = A(1,:);
    p2 = A(length(A),:);
    crack_orientations(i) = orientation(p1, p2) * 360/(2*pi);
end

x = linspace(1,n,28);
figure;
scatter(x, crack_orientations)
xlabel = "Cracks 1-28";
ylabel = "Orientation in Degrees";

figure;
scatter(x, crack_lengths)
xlabel = "Cracks 1-28";
ylabel = "Length in km";
