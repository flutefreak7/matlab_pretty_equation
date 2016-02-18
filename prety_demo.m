x = 1;
a = 1;
b = 1;

% Test typical expression
y = exp(a^3 / b^2) * (x^2 + 2*x - sqrt(3))/(x^3 + 2*x^2 - 4* x + 12);
pretty_equation()

% Test expression with a comment
y = exp(a^3 / b^2) * (x^2 + 2*x - sqrt(3))/(x^3 + 2*x^2 - 4* x + 12); %comment
pretty_equation()

% Test multiline expressions
y = exp(a^3 / b^2) * ...
    (x^2 + 2*x - sqrt(3)) / ...
    (x^3 + 2*x^2 - 4* x + 12);
pretty_equation()

% Verify that it can exclude multiline comments
y = exp(a^3 / b^2) * ... % part 1
    (x^2 + 2*x - sqrt(3)) / ... % part 2
    (x^3 + 2*x^2 - 4* x + 12);
pretty_equation()

% Verify behavior for invalid expressions
disp('This is not an equation.')
pretty_equation()
