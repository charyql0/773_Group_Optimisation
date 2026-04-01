% TESTCREATESURROGATE Basic check for the provided surrogate code.
clear all; close all; clc;

airfoil = 'NACA0012';
default_range = -10:1:12;
wide_range = -15:1:15;
alpha_test_deg = -25:0.5:25;
alpha_test_rad = alpha_test_deg * pi/180;

fprintf('Testing createSurrogate for %s\n', airfoil);

[fx_default, success_default] = createSurrogate(airfoil, false, default_range);
[fx_wide, success_wide] = createSurrogate(airfoil, false, wide_range);

if ~success_default || ~success_wide
    error('Could not build the requested surrogate(s). Check your XFOIL setup first.');
end

[CL_default, CD_default] = fx_default(alpha_test_rad);
[CL_wide, CD_wide] = fx_wide(alpha_test_rad);


figure('Position', [100, 100, 950, 420]);

subplot(1,2,1);
pos1 = get(gca, 'Position');
pos1(2) = pos1(2) + 0.02;   % move up
set(gca, 'Position', pos1);
plot(alpha_test_deg, CL_default, 'b-', 'LineWidth', 2); hold on;
plot(alpha_test_deg, CL_wide, 'r--', 'LineWidth', 2);
% Mark training range limits
xline(min(default_range), '--b', 'LineWidth', .5);
xline(max(default_range), '--b', 'LineWidth', .5);
xline(min(wide_range), '--r', 'LineWidth', .5);
xline(max(wide_range), '--r', 'LineWidth', .5);

grid on;
xlabel('Angle of attack (deg)');
ylabel('C_L');
title(['Lift coefficient - ' airfoil]);
legend('default range', 'wider range', 'Location', 'best');

subplot(1,2,2);
pos2 = get(gca, 'Position');
pos2(2) = pos2(2) + 0.02;   % move up
set(gca, 'Position', pos2);

plot(alpha_test_deg, CD_default, 'b-', 'LineWidth', 2); hold on;
plot(alpha_test_deg, CD_wide, 'r--', 'LineWidth', 2);
% Mark training range limits
xline(min(default_range), '--b', 'LineWidth', .5);
xline(max(default_range), '--b', 'LineWidth', .5);
xline(min(wide_range), '--r', 'LineWidth', .5);
xline(max(wide_range), '--r', 'LineWidth', .5);
grid on;
xlabel('Angle of attack (deg)');
ylabel('C_D');
title(['Drag coefficient - ' airfoil]);
legend('default range', 'wider range', 'Location', 'best');

annotation('textbox', [0 0 1 0.05], ...
    'String', 'Note: Dashed vertical lines indicate training range limits (blue: default, red: wider).', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center');

fprintf('\nSample values at 5 degrees:\n');
[cl_default_5, cd_default_5] = fx_default(5*pi/180);
[cl_wide_5, cd_wide_5] = fx_wide(5*pi/180);
fprintf('  default range: CL = %.4f, CD = %.4f\n', cl_default_5, cd_default_5);
fprintf('  wider range:   CL = %.4f, CD = %.4f\n', cl_wide_5, cd_wide_5);

fprintf('\nNote: createSurrogate takes angle ranges in degrees, but fx expects radians.\n');


%%

% #5: briefly comment on what you observe

% Between -10° and 12°, where both surrogates are trained, the two models 
% produce almost identical results, indicating reliable interpolation. 
% Outside this range, the results begin to diverge, as the default 
% surrogate is extrapolating while the wider-range surrogate remains within 
% its training bounds up to -15° and 15°. Beyond -15° and 15°, both models 
% are extrapolating and therefore become less reliable. This demonstrates 
% that surrogate accuracy strongly depends on the range over which it is 
% constructed.