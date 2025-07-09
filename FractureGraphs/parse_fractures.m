function intersects = cracksIntersect(A, B)
    intersects = false;
    for i = 1:size(A,1)-1
        p1 = A(i,:); p2 = A(i+1,:);
        for j = 1:size(B,1)-1
            q1 = B(j,:); q2 = B(j+1,:);
            if segmentsIntersect(p1, p2, q1, q2)
                intersects = true;
                return;
            end
        end
    end
end

function tf = segmentsIntersect(p1, p2, q1, q2)
    % Use vector cross product test for segment intersection
    % p1, p2, q1, q2 are 1x2 vectors: [lat lon] or [x y]

    % Convert to 2D points
    A = p1; B = p2; C = q1; D = q2;

    % Compute orientations
    o1 = orientation(A, B, C);
    o2 = orientation(A, B, D);
    o3 = orientation(C, D, A);
    o4 = orientation(C, D, B);

    % General case
    tf = (o1 ~= o2) && (o3 ~= o4);
end

function o = orientation(p, q, r)
    val = (q(2) - p(2)) * (r(1) - q(1)) - ...
          (q(1) - p(1)) * (r(2) - q(2));
    if abs(val) < 1e-10
        o = 0;  % colinear
    elseif val > 0
        o = 1;  % clockwise
    else
        o = 2;  % counterclockwise
    end
end


% Path to txt file
filename = './Data/2022-06-04.txt';

fid = fopen(filename, 'r');
raw_text = fread(fid, '*char')';
fclose(fid);

% Clean and convert Python syntax to MATLAB-compatible JSON-like format
json_like = raw_text;
json_like = strrep(json_like, '''', '"');
json_like = regexprep(json_like, '\(([^)]+)\)', '[$1]');

% Use JSON parser
try
    data = jsondecode(json_like);
catch ME
    error('Failed to parse dictionary. Check input formatting.\n\n%s', ME.message);
end

% Display keys
keys = fieldnames(data);
n = length(keys);
disp('Loaded keys:');
disp(keys);

% Begin figure
figure;
hold on;
title('Crack paths');
xlabel('Longitude');
ylabel('Latitude');
legend_entries = {};

% Loop through each crack and plot
for i = 1:n
    frac_key = keys{i};
    coords = data.(frac_key);  % Nx2 matrix: [lat, lon]
    
    % Extract lat and lon
    lat = coords(:,1);
    lon = coords(:,2);
    
    % Plot each crack
    plot(lon, lat, '-o', 'DisplayName', frac_key);  % plot lon vs lat
    legend_entries{end+1} = frac_key;
end

legend('show');
axis equal;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Step 1: Convert all cracks to lat/lon arrays and store them
crack_coords = cell(n, 1);
for i = 1:n
    coords = data.(keys{i});
    if iscell(coords)
        crack_coords{i} = cell2mat(coords); % Nx2 [lat lon]
    else
        crack_coords{i} = coords;
    end
end

% Step 2: Initialize adjacency matrix
adj = zeros(n);

% Step 3: Check for intersections between cracks
for i = 1:n-1
    A = crack_coords{i};
    for j = i+1:n
        B = crack_coords{j};

        % Check if crack i intersects crack j
        if cracksIntersect(A, B)
            adj(i, j) = 1;
            adj(j, i) = 1;
        end
    end
end

% Step 4: Build graph
G = graph(adj, keys);

% Step 5: Plot graph
figure;
plot(G, 'Layout', 'force');
title('Intersection Graph of Cracks');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure;
gx = geoaxes;
hold(gx, 'on');
title(gx, 'Crack Map with Intersections');
geobasemap(gx, 'satellite');

% Set geographic limits (latitude and longitude)
geolimits(gx, [66.4 67.1], [-162.2 -161.4]);

% Color for intersecting cracks
highlight_color = [1 0 0];  % red
default_color = [0.3 0.3 0.3];  % gray

% Determine which cracks are involved in intersections
connected_nodes = unique(G.Edges.EndNodes);

% Plot each crack
for i = 1:numel(crack_coords)
    lon = crack_coords{i}(:,1);
    lat = crack_coords{i}(:,2);

    if ismember(keys{i}, connected_nodes)
        % This crack intersects another → highlight
        geoplot(lat, lon, '-', 'LineWidth', 2, 'Color', highlight_color);
    else
        % Non-intersecting crack
        geoplot(lat, lon, '-', 'LineWidth', 1, 'Color', default_color);
    end
end

% Optional: Label cracks (at the midpoint)
for i = 1:numel(crack_coords)
    lat = crack_coords{i}(:,1);
    lon = crack_coords{i}(:,2);
    mid_idx = round(length(lat)/2);
    text(lat(mid_idx), lon(mid_idx), keys{i}, ...
        'FontSize', 8, 'HorizontalAlignment', 'center');
end