global nSections Re
nSections = 15;
Re = 100000;

[alpha1, Cl1, Cd1] = liftAndDrag('NACA0012');
disp('Alpha')
disp(alpha1)
disp('Lift Coefficients')
disp(Cl1)
disp('Drag Coefficients')
disp(Cd1)

testArray = {'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', 'NACA0015', ...
     'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat', 'e176.dat'};
[alpha2, Cl2, Cd2] = liftAndDrag(testArray);
disp('Alpha')
disp(alpha2)
disp('Lift Coefficients')
disp(Cl2)
disp('Drag Coefficients')
disp(Cd2)

CL = [1.3054    0.8773    0.6231];
CD = [0.0126    0.0110    0.0123];
Alphas = [0.0873    0.0785    0.0873]; % in radians
x = [1 1 1 1 2 2 2 2 2 2 3 3 3 3 1];

[alpha3, Cl3, Cd3] = liftAndDrag(x, CL, CD, Alphas);
disp('Alpha')
disp(alpha3)
disp('Lift Coefficients')
disp(Cl3)
disp('Drag Coefficients')
disp(Cd3)