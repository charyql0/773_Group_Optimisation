global Vu rho eta nSections clearance B Re R Curve
Vu = 6;
R = 0.75;
Curve = @generator;
rho = 1.29;
eta = 0.6;
nSections = 15;
clearance = 0.1;
Re = 100000;
B = 5;
num_blades = 5;
airfoil = 'NACA2412';

[fx, success] = createSurrogate(airfoil, false, -10:1:12);
[result, x] = optimiseTurbineGivenShape(fx, num_blades);
disp(result)

%% Test evaluateTurbine on candidate designs
nTests = 20;
chord_ref = linspace(0.30, 0.14, nSections);
beta_ref  = linspace(40, 14, nSections) * pi/180;

% generate random candidate designs within bounds
candidates = rand(nTests, 2*nSections) .* ...
    ([chord_ref * 1.5, beta_ref + 10*pi/180] - [chord_ref * 0.5, beta_ref - 10*pi/180]) + ...
    [chord_ref * 0.5, beta_ref - 10*pi/180];

% add the optimised design as the first candidate
candidates(1, :) = x;

% preallocate recording arrays
powers       = zeros(nTests, 1);
successes    = false(nTests, 1);
runtimes     = zeros(nTests, 1);
failureCases = {};

for i = 1:nTests
    chord_i = candidates(i, 1:nSections);
    beta_i  = candidates(i, nSections+1:end);
    
    tic
    try
        [power, speed] = evaluateTurbine(fx, chord_i, beta_i);
        runtimes(i)  = toc;
        successes(i) = true;
        powers(i)    = power;
        speeds(i)    = speed;

        if isnan(power) || isinf(power)
            successes(i) = false;
            failureCases{end+1} = struct('index', i, 'design', candidates(i,:), 'reason', 'NaN/Inf power');
        end

    catch e
        runtimes(i)  = toc;
        successes(i) = false;
        powers(i)    = NaN;
        failureCases{end+1} = struct('index', i, 'design', candidates(i,:), 'error', e.message);
        warning('Design %d threw an error: %s', i, e.message);
    end
end

% Report results
fprintf('\n--- evaluateTurbine Test Report ---\n')
fprintf('Total designs tested : %d\n', nTests);
fprintf('Successful           : %d (%.1f%%)\n', sum(successes), 100*mean(successes));
fprintf('Failed               : %d\n', sum(~successes));
fprintf('Average runtime      : %.3f s\n', mean(runtimes));
fprintf('Max runtime          : %.3f s\n', max(runtimes));
fprintf('Mean power (success) : %.3f W\n', mean(powers(successes)));

if ~isempty(failureCases)
    fprintf('\nFailure cases:\n')
    for i = 1:numel(failureCases)
        fprintf('  Design %d', failureCases{i}.index);
        if isfield(failureCases{i}, 'error')
            fprintf(' - error: %s', failureCases{i}.error);
        end
        fprintf('\n')
    end
end

%% Test GA

airfoils = {'NACA0012', 'NACA2412'};

nRuns = 5;  % number of times to run GA per airfoil

for a = 1:numel(airfoils)
    airfoil = airfoils{a};
    fprintf('\n=== Testing GA with %s ===\n', airfoil);

    [fx, success] = createSurrogate(airfoil, false, -10:1:12);
    if ~success
        warning('Surrogate creation failed for %s, skipping', airfoil);
        continue
    end

    powers   = zeros(nRuns, 1);
    runtimes = zeros(nRuns, 1);
    results  = cell(nRuns, 1);

    for i = 1:nRuns
        fprintf('  Run %d/%d ... ', i, nRuns);
        tic
        try
            [result, x] = optimiseTurbineGivenShape(fx, num_blades);
            runtimes(i) = toc;

            % evaluate the result directly to get power
            chord_i = x(1:nSections);
            beta_i  = x(nSections+1:end);
            [power, speed] = evaluateTurbine(fx, chord_i, beta_i);

            powers(i)  = power;
            results{i} = result;
            fprintf('power = %.3f W, speed = %.1f RPM, time = %.1fs\n', ...
                power, speed, runtimes(i));

        catch e
            runtimes(i) = toc;
            powers(i)   = NaN;
            warning('Run %d failed: %s', i, e.message);
        end
    end

    % summary for this airfoil
    validPowers = powers(~isnan(powers));
    fprintf('\n  --- Summary for %s ---\n', airfoil);
    fprintf('  Successful runs : %d/%d\n',  numel(validPowers), nRuns);
    fprintf('  Best power      : %.3f W\n', max(validPowers));
    fprintf('  Mean power      : %.3f W\n', mean(validPowers));
    fprintf('  Std power       : %.3f W\n', std(validPowers));
    fprintf('  Mean runtime    : %.1f s\n', mean(runtimes));
    fprintf('  Max runtime     : %.1f s\n', max(runtimes));
end


%% Generator function

function RPM = generator(Q)
    if Q > 4.8
        % Outside the practical range for the generator.
        RPM = 314.0*Q-1200.0;
    elseif Q >= 0
        RPM = 1.25*(279-sqrt(77841.0-16000.0*Q));
    else
        % This is bad news, but allowing the generator to deal with
        % negative torque can help with convergence
        RPM = -generator(-Q);
    end
end