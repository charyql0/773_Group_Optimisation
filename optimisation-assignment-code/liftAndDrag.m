function [alpha, Cl, Cd] = liftAndDrag(varargin)
% This function evaluates a turbine design, given a set of properties in a
% format suitable for optimisation using metaheuristics.
% 1 Input:  x - either a string that contains the ONE aerofoil type to be
%               used, or else a cell array that contains the aerofoil type
%               at each cross-section.
%            -- OR --
% 4 Inputs: for aerofoil information already found from elsewhere
%           Inputs must be in correct order. 
%           1. x = 1 x n matrix containing the sequence number (1...k) of the 
%                aerofoil to be used at each section. n == nSections
%           2. CL = 1 x k matrix containing lift coefficient for each of k
%           aerofoils
%           3. CD = 1 x k matrix containing drag coefficient at optimal angle
%           of attack for each of k aerofoils.
%           4. alpha = 1 x k matrix containing optimal angle of attack for
%           each of k aerofoils
% Outputs:  alpha - A 1D array of length nSections, containing the optimal
%                 angle of attack for the aerofoil present at each section
%           Cl - A 1D array of length nSection, containing the lift
%                 coefficient C_l at the optimal angle of attack for the
%                 aerofoil at that section
%           Cd - A 1D array of length nSection, containing the drag
%                 coefficient C_d at the optimal angle of attack for the
%                 aerofoil at that section
%
% Note: xFoil takes a long time to run! We shouldn't call it more than
% neccessary!

global nSections Re

if nargin == 1
    x = varargin{1};
    
    % Get aerofoil data.
    if isa(x, 'cell') % We have multiple aerofoils
        alphas = 0:1:15;

        % iterate over unique aerofoils and caluclate Cl, Cd, alpha for
        % each
        [unique_aerofoils, ~, ind] = unique(x);

        % preallocate angles
        optimal_alphas = zeros(length(unique_aerofoils));
        optimal_Cl = zeros(length(unique_aerofoils));
        optimal_Cd = zeros(length(unique_aerofoils));

        for i = 1:length(unique_aerofoils)
            
            [pol, ~] = callXfoil(unique_aerofoils{i}, alphas, Re, 0);

            % extract lift and drag, use to calculate optimal angle
            Cl = pol.CL;
            Cd = pol.CD;

            [~, max_ind] = max(Cl ./ Cd);
            optimal_alphas(i) = alphas(max_ind) * pi / 180;
            optimal_Cl(i) = Cl(max_ind);
            optimal_Cd(i) = Cd(max_ind); 
        end

        % map values back into array with entry for each section
        alpha = transpose(optimal_alphas(ind));
        Cl = transpose(optimal_Cl(ind));
        Cd = transpose(optimal_Cd(ind));
        
    else % We have a single aerofoil

        % call xfoil for the given aerofoil
        alphas = 0:1:15;
        [pol, ~] = callXfoil(x, alphas, Re, 0);
        
        % extract lift and drag, use to calculate optimal angle
        Cl = pol.CL;
        Cd = pol.CD;

        [~, max_ind] = max(Cl ./ Cd);
        optimal_alpha = alphas(max_ind) * pi / 180;
        optimal_Cl = Cl(max_ind);
        optimal_Cd = Cd(max_ind);

        % create arrays with one entry for each section
        alpha = optimal_alpha * ones(1, nSections);
        Cl = optimal_Cl * ones(1, nSections);
        Cd = optimal_Cd * ones(1, nSections);
    end   
elseif nargin == 4
    % Aerofoil info already pre-generated and is read in.
    x = varargin{1};
    LiftCoeffs = varargin{2};
    DragCoeffs = varargin{3};
    Alphas = varargin{4};

    % preallocate arrays
    alpha = zeros(1, length(x)); 
    Cl = zeros(1, length(x));
    Cd = zeros(1, length(x));

    % iterate over sections, allocate correct values for each
    for i = 1:length(x)
        Cl(i) = LiftCoeffs(x(i));
        Cd(i) = DragCoeffs(x(i));
        alpha(i) = Alphas(x(i));
    end
    
else
    error("Incorrect number of inputs")
end

end