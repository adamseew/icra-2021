%OP2
% Simulation of the Energy-Aware Dynamic Mission Planning Algorithm
%
% 3D, 2D, and vector field simulations from a paparazzi autopilot logs,
% possibly animated

%% Build the model

fprintf(['[ OP1 ] 3D, 2D, and vector field simulations from a paparazzi\n' ... 
         '        autopilot logs, possibly animated\n']);

ah = input('[   ? ] Battery capacity [Ah]: ');
if isempty(ah)
    ah = 2.5; % default battery capacity (2500 mAh)
end
     
% retriving paparazzi log
disp('[   $ ] Input Paparazzi autopilot log [data]');
[bn, folder] = uigetfile('.data');
if bn == 0
    % default: data from the paparazzi simulation on 12/12/18 09:53:01
    % credit: Amit Ferencz Appel
    [p w segments circles] = ...
        load_pprz('../../data/simulation1/18_12_12__09_53_01_SD.data', ah);
else    
    [p w segments circles] = ...
        load_pprz(fullfile([folder, bn]), ah);
end

answer = inputdlg({'Mission started [s]:', 'Mission stopped [s]:'}, ...
                   'Mission time', [1 35], {'0', sprintf('%.2f',p(end, 1))} ...
                 );

if isempty(answer)
    strp = [680; 1000];
else
    strp = str2double(answer);
end

clear answer;

% filter data about the cruise (default are ~ 490.5->1226)
p(p(:, 1) < strp(1), :) = [];
p(p(:, 1) > strp(2), :) = [];

w(w(:, 1) < strp(1), :) = [];
w(w(:, 1) > strp(2), :) = [];

segments(segments(:, 1) < strp(1), :) = [];
segments(segments(:, 1) > strp(2), :) = [];

circles(circles(:, 1) < strp(1), :) = [];
circles(circles(:, 1) > strp(2), :) = [];

% normalizing and merging
% units are now: x, y (utm normalized in cm), altitude (cm)
% so it's expressed in cm, meaning this is the way to get in in meters
% data from NAV, so no more normalization needed... Except for height
%p(:, 2) = p(:, 2) - min(p(:, 2));
%p(:, 3) = p(:, 3) - min(p(:, 3));
%p(:, 2) = p(:, 2) / 100;
%p(:, 3) = p(:, 3) / 100;
p(:, 4) = p(:, 4) / 100;

min_ = min(min(p(:, 2)), min(p(:, 3)));
max_ = max(max(p(:, 2)), max(p(:, 3)));

% Here is the part that takes care of the vector field vector field
% create all the points I want to use to build gdn
[xp yp] = meshgrid( ...
    min_:(abs(min_) + abs(max_)) / 50:max_, min_:(abs(min_) + abs(max_)) / 50:max_);
points = reshape(cat(2, xp', yp'), [], 2);
clear xp yp;

min_ = [min(p(:, 2)), min(p(:, 3))];
max_ = [max(p(:, 2)), max(p(:, 3))];

E = [0 1; -1 0];
ke = input('[   ? ] Gain to adjust speed of convergence: ');
if isempty(ke)
   ke = 1.5 * 10^-3; % default gain to adjust speed of convergence
end


disp('[   ! ] The simulation with the animation takes a lot of time');

%%  Plots

delay = p(2, 1) - p(1, 1);
    
animation = - 1;
gif = [];

if strcmp(questdlg('Show the animation?', 'Animate', 'Yes', 'No', 'Yes'),...
           'Yes'...
         )
    animation = 0;
     
    if strcmp(questdlg('Save animation?', 'Save', 'Yes', 'No', 'Yes'),...
                'Yes'...
              )
        gif = input('[   ? ] Name of the gif: ');
        if isempty(gif)
            gif = 'animation.gif'; % default name
        end
    end
     
     syms x y;
end

h = figure;

for i=1:size(p(:, 1))
    
    if animation == -1
        i = size(p(:, 1), 1);
    end
    
    subplot(2, 2 + animation, [1 2 + animation]);
    
    plot3(p(1:i, 2), p(1:i, 3), p(1:i, 4));
    xlim([min_(1) max_(1)]);
    ylim([min_(2) max_(2)]);
    zlim([0 max(p(:, 4))]);
    
    if animation == -1
        title([datestr(p(1, 1) / (24 * 60 * 60), 'HH:MM:SS') ...
               ' -> ' ... 
               datestr(p(i, 1) / (24 * 60 * 60), 'HH:MM:SS')]);
    else
        title(datestr(p(i, 1) / (24 * 60 * 60), 'HH:MM:SS'));
            set(gcf, 'position', [10 10 1000 1000]);
            set(gcf, 'color', 'w');
            axis tight manual; % this ensures that getframe() returns a  
                               % consistent size
    end
    
    subplot(2, 2 + animation, 3 + animation);
    
    plot(p(1:i, 2), p(1:i, 3));
    xlim([min_(1) max_(1)]);
    ylim([min_(2) max_(2)]);
    
    if animation == -1
       break; 
    end
    
    subplot(2, 2, 4);
    
    if any(fix(circles(:, 1)) == fix(p(i, 1)))
        
        if and(i > 1, exist('circle') == 1)
            if circle == circles(fix(circles(:, 1)) == fix(p(i, 1)), 2:end)
                pause(delay);
                continue;
            end
        end
        
        circle = circles(fix(circles(:, 1)) == fix(p(i, 1)), 2:end);
        
        f = (x - circle(1))^2 + (y - circle(2))^2 - circle(3)^2;         
    end
    
    if any(fix(segments(:, 1)) == fix(p(i, 1)))
       
        if and(i > 1, exist('segment') == 1)
            if segment == segments(fix(segments(:, 1)) == fix(p(i, 1)), 2:end)
                pause(delay);
                continue;
            end
        end
        
        segment = segments(fix(segments(:, 1)) == fix(p(i, 1)), 2:end);
        
        if segment(1) == segment(3)
            f = x - segment(1);
        else
            f = (y - segment(2)) / (x - segment(1)) - ...
                (segment(4) - segment(2)) / (segment(3) - segment(1));
        end
    end
    
    [dpd, pdangle] = build_gdn2(E, ke, f, points);
    plot_gdn2(E, ke, f, points, pdangle, min(min_), max(max_), 0, 0, [0; 0]);
    xlim([min_(1) max_(1)]);
    ylim([min_(2) max_(2)]);
    
    hold off;
    
    if (~isempty(gif))
        drawnow
        
        frame = getframe(h);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im, 256);
    
        if i == 1 
            imwrite(imind, cm, 'figure1.gif', 'gif', 'Loopcount', inf);
        else 
            imwrite(imind, cm, 'figure1.gif', 'gif', 'WriteMode', 'append'); 
        end 
    
    end
    
    pause(delay);
    
end

