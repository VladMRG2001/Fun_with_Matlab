% GAIC_R4    Module that evaluates the optimum structural 

%Se bazeaza pe GAIC_R3, dar avem 4 indici in loc de 3
%In mare nc se inlocuieste cu nf si restul se ajusteaza

%si = [nb,nc,nd,nf]
function [nb,nc,nd,nf,GAICR] = GAIC_R4(Lambda,N) 

%
% BEGIN
% 
% Messages 
% ~~~~~~~~
	FN  = '<GAIC_R4>: ' ; 
	E1  = [FN 'Missing, empty or null N. Empty outputs. Exit.'] ; 
	E2  = [FN 'Missing or empty Lambda. Empty outputs. Exit.'] ;
%
% Faults preventing
% ~~~~~~~~~~~~~~~~~
nb = [] ; 
nc = [] ;
nd = [] ;
nf = [] ;
GAICR = [] ; 
if (nargin < 1)
   war_err(E2) ; 
   return ;
end
if (isempty(Lambda))
   war_err(E2) ; 
   return ;
end 
Lambda = abs(Lambda) ; 
Lambda(~Lambda) = eps ; 
if (nargin < 2)
   war_err(E1) ; 
   return ;
end 
if (isempty(N))
   war_err(E1) ; 
   return ;
end 
N = abs(round(N(1))) ; 
if (~N)
   war_err(E1) ; 
   return ;
end 
% 
% Evaluating the GAIC_R criterion
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[~, ~,~,Nf] = size(Lambda) ; 
nb = zeros(1, Nf);
nc = zeros(1, Nf);
nd = zeros(1, Nf);
Gmin = zeros(1, Nf);
for nf=1:Nf
   [Nb,Nc,Nd,G] = GAIC_R3(Lambda(:,:,:,nf)*exp((nf-1)*log(N)/N),N) ; 
   nb(nf) = Nb ; 
   nc(nf) = Nc ; 
   nd(nf) = Nd ;
   GAICR = cat(4,GAICR,G) ; 
   Gmin(nf) = G(Nb,Nc,Nd) ; 
end 
[~,nf] = min(Gmin) ; 
nb = nb(nf) ; 
nc = nc(nf) ; 
nd = nd(nf) ; 
%
% END
%
