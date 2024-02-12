function [theta,ypred,P,phi,z] = riv(D,si,f,lambda,theta0,P0,phi0,z0) 
%
% RIV        Implements the Recursive Instrumental Variables 
%            Method with exponential window applied on prediction 
%            errors.  
%
% Inputs:       D      # IDDATA object including the identification 
%                        data (which have to be ARX modelled) 
%               si     # structural indices vector [na nb nk]
%               f      # the vector of instruments (D.u, by default)
%                        (must have the same length as D.u, otherwise 
%                         it is cut or zero-padded, whichever applies) 
%               lambda # forgetting factor (1, by default)
%               theta0 # initial guess of parameters vector 
%                        (null, by default)
%               P0     # initial guess of main matrix inverse 
%                        (unit, by default)
%               phi0   # initial guess of regressors vector 
%                        (null, by default)
%               z0     # initial guess of instrumental vector 
%                        (null, by default)
%
% Outputs:  	theta  # matrix including on each row the estimated 
%                        parameters [a b] corresponding to a sampling 
%                        instant; the number of rows equals the 
%                        length of D.u (or f)
%               ypred  # predicted outpud when using the estimated 
%                        parameters theta
%               P      # final value of main matrix inverse
%               phi    # final value of regressors vector
%               z      # final value of instrumental vector
%
% Explanation:  An ARX model with variable parameters is estimated 
%	        through the Recursive Instrumental Variables Method 
%	        starting from experimental data. The prediction 
%               errors are exponentially windowed in this aim. 
%
% Author:  Dan Stefanoiu (*)
% Revised: Lavinius Ioan Gliga (*)
%
% Created: April 10, 2004
% Revised: August 9, 2018
%
% Copyright: (*) "Politehnica" Unversity of Bucharest, ROMANIA
%                Department of Automatic Control & Computer Science

%
% BEGIN
% 
% Messages 
% ~~~~~~~~
	FN  = '<RIV>: ' ; 
	EX  = 'Empty outputs. Exit.' ;
	E1  = [FN 'Missing or empty measured data. ' EX] ;
	E2  = [FN 'Unrecognized data set ' ... 
                  '(not an IDDATA object). ' EX] ; 
	E3  = [FN 'Inconsistent measured data. ' EX] ; 
	E4  = [FN 'Missing or empty structural indices. ' EX] ; 
	E5  = [FN 'Inconsistent structural indices. ' EX] ; 
	E6  = [FN 'Null forgetting factor. ' EX] ; 
	E7  = [FN 'Wrong size of P0 matrix. ' EX] ; 
% 
% Faults preventing
% ~~~~~~~~~~~~~~~~~
theta = [] ; 
ypred = [] ; 
P = [] ; 
phi = [] ; 
z = [] ; 
if (nargin < 1)
   war_err(E1) ;
   return ; 
end 
if (isempty(D))
   war_err(E1) ;
   return ; 
end 
if (~isa(D,'IDDATA'))
   war_err(E2) ;
   return ; 
end 
if (isempty(D.u)) 
   war_err(E3) ;
   return ; 
end 
if (nargin < 2)
   war_err(E4) ;
   return ; 
end
if (isempty(si))
   war_err(E4) ;
   return ; 
end 
si = vectorize(si) ; 
if (length(si) < 3)
   war_err(E5) ;
   return ; 
end 
si = abs(round(si(1:3))) ; 
si(3) = max(1,si(3)) ; 
na = si(1) ; 
nb = si(2) ; 
nk = si(3) ; 
if (nargin < 3)
   f = D.u ;
end 
if (isempty(f))
   f = D.u ; 
end 
f = vectorize(f)' ; 
n = length(f) ; 
N = length(D.u) ; 
n = min(n,N) ; 
f = [f(1:n) ; zeros(N-n,1)]; 
if (nargin < 4)
   lambda = 1 ;
end 
if (isempty(lambda))
   lambda = 1 ;
end  
lambda = abs(lambda(1)) ; 
if (~lambda) 
   war_err(E6) ; 
   return ; 
end  
if (lambda>1) 
   lambda = 1/lambda ; 
end  
k = na+nb+nk-1 ; 
if (nargin < 5)
   theta0 = zeros(k,1) ; 
end 
if (isempty(theta0))
   theta0 = zeros(k,1) ; 
end  
theta0 = vectorize(theta0)' ; 
n = min(length(theta0),k) ; 
theta0 = [theta0(1:n) zeros(k-n,1)] ; 
if (nargin < 6)
   P0 = eye(k) ;
end 
if (isempty(P0))
   P0 = eye(k) ;
end 
P0 = P0(:,:) ; 
if ((size(P0,1) - k) || (size(P0,2) - k))
   war_err(E7) ; 
   return ; 
end  
if (nargin < 7)
   phi0 = zeros(k,1) ; 
end 
if (isempty(phi0))
   phi0 = zeros(k,1) ; 
end 
phi0 = vectorize(phi0)' ; 
n = min(length(phi0),k) ; 
phi0 = [phi0(1:n) zeros(k-n,1)] ; 
if (nargin < 8)
   z0 = zeros(k,1) ; 
end
if (isempty(z0))
   z0 = zeros(k,1) ; 
end  
z0 = vectorize(z0)' ; 
n = min(length(z0),k) ; 
z0 = [z0(1:n) zeros(k-n,1)] ; 
% 
% Centering the data 
% ~~~~~~~~~~~~~~~~~~
D.y = D.y - mean(D.y) ; 
D.u = D.u - mean(D.u) ; 
f   = f   - mean(f) ; 
% 
% Recursive identification and simulation
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
nb = nb+nk-1 ;  			% Initialization. 
D = iddata([zeros(nb,1) ; -phi0(na:-1:1)     ; D.y], ... 
           [zeros(na,1) ;  phi0(k:-1:(na+1)) ; D.u]) ; 
f = [z0(k:-1:1) ; f] ; 
phi = [-D.y((k-1):-1:(nb+1)) ; 0 ; D.u((k-1):-1:(na+1)) ; 0] ; 
z = [f((k-1):-1:1) ; 0] ; 
P = P0 ; 
si = theta0 ; 
ypred = zeros(N, 1);
theta = zeros(N, length(theta0));
for n=(k+1):(k+N)			% Estimation and simulation. 
   phi = [-D.y(n-1) ; phi(1:(na-1)) ; ... 
           D.u(n-1) ; phi((na+1):(k-1))] ; 
   z = [f(n-1) ; z(1:(k-1))] ; 
%   phi = [-D.y((n-1):-1:(n-na)) ; D.u((n-1):-1:(n-nb))] ; 
%   z = f((n-1):-1:(n-k)) ; 
   nk = P*z ; 
   nk = nk/(lambda+phi'*nk) ; 		% Gain vector. 
   P = (P-nk*phi'*P)/lambda ; 		% Next matrix. 
   ypred(n - k) = phi'*si ; 		% Predicted output. 
   si = si + nk*(D.y(n)-ypred(n - k)) ; 	% Upgrade parameters. 
   theta(n - k, :) = si' ; 		% Save parameters.
end 
%
% END
%
