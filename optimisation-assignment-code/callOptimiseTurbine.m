clc;
clear;

fprintf('--- Testing optimiseTurbine ---\n');

try
    results = optimiseTurbine();

    fprintf('\n--- Optimisation Completed ---\n');

    if isempty(results)
        fprintf('No valid results were returned.\n');
        return;
    end

    % Display each airfoil result
    for i = 1:length(results)
        fprintf('\nCandidate %d\n', i);
        fprintf('Airfoil: %s\n', results(i).airfoil);
        fprintf('Power: %.4f\n', results(i).power);
    end

    % Find best overall candidate
    [~, bestIdx] = max([results.power]);

    fprintf('\n=== BEST OVERALL DESIGN ===\n');
    fprintf('Airfoil: %s\n', results(bestIdx).airfoil);
    fprintf('Power: %.4f\n', results(bestIdx).power);

    fprintf('Best chord distribution:\n');
    disp(results(bestIdx).chord);

    fprintf('Best beta distribution:\n');
    disp(results(bestIdx).beta);

catch ME
    fprintf('\nError during optimiseTurbine:\n%s\n', ME.message);
end
