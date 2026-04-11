function [result, x] = optimiseTurbineGivenShape(fx, num_blades)
% OPTIMISETURBINEGIVENSHAPE Inner-loop scaffold for a fixed airfoil.
%
% Suggested steps:
%   1. set the usual global parameters (Vu, rho, eta, nSections, etc.)
%   2. set B = num_blades
%   3. choose lower and upper bounds for chord and beta
%   4. define objective = @(design) turbineObj(design, fx)
%   5. run ga (or another justified optimiser)
%   6. evaluate the best design across the chosen wind speeds
%   7. return the best design and a short summary in result

% A simple starting point is to use a smooth reference design such as:
%   chord_ref = linspace(0.30, 0.14, nSections);
%   beta_ref = linspace(40, 14, nSections) * pi/180;
%
% You may then build sensible bounds around that reference, or use bounds
% based on a BEM design from your previous assignment.

% Defines required global vars.
global Vu rho eta nSections clearance B R Curve

B = num_blades;

% set bounds
chord_ref = linspace(0.30, 0.14, nSections);
beta_ref  = linspace(40, 14, nSections) * pi/180;

% proportional chord bounds - scales naturally across sections
lb_chord = chord_ref * 0.3;
ub_chord = chord_ref * 1.7;

% absolute beta bounds - wide enough for camber differences between airfoils
lb_beta = beta_ref - 20*pi/180;
ub_beta = beta_ref + 20*pi/180;

lb = [lb_chord, lb_beta];
ub = [ub_chord, ub_beta];

% set objective function
objective = @(design) turbineObj(design, fx);

% set options and run ga
options = optimoptions('ga', ...
    'PopulationSize', 30, ...
    'MaxGenerations', 10, ...
    'MaxStallGenerations', 5, ...
    'FunctionTolerance', 1e-2, ...
    'MaxTime', 60, ...
    'Display', 'iter', ...
    'PlotFcn', {@gaplotbestf, @gaplotbestindiv});

nvars = 2 * nSections;
x = ga(objective, nvars, [], [], [], [], lb, ub, [], options);

chord_opt = x(1:nSections);
beta_opt  = x(nSections+1:end);

result = struct();
result.chord     = chord_opt;
result.beta      = beta_opt;
result.power     = -turbineObj(x, fx);

% TODO: implement this file.
% Some groups may find it helpful to:
%   - start with a smaller population / fewer generations
%   - seed the initial population near a smooth reference design
%   - tighten bounds if completely random designs behave badly

% error('optimiseTurbineGivenShape:NotImplemented', ...
%     'Complete optimiseTurbineGivenShape.m before using it.');
end
