function obj = turbineObj(design, fx)
% TURBINEOBJ Objective-function scaffold for the optimisation assignment.
%
% Core task:
%   - split design into chord and beta
%   - evaluate evaluateTurbine(fx, chord, beta) at wind speeds [4 5 6 7]
%   - use weights [0.25 0.45 0.20 0.10]
%   - apply the RPM rule from the handout
%   - return the negative weighted power

global Vu nSections

chord = design(1:nSections);
beta = design(nSections+1:end);

wind_speeds = [4.0, 5.0, 6.0, 7.0];
weightings = [0.25, 0.45, 0.20, 0.10];
weighted_power = 0.0;

Vu_before = Vu;

% Test lines
%fprintf('--- turbineObj breakdown ---\n');

for i = 1:length(wind_speeds)
    Vu = wind_speeds(i);
    % TODO:
    % 1. call evaluateTurbine(fx, chord, beta)
    
    % evaluateTurbine currently returns:
    %   obj   = extracted power
    %   speed = RPM
    [power_extracted, rpm] = evaluateTurbine(fx, chord, beta);
    

    % 2. apply the RPM rule from the assignment handout
    if rpm < 0
        contribution = 0;

    elseif rpm <= 200
        contribution = power_extracted;

    elseif rpm < 250
        % Reduce linearly from full contribution at 200 RPM to 0 at 250 RPM
        scale = (250 - rpm) / 50;
        contribution = power_extracted * scale;
    else
        contribution = 0;
    end     

    % 3. add the weighted contribution to weighted_power
    weighted_power = weighted_power + contribution * weightings(i);
    
    % Test lines
    %fprintf('Vu = %.1f | power = %.6f | rpm = %.6f | contribution = %.6f | weighted term = %.6f\n', ...
    % Vu, power_extracted, rpm, contribution, contribution* weightings(i));
end

% after calculating weighted_power, before returning obj

% smoothness penalty - penalise large changes between adjacent sections
chord_penalty = sum(diff(chord).^2);
chord_penalty2 = sum(diff(diff(chord)).^2); 
beta_penalty  = sum(diff(beta).^2);

% scale factors control how strongly smoothness is enforced
lambda_chord1 = 100;
lambda_chord2 = 70;
lambda_beta  = 30;

smoothness_penalty = lambda_chord1 * chord_penalty + lambda_chord2 * chord_penalty2 + lambda_beta * beta_penalty;

Vu = Vu_before;
obj = -weighted_power + smoothness_penalty;

% error('turbineObj:NotImplemented', 'Complete turbineObj.m before using it in optimisation.');
end

