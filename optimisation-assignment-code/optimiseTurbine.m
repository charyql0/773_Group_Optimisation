function results = optimiseTurbine()
% OPTIMISETURBINE Outer-loop scaffold for comparing candidate airfoils.
%
% Suggested core steps:
%   1. choose a small list of candidate airfoils
%   2. build a surrogate for each one
%   3. call optimiseTurbineGivenShape
%   4. store the best result for each airfoil
%   5. identify the best overall candidate

% TODO: implement this file.
% Keep the core case simple:
%   - one blade count, e.g. B = 5
%   - one constant airfoil shape across the blade
%   - basic error handling if surrogate construction fails

% Initialise global variables for evaluation functions
global Vu rho eta nSections clearance B R Curve

% Suggested starting list:
airfoil_candidates = {
    'NACA0012', ...
    'NACA2412', ...
    'NACA4415'
};

% Set the fixed blade count, keeping it to simple one blade count
num_blades = 5;
B = num_blades; % Ensure to set to global B, if different

% Initialise variables to keep track of the best design
best_overall_power = -Inf;
best_overall_airfoil = '';

% Initialise an array of structures to store results for all candidates
% Storing chord and beta as it may come in handy for report.
results = struct('airfoil', {}, 'power', {}, 'chord', {}, 'beta', {});

% Loop through each candidate airfoil
for i = 1:length(airfoil_candidates)
    current_airfoil = airfoil_candidates{i};
    
    try % Basic error handling if surrogate construction fails
        % Build a surrogate for the current airfoil
        [fx, success] = createSurrogate(current_airfoil, false, -10:1:12);
        
        % Call optimiseTurbineGivenShape
        [inner_result, x] = optimiseTurbineGivenShape(fx, num_blades);
        
        % Store the best result for this airfoil
        results(i).airfoil = current_airfoil;
        results(i).power = inner_result.power;
        results(i).chord = inner_result.chord;
        results(i).beta = inner_result.beta;
        
        fprintf('Optimal weighted power for %s: %.3f W\n\n', current_airfoil, inner_result.power);
        
        % Check if this is the best overall candidate so far
        if inner_result.power > best_overall_power
            best_overall_power = inner_result.power;
            best_overall_airfoil = current_airfoil;
        end

    catch ME
        fprintf('Error during optimisation for %s: %s\n', current_airfoil, ME.message);
        fprintf('Skipping to the next airfoil.\n\n');
    end

end

% Best overall design
fprintf('Optimisation Complete:\n');
fprintf('Best overall airfoil: %s\n', best_overall_airfoil);
fprintf('Maximum weighted power: %.3f W\n', best_overall_power);
end
