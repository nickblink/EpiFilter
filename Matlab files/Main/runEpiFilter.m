% Bayesian recursive filter
function [Rmed, Rlow, Rhigh, Rm, pR] = runEpiFilter(Rmin, Rmax, nPts, eta, nday, pr0, Lam, Iday)

% Assumptions and notes
% - discrete filter on grid from Rmin to Rmax
% - provides conditional posterior and mean
% - expects a renewal model incidence input curve

% Delimited grid defining space of R
Rgrid = linspace(Rmin, Rmax, nPts);

% Prob vector for R and prior
pR = zeros(nday, nPts); 
pR(1, :) = pr0;

% Mean, median and confidence on R
Rm = zeros(1, nday); Rmed = Rm;
Rlow = Rm; Rhigh = Rm;

% Initial stats
Rm(1) = pR(1, :)*Rgrid'; 
ids = zeros(1, 3); Rcdf0 = cumsum(pR(1, :)); 
ids(1) = find(Rcdf0 > 0.5, 1, 'first');
ids(2) = find(Rcdf0 > 0.025, 1, 'first'); 
ids(3) = find(Rcdf0 > 0.975, 1, 'first');
Rmed(1) = Rgrid(ids(1)); 
Rlow(1) = Rgrid(ids(2)); Rhigh(1) = Rgrid(ids(1));

% For probabilities above or below 1
id1 = find(Rgrid <= 1, 1, 'last');
prL1 = zeros(1, nday); 

% Precompute state distributions
pstate = zeros(nPts, nPts);
for j = 1:nPts
    pstate(j, :) = normpdf(Rgrid(j), Rgrid, sqrt(Rgrid)*eta);
end

% Update prior to posterior sequentially
for i = 2:nday
    % Compute rate from Poisson renewal
    rate = Lam(i).*Rgrid;
    % Probabilities of observations
    pI = poisspdf(Iday(i), rate);
    
    % State equations for R
    pRup = pR(i-1, :)*pstate;
    
    % Posterior over R (updated)
    pR(i, :) = pRup.*pI;
    pR(i, :) = pR(i, :)/sum(pR(i, :));
    
    % Posterior mean and CDF
    Rm(i) = pR(i, :)*Rgrid';
    Rcdf = cumsum(pR(i, :));
    % Probability R <= 1
    prL1(i) = Rcdf(id1);
    
    % Quantiles from estimates
    ids(1) = find(Rcdf > 0.5, 1, 'first');
    ids(2) = find(Rcdf > 0.025, 1, 'first');
    ids(3)= find(Rcdf > 0.975, 1, 'first');
    clear('Rcdf'); Rmed(i) = Rgrid(ids(1)); 
    Rlow(i) = Rgrid(ids(2)); Rhigh(i) = Rgrid(ids(3));
end