function [obj, speed] = evaluateTurbine(fx, c, beta)
% This function evaluates a turbine design, given a set of properties in a
% format suitable for optimisation using metaheuristics.
%
% Inputs:  f - A fast (er than xFoil) function that we return the lift and
%              drag coefficients of our aerofoil for a given angle of
%              attack
%           c - A 1D array of length nSections, containing the chord length
%               for each section
%           beta - a 1D array of length nSections, containing the blade
%                  setting angle for each section
% Outputs:  obj = objective value of interest, to be defined for the
%                 application. Usually, Cp.
%           speed = The RPM of the turbine
%
% Zara Wong

% Constants (to go into params)
global Vu rho eta nSections clearance B R Curve
r = linspace(clearance, R, nSections);

% funny loop thing :/
tolerance = 1e-6;
update_param = 0.1;

% starting estimate of lambda
lambda = 1;
lambda_diff = 1;

% starting guess for a and a_prime
old_a = 0.33 * ones(1,nSections);
old_a_prime = 0 * ones(1,nSections);

% outer loop calculates new speed until converges
while lambda_diff > tolerance
    turbine_spin = (Vu * lambda) / R;
    local_speed_ratio = (turbine_spin .* r) ./ Vu;
    
    % inner loop iterates over a and a_prime until converges
  
    % loop from here while a and a_prime not converged
    inner_convergence = false;
    while ~inner_convergence
      
        % local wind angle
        denom = local_speed_ratio .* (1 + old_a_prime);
        % don't allow to be zero
        denom(denom == 0) = eps;

        % calculate wind angle
        phi = atan((1 - old_a) ./ denom);

        % recalculate alpha and coefficients
        alpha = phi - beta;
        [Cl, Cd] = fx(alpha);
        
        % solidity, can't be bigger than 1
        solidity = (B .* c) ./ (2 .* pi .* r);
        %solidity = min(solidity, 1);
        
        % rotate lift and drag
        C_n = Cl .* cos(phi) + Cd .* sin(phi);
        C_t = Cl .* sin(phi) - Cd .* cos(phi);
        
        % update a and a_prime
        denom_a  = 4 .* sin(phi).^2 + solidity .* C_n;
        denom_a(abs(denom_a) < eps) = eps;
        new_a = (solidity .* C_n) ./ denom_a;
        
        new_a_prime = (solidity .* C_t) ./ (4 .* sin(phi) .* cos(phi) - solidity .* C_t);

        % stop singularity
        new_a_prime = max(new_a_prime, -1 + 1e-6);
        
        % check that a is within physical limits
        new_a = min(new_a, 0.5);
        new_a = max(new_a, 0);

        % calculate differences to check if converged
        inner_convergence = (max(abs(new_a - old_a)) < tolerance) && (max(abs(new_a_prime - old_a_prime)) < tolerance);
        
        % update slowly
        updated_a = old_a + update_param .* (new_a - old_a);
        updated_a_prime = old_a_prime + update_param .* (new_a_prime - old_a_prime);

        old_a = updated_a;
        old_a_prime = max(updated_a_prime, -1 + 1e-6);
    end

    % final converged a and a_prime
    a = updated_a;
    a_prime = updated_a_prime;

    % recompute values with final a, a_prime
    phi = atan((1 - a) ./ (local_speed_ratio .* (1 + a_prime)));
    alpha = phi - beta;
    [Cl, Cd] = fx(alpha);
    C_t = Cl .* sin(phi) - Cd .* cos(phi);
    
    % tangential load, avoid division by zero
    denom = 2 .* sin(phi).^2;
    denom(denom == 0) = eps;

    p_t = (rho .* Vu^2 .* (1 - a).^2 .* C_t .* c) ./ denom;
    
    % numerically integrate to find torque
    Q = trapz(r, p_t .* r) * B;
        
    % use torque and generator curve to find rpm then recalculate lambda
    new_lambda = (pi * R * Curve(Q)) / (30 * Vu);

    lambda_diff = abs(new_lambda - lambda);
    lambda = lambda + update_param .* (new_lambda - lambda);
end

% redo final calculation with final lambda
turbine_spin = (Vu * lambda) / R;
omega_final = Curve(Q) * pi / 30;

power_extracted = Q * omega_final * eta;
wind_power = 0.5 * pi * rho * R^2 * Vu^3;

Cp = power_extracted / wind_power;

% return values
obj = power_extracted;
speed = Curve(Q);

end

