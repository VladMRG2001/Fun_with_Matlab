function [D,V,P] = gdata_vp(cv,N,sigma,lambda,bin) 
%
% GDATA_VP   Module that generates data from an ARMAX
%            process model with constant or variable 
%	     parameters. 
%
% Inputs:       cv     # flag indicating the type of process: 
%			    cv=0 -> constant parameters (default)
%			    cv=1 -> variable parameters
%               N      # simulation period (250, by default)
%               sigma  # standard deviation of PRB input 
%                        (1, by default) 
%                        if null, input inhibited
%               lambda # standard deviation of white noise 
%                        (1, by default)
%                        if null, noise free processes 
%                        are considered
%               bin    # flag indicating the type of input:
%                          0 -> Gaussian PRB
%                          1 -> flip-flop Gaussian PRB (default)
%
% Outputs:  	D      # IDDATA object representing the 
%                        I/O generated data 
%               V      # IDDATA object representing the 
%                        I/O noise generated data 
%                        (white noise as input, colored noise 
%                        as output)
%               P      # IDMODEL object representing the 
%                        process that provided the data 
%			 (see P.a, P.b and P.c for parameters)
%
% Explanation:  An ARMAX model with constant or variable parameters 
%	        is stimulated with a PRB signal. The generated input 
%	        and the observed output are returned.  
%
% Author:  Dan Stefanoiu (*)
% Revised: Lavinius Ioan Gliga (*)
%		   Iulia Cristina Rădulescu (*)
%
% Created: April 14, 2004
% Revised: August 9, 2018
%		   November 29, 2018
%
% Copyright: (*) "Politehnica" University of Bucharest, ROMANIA
%                Department of Automatic Control & Computer Science

%
% BEGIN
%
% Constants
% ~~~~~~~~~
a = -0.7 ;			% Constant coefficient of AR part. 
b =  0.6 ;			% Constant coefficient of X part.
c = -0.9 ;			% Constant coefficient of MA part. 
oa = 10*pi ; 			% Basic pulsation of AR part. 
ob =  4*pi ; 			% Basic pulsation of X part. 
oc = 18*pi ; 			% Basic pulsation of MA part. 
% 
% Faults preventing
% ~~~~~~~~~~~~~~~~~
if (nargin < 5)
   bin = 1 ;
end 
if (isempty(bin))
   bin = 1 ;
end 
bin = abs(sign(bin(1))) ; 
if (nargin < 4)
   lambda = 1 ;
end 
if (isempty(lambda))
   lambda = 1 ;
end 
lambda = abs(lambda(1)) ; 
if (nargin < 3)
   sigma = 1 ;
end
if (isempty(sigma))
   sigma = 1 ;
end 
sigma = abs(sigma(1)) ; 
if (nargin < 2)
   N = 250 ;
end
if (isempty(N))
   N = 250 ;
end 
N = abs(fix(N(1))) ; 
if (~N)
   N = 250 ;
end 
if (nargin < 1) 
   cv = 0 ;
end
if (isempty(cv))
   cv = 0 ;
end 
cv = cv(1) ; 
% 
% Building the process with constant parameters 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
P = idpoly([1 a],[0 b],[1 c]) ;
% 
% Generating the Gaussian white noise
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
e = lambda*randn(N,1) ; 
% 
% Generating the PRB input
% ~~~~~~~~~~~~~~~~~~~~~~~~
u = randn(N,1) ; 
u = sigma*(sign(u).^bin).*(u.^(1-bin)) ; 
% 
% Generating the data
% ~~~~~~~~~~~~~~~~~~~
if (cv)				% Case: variable parameters. 
   n = (1:N)/N ; 		% Define the variable parameters. 
   a = a*cos(oa*n) ; 
   b = b*sign(cos(ob*n)) ; 
   n = n*oc ; 
   c = c*sin(n)./n ;
   V = zeros(N, 1);
   V(1) = e(1) ;
   y = zeros(N, 1);
   y(1) = V(1) ; 
   for n=2:N			% Generate the noise & output. 
      V(n) = e(n)+c(n)*e(n-1) ; 
      y(n) = [-a(n)*y(n-1)+b(n)*u(n-1)+e(n)+c(n)*e(n-1)] ; 
   end  
   D = iddata(y,u) ;  
   P.a = [1 a] ; 
   P.b = [0 b] ; 
   P.c = [1 c] ;
else				% Case: constant parameters. 
   V = filter(P.c,1,e) ; 	% Generate the colored noise. 
   D = iddata(sim(P,[u e]),u) ;	% Output data. 
end 
				% Record the noise. 
V = iddata(V,e) ; 		% White noise:   V.u
				% Colored noise: V.y
%
% END
%
