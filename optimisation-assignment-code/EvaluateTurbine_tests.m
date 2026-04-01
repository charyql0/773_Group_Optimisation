global Vu rho eta nSections clearance B Re R Curve optimise_c

Vu = 5;             % Design speed, e.g. 5 m/s
R = 0.75;           % Outside radius of the turbine
Curve = @generator; % Function relating torque to RPM of the generator
rho = 1.29;         % Density of air
eta = 0.6;          % System efficiency
nSections = 15;     % Number of sections to divide the blade into for BEM calculations.
clearance = 0.1;    % Radius of hub + any further distance with no blade section allowed.
B = 5;              % Number of blades
Re = 100000;         % Approximate Reynolds number for design

[alpha, Cl, Cd] = liftAndDrag('NACA0012');
[obj1, design1] = BEM(alpha, Cl, Cd);
disp(obj1)
disp(design1)

try
    [PE, RPM] = evaluateTurbine(@fx, design1.chord, design1.beta);
catch Me
    disp(Me.message)
    PE = 'Error';
    RPM = 'Error';
end
disp(PE)
disp(RPM)

% ------------------------------
% Helpers functions
% ------------------------------

function [Cl, Cd] = fx(alpha)
% An example of a function that can approximate the lift and drag
% coefficient for an aerofoil. Example is a NACA0012 aerofoil, and we
% linearly interpolate between the coefficients at discrete values of alpha
if ~all(isreal(alpha))
    disp(alpha)
    error('Imaginary alpha, model has diverged')
end

ClIndex = [-0.8918;-0.9004;-0.8469;-0.7699;-0.6897;-0.6175;-0.5428;-0.4633;-0.3176;0.0034;0;-0.0034;0.3176;0.4633;0.5428;0.6175;0.6897;0.7699;0.8469;0.9005;0.8599;0.601;0.6321;0.6432;0.6728;0.6849;0.7148;0.7443;0.7748;0.8154;0.8396;0.8748;0.91;0.9409;0.9719;1.0034];

CdIndex = [0.06401;0.0479;0.03734;0.03005;0.02493;0.02158;0.02001;0.0198;0.02123;0.02071;0.01958;0.0207;0.02123;0.0198;0.02;0.02158;0.02493;0.03005;0.03734;0.0479;0.0664;0.1277;0.14283;0.15634;0.17041;0.18175;0.1944;0.20665;0.21869;0.23282;0.24201;0.25412;0.26623;0.27661;0.28666;0.2969];

alphaIndex = pi/180*(-10:25)';

Cl = interp1(alphaIndex, ClIndex, alpha, 'linear', 'extrap');
Cd = interp1(alphaIndex, CdIndex, alpha, 'linear', 'extrap');
end


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