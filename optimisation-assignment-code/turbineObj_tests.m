% TESTTURBINEOBJ Test script for turbineObj using sample design
clear; clc; close all;

global Vu rho eta nSections clearance B Re R Curve 

% Global var.s from evaluate turbine
Vu = 5;             % Design speed, e.g. 5 m/s
R = 0.75;           % Outside radius of the turbine
Curve = @generator; % Function relating torque to RPM of the generator
rho = 1.29;         % Density of air
eta = 0.6;          % System efficiency
nSections = 15;     % Number of sections to divide the blade into for BEM calculations.
clearance = 0.1;    % Radius of hub + any further distance with no blade section allowed.
B = 5;              % Number of blades
Re = 100000;         % Approximate Reynolds number for design

% --- Build surrogate ---
airfoil = 'NACA0012';
[fx, success] = createSurrogate(airfoil, false, -10:1:12);

if ~success
    error('Could not build surrogate.');
end

% --- Sample design from handout ---
chord = linspace(0.30, 0.14, nSections);
beta  = linspace(40, 14, nSections) * pi/180;
design = [chord, beta];


% --- Run objective function ---
obj = turbineObj(design, fx);

fprintf('Objective value (negative weighted power) = %.6f\n', obj);

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
%%
% The objective function evaluates turbine performance across multiple wind 
% speeds (4, 5, 6, and 7 m/s) using corresponding weightings of 0.25, 0.45, 
% 0.20, and 0.10. 
% 
% For each wind speed, an RPM-based rule is applied:
% 
% - If RPM < 0, the contribution is set to 0
% - If 0 ≤ RPM ≤ 200, the full power is used
% - If 200 < RPM < 250, the contribution is reduced linearly to 0
% - If RPM ≥ 250, the contribution is set to 0
% 
% The objective function represents the weighted performance of the turbine
%  across multiple wind speeds. Each wind speed contributes to the total 
% performance based on its assigned weighting, with higher weights 
% indicating more important operating conditions. The RPM constraint 
% ensures that designs operating outside the practical rotational speed 
% range are penalised, reducing their contribution to the objective. By 
% minimising the negative weighted power, the optimisation effectively
%  seeks to maximise the overall extracted power while maintaining feasible 
% operating speeds.