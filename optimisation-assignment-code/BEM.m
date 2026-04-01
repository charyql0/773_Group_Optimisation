function [obj, design] = BEM(alpha, Cl, Cd)
% This function evaluates a turbine design, given a set of properties in a
% format suitable for optimisation using metaheuristics.
%
% Inputs:  alpha - A 1D array of length nSections, containing the optimal
%                 angle of attack for the aerofoil present at each section
%           Cl - A 1D array of length nSection, containing the lift
%                 coefficient C_l at the optimal angle of attack for the
%                 aerofoil at that section
%           Cd - A 1D array of length nSection, containing the drag
%                 coefficient C_d at the optimal angle of attack for the
%                 aerofoil at that section
% Outputs:  obj = objective value of interest, to be defined for the
%                 application. Usually, PE.
%           design = structure with turbine design features, specifically
%               r = cross-sectional radii
%               chord = chord length
%               Cp = power coefficient
%               alpha = angle of attack of aerofoil
%               beta = setting angle
%               RPM = RPM of the turbine spin
%               Q = torque of the turbine
%
% Zara Wong

% Constants (to go into params)
global Vu rho eta nSections clearance B R Curve optimise_c

r = linspace(clearance, R, nSections);

% YOUR CODE HERE

% funny loop thing :/
tolerance = 1e-4;
update_param = 0.3;

% starting estimate of lambda
lambda = 4;
lambda_diff = 1;

% starting guess for a and a_prime
old_a = 0.33 * ones(1,nSections);
old_a_prime = 0 * ones(1,nSections);

% set chord length
c = 0.5 / B * ones(1,nSections);

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

        phi = atan2((1 - old_a), denom);
        
        % chord length
        if optimise_c
            % limit c to have maximum solidity = 1
            new_c = (8 .* pi .* r) ./ (B .* Cl) .* (1 - cos(phi));
            new_c = min(new_c, (1 * 2 .* pi .* r) ./ B);

            % slow updates for stability
            c = c + update_param * (new_c - c);

        end
        
        % solidity, can't be bigger than 1
        solidity = (B .* c) ./ (2 .* pi .* r);
        solidity = min(solidity, 1);
        
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
            
        % update slowly
        updated_a = old_a + update_param .* (new_a - old_a);
        updated_a_prime = old_a_prime + update_param .* (new_a_prime - old_a_prime);

        % calculate differences to check if converged
        inner_convergence = all(abs(new_a - old_a) < tolerance) && all(abs(new_a_prime - old_a_prime) < tolerance);
    
        old_a = updated_a;
        old_a_prime = max(updated_a_prime, -1 + 1e-6);
    end

    % final converged a and a_prime
    a = updated_a;
    a_prime = updated_a_prime;
    
    % tangential load, avoid division by zero
    denom = 2 .* sin(phi).^2;
    denom(denom == 0) = eps;

    p_t = (rho .* Vu^2 .* (1 - a).^2 .* C_t .* c) ./ denom;
    
    % numerically integrate to find torque
    Q = trapz(r, p_t .* r) * B;
        
    % use torque and generator curve to find rpm then recalculate lambda
    new_lambda = (pi * R * Curve(Q)) / (30 * Vu);
    
    lambda_diff = abs(lambda - new_lambda);
    lambda = lambda + update_param .* (new_lambda - lambda);
end

power_extracted = Q * turbine_spin * eta;
wind_power = 0.5 * pi * rho * R^2 * Vu^3;

Cp = power_extracted / wind_power;

% return values
obj = power_extracted;

design.r = r;
design.chord = c;
design.Cp = Cp;
design.alpha = alpha;
design.beta = phi - alpha;
design.RPM = Curve(Q);
design.Q = Q;

return