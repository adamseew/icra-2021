%MAIN
% Simulation of the Energy-Aware Dynamic Mission Planning Algorithm


%% Energy sim, input data

disp('[E    ] Energy sim');
disp('[  E> ] Input data');

% Fourier series order (see eq:fourier)
r = input('[   ? ] Fourier series order r: ');
if isempty(r)
    r = 3; % default order
end

% Characteristic time
xi = input('[   ? ] Characteristic time xi: ');
if isempty(xi)
    xi = 10; % Characteristic time
end

% The value of y from the sensor. This is the former mechanical energy; the
% former computational energy [i.e., the energy from the embedded
% companion is obtained from the modeling tool's csv file].
disp('[   $ ] Input sensor energy data [csv]');
[bn, folder] = uigetfile('.csv');
if bn == 0
    % default: data from the paparazzi simulation on 12/12/18 09:53:01
    % credit: Amit Ferencz Appel
    file = csvread('../../data/simulation1/pprz_energy.csv');
else
    file = csvread(fullfile([folder, bn]));
end

if bn == 0
    column = 1; % default column
else
    column = input('[   ? ] Which column contains energy: ');
end
    file = file(:, [column]);

if bn == 0
    ts = 200; % default time step
else 
    ts = input('[   ? ] At what time step [ms]: ');
end
ts = ts / 1000;
tf = ts * size(file, 1); % leaving here just for exemplification
t = 1:1:size(file, 1); % discretizing, use ts to get the original

meas = file;

clear column file tf;

% The value of the model from the modeling tool (powprof); former
% computational energy.
disp('[   $ ] Input computational energy data (from powprof) [csv]');
[bn, folder] = uigetfile('.csv');
if bn == 0
    file2 = csvread('../../data/simulation1/computational_energy.csv');
else
    file2 = csvread(fullfile([folder, bn]));
end

% Mission specification
disp('[   $ ] Input mission specification [csv]')
[bn, folder] = uigetfile('.csv');
if bn == 0
    file3 = csvread('../../data/simulation1/mission_specification.csv');
else
    file3 = csvread(fullfile([folder, bn]));
end

clear bn folder;

selection = 0;


%% Selection of subroutine
 
% Runs if one runs just MAIN instead of selectively running sections...

[indx] = listdlg ...
    (   'PromptString', {'Select a subroutine'}, ...
        'SelectionMode', 'single', 'ListString', ...
        { ...
            'OP1: fixed max controls, kf no animation', ...
            'OP2: fixed max controls, kf animation', ...
            'OP3: fixed max controls, akf no animation', ...
            'OP4: energy in fun. of estimation stop time, same as OP4', ...
            'OP5: variable controls (computations) same as OP4'
        }, ... 
        'ListSize', [350 150] ...
    );
selection = 1;

% Now comes these subroutines:


%% Energy sim, OP1

% Non animated simulation / fixed case: with no TEEs controls, and the 
% highest possible QoS controls at each time step

if or(selection == 0, indx == 1)

    OP1;

    disp('[  E> ] Plot of the results');
    disp('[   ! ] Dependencies: y, meas, gck, ts');

    figure;

    plot(t * ts, meas); %+ gck);
    hold on;
    plot(t * ts, y);
    hold off;

    legend('data', 'observer');
end


%% Energy sim, OP2

% Animated simulation rest same as OP1

if or(selection == 0, indx == 2)

    OP1;

    disp('[  E> ] Animation of the results');
    disp('[   ! ] Dependencies: y, meas, gck, ts');

    figure;

    for i=t
        plot(t(1:i) * ts, meas(1:i)); %+ gck(1:i));
        hold on;
        plot(t(1:i) * ts, y(1:i));
        hold off;
    
        legend('data', 'observer');
    
        pause(ts);
    end
end


%% Energy sim, OP3

% Simulation of adaptive KF. KF is activated only when the difference 
% between the output and measurement is greater or equal to epsilon rest 
% same as OP1

if or(selection == 0, indx == 3)

    OP3;

    disp('[  E> ] Plot of the results');
    disp('[   ! ] Dependencies: y, meas, gck, ts');

    figure;

    plot(t * ts, meas); %+ gck);
    hold on;
    plot(t * ts, y);
    hold off;

    legend('data', 'observer');
end

%% Energy sim, OP4

% Uses the state that evolves from different time instants on till the end  
% of the sim

if or(selection == 0, indx == 4)

    OP3;

    disp('[  E> ] Plot of the results');
    disp('[   ! ] Dependencies: y, meas, gck, ts');

    figure;
    
    % t * ts; time
    % meas; data
    % y; estimated
    
    yy = [];
    
    for i=10:10:t(end)
        [y1, q1] = evolve_sys(A, B, C, u, q(:,i-1), i:t(end));
        
        yy = [yy; i*ts sum(y1) + sum(y(1:i-1))];
    end
    
    
    line([0 t(end)*ts], [sum(meas) sum(meas)]);
    hold on;
    bar(yy(:,1), yy(:,2));
    hold off;
    
    csvwrite([yy(:,1) yy(:,2) ones(size(yy,1),1)*sum(meas)], '../data/simulation2/est_vs_joules.csv');
    
end

%% Energy sim, OP5

if or(selection == 0, indx == 5)

    OP5;

    disp('[  E> ] Plot of the results');
    disp('[   ! ] Dependencies: y, meas, gck, ts');

    figure;

    plot(t * ts, meas); %+ gck);
    hold on;
    plot(t * ts, y);
    hold off;

    legend('data', 'observer');
end
