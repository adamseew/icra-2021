%MAIN
% Simulation of the Energy-Aware Dynamic Mission Planning Algorithm


%% Simulations selection

% Hint: use default values (just press enter when asked anything and don't 
% input any file)

% Hint: always good idea to start with a clear command

fprintf(['\t\t+---------------------------------------------+\n' ...
         '\t\t|            E A D M P A   S I M              |\n' ...
         '\t\t|    Energy-Aware Dynamic Mission Planning    |\n' ...
         '\t\t|            Algorithm Simulator              |\n' ...
         '\t\t+---------------------------------------------+\n\n']);%51
 
[indx] = listdlg ...
    (   'PromptString', {'Select a simulation'}, ...
        'SelectionMode', 'single', 'ListString', ...
        { ...
            'Simulator', ...
            'Energy', ...
            'Position ', ...
        }, ... 
        'ListSize', [180 60] ...
    );

if indx == 1
        
    fprintf(['\t\t             +---------------+\n' ...
             '\t\t             | The simulator |\n' ...
             '\t\t             +---------------+\n\n']);%21
    
    disp('[>    ] Invoking the simulator');
    SIM;    
elseif indx == 2
    
    fprintf(['\t\t             +-------------------+\n' ...
             '\t\t             | Energy simulation |\n' ...
             '\t\t             +-------------------+\n\n']);%21
    
    disp('[>    ] Invoking energy sim');
    cd energy;
    MAIN;
    cd ..;
elseif indx == 3
    
    fprintf(['\t\t            +---------------------+\n' ...
             '\t\t            | Position simulation |\n' ...
             '\t\t            +---------------------+\n\n']);%23
    
    disp('[>    ] Invoking position sim');
    cd position;
    MAIN;
    cd ..;
end

disp('[>    ] Sim done');
 
