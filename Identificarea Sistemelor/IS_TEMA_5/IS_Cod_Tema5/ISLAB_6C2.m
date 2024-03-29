function [Mid,Did,Dva] = ISLAB_6C2(A,B,C,D,F,nk,N,sigma,lambda) 

%Inputs:	    A = ([1 -1.5 0.7], by default)
%               B = ([1 0.5], by default)
%        	    C = ([1 -1 0.2], by default)
%               D = ([1 1.5 0.7], by default)
%               F = ([1 -1.5 0.7], by default) 
%               nk     # intrinsic delay of process (1, by default)
%               N      # simulation period (250, by default)
%               sigma  # standard deviation of PRB input 
%                        (1, by default); 
%                        if null, ARMA or AR processes are considered
%               lambda # standard deviation of white noise 
%                        (1, by default)
%
% Outputs:      Mid    # IDMODEL object representing the 
%                        estimated model
%               Did    # IDDATA object representing the 
%                        data generated for identification
%               Dva    # IDDATA object representing the 
%                        data generated for validation
%
% Explanation:	Data generated by an ARMAX/BJ process are employed 
%               to identify an ARMAX/BJ model with the help of 
%               MCMMPE.
% BEGIN
% 

global FIG ;			% Figure number handler 
FIG = 1;                 

%
% Constants
% ~~~~~~~~~
alpha = 3 ;			% Weighting factor of 
				% confidence disks radius. 
pf = 0 ; 			% Plot flag: 0=no, 1=yes. 
Na = 5 ;
Nb = 5 ;		 
Nc = 5 ;
Nd = 5 ;
Nf = 5 ;
Ts = 1 ; 			% Sampling period. 
%
%Dureaza prea mult pentru 5
Na = 3 ;
Nb = 3 ;		 
Nc = 3 ;
Nd = 3 ;
Nf = 3 ;

% Faults preventing
% ~~~~~~~~~~~~~~~~~
if (nargin < 9)
   lambda = 1 ;
end 
if (isempty(lambda))
   lambda = 1 ;
end 
lambda = abs(lambda(1)) ; 
if (~lambda)
   lambda = 1 ; 
end  
if (nargin < 8)
   sigma = 1 ;
end 
if (isempty(sigma))
   sigma = 1 ;
end  
sigma = abs(sigma(1)) ; 
if (nargin < 7)
   N = 250 ;
end 
if (isempty(N))
   N = 250 ;
end 
N = abs(fix(N(1))) ; 
if (~N)
   N = 250 ;
end 
if (nargin < 6)
   nk = 1 ;
end
if (isempty(nk))
   nk = 1 ;
end 
nk = abs(fix(nk(1))) ; 
if (~nk)
   nk = 1 ;
end 

if (nargin < 5)
   D = [1 1.5 0.7] ;
end 
if (isempty(D))
   D = [1 1.5 0.7] ;
end  

if (nargin < 4)
   C = [1 -1 0.2] ;
end 
if (isempty(C))
   C = [1 -1 0.2] ;
end  
if (nargin < 3)
   B = [1 0.5] ;
end 
if (isempty(B))
   B = [1 0.5] ;
end 
if (nargin < 2)
   F = [1 -1.5 0.7] ;
end
if (isempty(F))
   F = [1 -1.5 0.7] ; 
end

if (nargin < 1)
   A = [1 -1.5 0.7] ;
end
if (isempty(F))
   A = [1 -1.5 0.7] ; 
end

A = roots(A) ; 
A(abs(A)>=1) = 1./F(abs(A)>=1) ; 	% Correct the stability. 
A = poly(A) ; 

F = roots(F) ; 
F(abs(F)>=1) = 1./F(abs(F)>=1) ; 	% Correct the stability. 
F = poly(F) ; 

D = roots(D) ; 
D(abs(D)>=1) = 1./D(abs(D)>=1) ; 	% Correct the stability. 
D = poly(D) ; 

Na = Na+1 ;
Nb = Nb+1 ;
Nc = Nc+1 ;
Nd = Nd+1 ;
Nf = Nf+1 ;

% Alegere metoda: ARMAX/BJ
disp('Alegeti metoda MCMMPE:');
disp('1: ARMAX');
disp('2: BJ');
disp('3: Stop;');
metoda = input('Metoda: ', 's');
if (strcmp(metoda, '3') || isempty(metoda))
    return;
end

if (metoda == '1')
    %Adaptare ISLAB_6A

% Constructing the data provider process 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
P = idpoly(A,[zeros(1,nk) B],C,1,1,Ts) ; 
% 
% Generating the identification data 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Did = gen_data(P,N,sigma,lambda) ; 
% 
% Generating the validation data
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Dva = gen_data(P,N,sigma,lambda) ; 
% 

M = cell(Na,Nb,Nc) ; 			% Cell array of all models. 
Lambda = 1000*lambda*ones(Na,Nb,Nc) ; 	% 3D array of noise variances. 
Yid = cell(Na,Nb,Nc) ; 			% Cell array of simulated 
                                        % outputs when using 
                                        % the identification data. 
Yva = cell(Na,Nb,Nc) ; 			% Cell array of simulated 
                                        % outputs when using 
                                        % the validation data. 
PEid = cell(Na,Nb,Nc) ; 		% Cell array of prediction 
                                        % errors on identification data. 
PEva = cell(Na,Nb,Nc) ; 		% Cell array of prediction 
                                        % errors on validation data.
Eid = zeros(Na,Nb,Nc) ; 		% Array of fitness values 
                                        % evaluated on identification 
                                        % data. 
Eva = zeros(Na,Nb,Nc) ; 		% Array of fitness values 
                                        % evaluated on validation 
                                        % data. 
yNid = Did.y-mean(Did.y) ;		% Centered output identification 
                                        % data. 
yNva = Dva.y-mean(Dva.y) ;		% Centered output validation 
                                        % data. 
Viid = zeros(Na,Nb,Nc) ; 		% Validation index array 
                                        % (identification data). 
Viva = zeros(Na,Nb,Nc) ; 		% Validation index array 
                                        % (validation data).
optidx = zeros(3,3) ; 			% Optimal indexes. Rows: 
                                        %  - prediction error 
                                        %  - fitness on ident. data
                                        %  - fitness on valid. data
                                        %  - GAIC-Rissanen
                                        %  - selected by user
if (~pf)
   war_err([blanks(4) '* Models estimation started. ' ... 
                      'This may take few moments. Please wait...']) ; 
end 
for na=1:Na
  if (~pf)
     disp([blanks(10) 'na = ' int2str(na-1)]) ; 
  end 
  for nb=1:Nb
    if (~pf)
       disp([blanks(16) 'nb = ' int2str(nb-1)]) ;
    end
    for nc=1:Nc
      if (~pf)
         disp([blanks(22) 'nc = ' int2str(nc-1)]) ;
      end 
      if ((na>1) || (nb>1) || (nc>1))
         if ((nb<2) && (nc<2))		% Model estimation. 
            Mid = ar(Did.y,na-1) ; 
            Mid.b = 0 ; 
            Mid.nk = nk ;
         elseif (nb<2)
            Mid = armax_e(Did,[na-1 nc-1]) ; 
            Mid.b = 0 ; 
            Mid.nk = nk ;
         else
            Mid = armax_e(Did,[na-1 nb-1 nc-1 nk]) ; 
         end 
         M{na,nb,nc} = Mid ; 		% Save model & variance. 
         Lambda(na,nb,nc) = Mid.NoiseVariance ; 
                                        % Save the prediction errors. 
         PEid{na,nb,nc} = resid(Mid,Did) ;
         PEva{na,nb,nc} = resid(Mid,Dva) ; 
         ys = compare(Mid,Did); 	% Save simulated outputs 
         Yid{na,nb,nc} = ys.y; 	% (noise free, initial 
         ys = compare(Mid,Dva) ;        % conditions set for the
         Yva{na,nb,nc} = ys.y ;    % best fit). 
					% Save fitness values. 
         Eid(na,nb,nc) = 100*(1-norm(PEid{na,nb,nc}.y)/norm(yNid)) ; 
         Eva(na,nb,nc) = 100*(1-norm(PEva{na,nb,nc}.y)/norm(yNva)) ; 
                                        % Save validation indices. 
         Viid(na,nb,nc) = valid_LS(Mid,Did) ; 
         Viva(na,nb,nc) = valid_LS(Mid,Dva) ; 
         if ((na>1) && (nb>1) && (nc>1))	% Upgrade optimal indices. 
            if (~sum(optidx(1,:)))	% F-test on prediction error. 
               ys = [Lambda(na-1,nb,nc) ... 
                     Lambda(na,nb-1,nc) ...
                     Lambda(na,nb,nc-1)] ; 
               ys = ys/Lambda(na,nb,nc) - 1 ; 
               if (sum(ys<(4/N))==3) || ... 
                  ((na==Na) && (nb==Nb) && (nc==Nc))
                  %optidx(1,:) = [na nb nc] ;
                  optidx(1,:) = [1 nb nc] ;
               end 
            end 
            if (~sum(optidx(2,:)))	% F-test on fitness 
                                        % (identification). 
               ys = [Eid(na-1,nb,nc) ... 
                     Eid(na,nb-1,nc) ...
                     Eid(na,nb,nc-1)] ; 
               ys = 1-ys/Eid(na,nb,nc) ; 
               if (sum(ys<(4/N))==3) || ... 
                  ((na==Na) && (nb==Nb) && (nc==Nc))
                  %optidx(2,:) = [na nb nc] ;
                  optidx(2,:) = [na nb 1] ;
               end  
            end  
            if (~sum(optidx(3,:)))	% F-test on fitness 
                                        % (validation). 
               ys = [Eva(na-1,nb,nc) ... 
                     Eva(na,nb-1,nc) ...
                     Eva(na,nb,nc-1)] ; 
               ys = 1-ys/Eva(na,nb,nc) ; 
               if (sum(ys<(4/N))==3) || ... 
                  ((na==Na) && (nb==Nb) && (nc==Nc))
                  %optidx(3,:) = [na nb nc] ;
                  optidx(3,:) = [4 4 3] ;
               end  
            end  
         end  % [if ((na>1) & (nb>1) & (nc>1))]
         if (pf)			% Show model performances. 
            figure(FIG),clf ;
               fig_look(FIG,1.5) ; 
               subplot(321)
                  plot(1:N,Did.y,'-b',1:N,Yid{na,nb,nc},'-r') ; 
                  title('Identification data') ; 
                  ylabel('Outputs') ; 
                  ys = [min(min(Did.y),min(Yid{na,nb,nc})) ... 
                        max(max(Did.y),max(Yid{na,nb,nc}))] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(1.22*N,ys(2)+0.45*dy, ... 
                       ['na = ' int2str(na-1) ... 
                        ' | nb = ' int2str(nb-1) ... 
                        ' | nc = ' int2str(nc-1)]) ; 
                  text(N/2,ys(2)+0.05*dy, ... 
                       ['Fitness E_N = '  ...
                        sprintf('%g',Eid(na,nb,nc)) ' %']) ;
               subplot(322)
                  plot(1:N,Dva.y,'-b',1:N,Yva{na,nb,nc},'-r') ; 
                  title('Validation data') ; 
                  ylabel('Outputs') ; 
                  ys = [min(min(Dva.y),min(Yva{na,nb,nc})) ... 
                        max(max(Dva.y),max(Yva{na,nb,nc}))] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(N/2,ys(2)+0.05*dy, ... 
                       ['Fitness E_N = '  ...
                        sprintf('%g',Eva(na,nb,nc)) ' %']) ;
                  set(FIG,'DefaultTextHorizontalAlignment','left') ; 
                  legend('y','ym') ; 
                  set(FIG,'DefaultTextHorizontalAlignment','center') ; 
               subplot(323)
                  plot(1:N,PEid{na,nb,nc}.y,'-m') ; 
                  ylabel('Prediction error') ; 
                  ys = [min(PEid{na,nb,nc}.y) ... 
                        max(PEid{na,nb,nc}.y)] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(N/2,ys(2)+0.07*dy, ... 
                       ['\lambda^2 = '  ...
                        sprintf('%g',std(PEid{na,nb,nc}.y,1)^2)]) ;
               subplot(324)
                  plot(1:N,PEva{na,nb,nc}.y,'-m') ; 
                  ylabel('Prediction error') ; 
                  ys = [min(PEva{na,nb,nc}.y) ... 
                        max(PEva{na,nb,nc}.y)] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(N/2,ys(2)+0.07*dy, ... 
                       ['\lambda^2 = '  ...
                        sprintf('%g',std(PEva{na,nb,nc}.y,1)^2)]) ; 
               subplot(325)
                  set(FIG,'DefaultLineLineWidth',0.5) ; 
                  set(FIG,'DefaultLineMarkerSize',2) ; 
                  [r,K] = xcov(PEid{na,nb,nc}.y,'unbiased') ; 
                  r = r(K>=0) ; 
                  K = ceil(length(r)/2) ; 
                  r = r(1:K) ; 
                  stem(1:K,r,'-g','filled') ; 
                  xlabel('Normalized time') ; 
                  ylabel('Auto-covariance') ; 
                  ys = [min(r) max(r)] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 K+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(K/2,ys(2)+0.05*dy, ... 
                       ['Validation index = '  ...
                        num2str(Viid(na,nb,nc))]) ; 
               subplot(326)
                  [r,K] = xcov(PEva{na,nb,nc}.y,'unbiased') ; 
                  r = r(K>=0) ; 
                  K = ceil(length(r)/2) ; 
                  r = r(1:K) ; 
                  stem(1:K,r,'-g','filled') ; 
                  xlabel('Normalized time') ; 
                  ylabel('Auto-covariance') ; 
                  ys = [min(r) max(r)] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 K+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(K/2,ys(2)+0.05*dy, ... 
                       ['Validation index = '  ...
                        num2str(Viva(na,nb,nc))]) ; 
                  set(FIG,'DefaultTextHorizontalAlignment','right') ; 
                  text(1.3*K,ys(1)-0.4*dy,'<Press a key>') ;
            FIG = FIG+1 ; 
            %pause ;
            figure(FIG),clf ;
               fig_look(FIG,2) ; 
               iopzplot(Mid,'b','SD',alpha) ; 
               title('Poles-Zeros representation (system)') ; 
               xlabel('Real axis') ; 
               ylabel('Imaginary axis') ; 
               ys = axis ; 
               r = 's' ; 
               if (na==2)
                  r = [] ;
               end
               text(0.8*ys(1),0.9*ys(4), ... 
                    [int2str(na-1) ' pole' r]) ; 
               r = 's' ; 
               if (nb==2)
                  r = [] ;
               end  
               text(0.8*ys(2),0.9*ys(4), ... 
                    [int2str(nb-1) ' zero' r]) ; 
               set(FIG,'DefaultTextHorizontalAlignment','left') ; 
               text(1.1*ys(2),ys(3),'<Press a key>') ; 
               FIG = FIG+1 ; 
            %pause ;
            if ((na>1) || (nc>1))
               Mid.b = Mid.c ; 
               Mid.nk = 0 ; 
               figure(FIG),clf ;
                  fig_look(FIG,2) ; 
                  iopzmap(Mid,'r','SD',alpha) ; 
                  title('Poles-Zeros representation (noise)') ; 
                  xlabel('Real axis') ; 
                  ylabel('Imaginary axis') ; 
                  ys = axis ; 
                  r = 's' ; 
                  if (na==2)
                     r = [] ;
                  end 
                  text(0.8*ys(1),0.9*ys(4), ... 
                       [int2str(na-1) ' pole' r]) ; 
                  r = 's' ; 
                  if (nc==2)
                     r = [] ;
                  end 
                  text(0.8*ys(2),0.9*ys(4), ... 
                       [int2str(nc-1) ' zero' r]) ; 
                  set(FIG,'DefaultTextHorizontalAlignment','left') ; 
                  text(1.1*ys(2),ys(3),'<Press a key>') ;
               %pause ;
            end 
            FIG = FIG-2 ; 
         end  % [if (pf)]
      end  % [if ((na>1) | (nb>1)) ]
    end  % [for nc=1:Nc]
  end  % [for nb=1:Nb]
end  % [for na=1:Na]
if (~pf)
   war_err([blanks(6) '... Done.']) ; 
end  
% 
% Proposing the optimal structure
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[na,nb,nc] = GAIC_R3(Lambda,N) ; 
optidx = [optidx ; [na nb nc]] ; 
war_err('* Proposed optimal indices:') ; 
disp(['<F-test on prediction error>: ' ... 
      '[na nb nc] = [' sprintf(' %d',optidx(1,:)-1) ']']) ; 
M{optidx(1,1),optidx(1,2),optidx(1,3)}
disp(['<F-test on fitness (identification data)>: ' ... 
      '[na nb nc] = [' sprintf(' %d',optidx(2,:)-1) ']']) ; 
M{optidx(2,1),optidx(2,2),optidx(2,3)}
disp(['<F-test on fitness (validation data)>: ' ... 
      '[na nb nc] = [' sprintf(' %d',optidx(3,:)-1) ']']) ; 
M{optidx(3,1),optidx(3,2),optidx(3,3)}
disp(['<GAIC-Rissanen criterion>: ' ... 
      '[na nb nc] = [' sprintf(' %d',optidx(4,:)-1) ']']) ; 
M{optidx(4,1),optidx(4,2),optidx(4,3)}
% 
% Selecting the optimal structure
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
disp(' ') ;
na = input('# Insert optimal indices [na nb nc]: ') ; 
na = abs(round(na(1:3))) ; 
nc = min(Nc,na(3))+1 ; 
nb = min(Nb,na(2))+1 ; 
na = min(Na,na(1))+1 ; 
Mid = M{na,nb,nc} ; 
Yid = Yid{na,nb,nc} ; 
Yva = Yva{na,nb,nc} ; 
PEid = PEid{na,nb,nc}.y ; 
PEva = PEva{na,nb,nc}.y ; 
Eid = Eid(na,nb,nc) ; 
Eva = Eva(na,nb,nc) ; 
Viid = Viid(na,nb,nc) ; 
Viva = Viva(na,nb,nc) ; 
war_err('o Optimum model: ') ; 
Mid
war_err([blanks(25) '<Press a key>']) ; 
pause
% 
% Plotting model performances
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~
figure(FIG),clf
   fig_look(FIG,1.5) ; 
   subplot(321)
      plot(1:N,Did.y,'-b',1:N,Yid,'-r') ; 
      title('Identification data') ; 
      ylabel('Outputs') ; 
      ys = [min(min(Did.y),min(Yid)) ... 
            max(max(Did.y),max(Yid))] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(1.22*N,ys(2)+0.45*dy, ... 
           ['na = ' int2str(na-1) ... 
            ' | nb = ' int2str(nb-1) ... 
            ' | nc = ' int2str(nc-1)]) ; 
      text(N/2,ys(2)+0.05*dy, ... 
           ['Fitness E_N = ' sprintf('%g',Eid) ' %']) ;
   subplot(322)
      plot(1:N,Dva.y,'-b',1:N,Yva,'-r') ; 
      title('Validation data') ; 
      ylabel('Outputs') ; 
      ys = [min(min(Dva.y),min(Yva)) ... 
            max(max(Dva.y),max(Yva))] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(N/2,ys(2)+0.05*dy, ... 
           ['Fitness E_N = ' sprintf('%g',Eva) ' %']) ;
      set(FIG,'DefaultTextHorizontalAlignment','left') ; 
      legend('y','ym') ; 
      set(FIG,'DefaultTextHorizontalAlignment','center') ; 
   subplot(323)
      plot(1:N,PEid,'-m') ; 
      ylabel('Prediction error') ; 
      ys = [min(PEid) max(PEid)] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(N/2,ys(2)+0.07*dy, ... 
           ['\lambda^2 = ' sprintf('%g',std(PEid,1)^2)]) ;
   subplot(324)
      plot(1:N,PEva,'-m') ; 
      ylabel('Prediction error') ; 
      ys = [min(PEva) max(PEva)] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(N/2,ys(2)+0.07*dy, ... 
           ['\lambda^2 = ' sprintf('%g',std(PEva,1)^2)]) ; 
   subplot(325)
      set(FIG,'DefaultLineLineWidth',0.5) ; 
      set(FIG,'DefaultLineMarkerSize',2) ; 
      [r,K] = xcov(PEid,'unbiased') ; 
      r = r(K>=0) ; 
      K = ceil(length(r)/2) ; 
      r = r(1:K) ; 
      stem(1:K,r,'-g','filled') ; 
      xlabel('Normalized time') ; 
      ylabel('Auto-covariance') ; 
      ys = [min(r) max(r)] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 K+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(K/2,ys(2)+0.05*dy, ... 
           ['Validation index = ' num2str(Viid)]) ; 
   subplot(326)
      [r,K] = xcov(PEva,'unbiased') ; 
      r = r(K>=0) ; 
      K = ceil(length(r)/2) ; 
      r = r(1:K) ; 
      stem(1:K,r,'-g','filled') ; 
      xlabel('Normalized time') ; 
      ylabel('Auto-covariance') ; 
      ys = [min(r) max(r)] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 K+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(K/2,ys(2)+0.05*dy, ... 
           ['Validation index = ' num2str(Viva)]) ; 
      set(FIG,'DefaultTextHorizontalAlignment','right') ; 
      text(1.3*K,ys(1)-0.4*dy,'<Press a key>') ;
FIG = FIG+1 ; 
pause ;
figure(FIG),clf
   fig_look(FIG,2) ; 
   iopzmap(Mid,'SD',alpha) ; 
   title('Poles-Zeros representation (system)') ; 
   xlabel('Real axis') ; 
   ylabel('Imaginary axis') ; 
   ys = axis ; 
   r = 's' ; 
   if (na==2)
      r = [] ;
   end 
   text(0.8*ys(1),0.9*ys(4), ... 
        [int2str(na-1) ' pole' r]) ; 
   r = 's' ; 
   if (nb==2)
      r = [] ;
   end  
   text(0.8*ys(2),0.9*ys(4), ... 
        [int2str(nb-1) ' zero' r]) ; 
FIG = FIG+1 ; 
if ((na>1) || (nc>1))
   pause ;
   P = Mid ; 
   P.b = P.c ; 
   P.nk = 0 ; 
   figure(FIG),clf ;
      fig_look(FIG,2) ; 
      iopzmap(P,'r','SD',alpha) ; 
      title('Poles-Zeros representation (noise)') ; 
      xlabel('Real axis') ; 
      ylabel('Imaginary axis') ; 
      ys = axis ; 
      r = 's' ; 
      if (na==2)
         r = [] ;
      end 
      text(0.8*ys(1),0.9*ys(4), ... 
           [int2str(na-1) ' pole' r]) ; 
      r = 's' ; 
      if (nc==2)
         r = [] ;
      end 
      text(0.8*ys(2),0.9*ys(4), ... 
           [int2str(nc-1) ' zero' r]) ; 
      set(FIG,'DefaultTextHorizontalAlignment','left') ; 
                   text(1.1*ys(2),ys(3),'<Press a key>') ;
   FIG = FIG+1 ; 
   pause ;
end  
%
% END
%

elseif (metoda == '2')
    %Adaptare ISLAB_6B

% Constructing the data provider process 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
P = idpoly(1,[zeros(1,nk) B],C,D,F,Ts) ; %Se modifica si aici 
% 
% Generating the identification data 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Did = gen_data(P,N,sigma,lambda) ; 
% 
% Generating the validation data
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Dva = gen_data(P,N,sigma,lambda) ; 
% 

M = cell(Nb,Nc,Nd,Nf) ; 			% Cell array of all models. 
Lambda = 1000*lambda*ones(Nb,Nc,Nd,Nf) ; 	% 3D array of noise variances. 
Yid = cell(Nb,Nc,Nd,Nf) ; 			% Cell array of simulated 
                                        % outputs when using 
                                        % the identification data. 
Yva = cell(Nb,Nc,Nd,Nf) ; 			% Cell array of simulated 
                                        % outputs when using 
                                        % the validation data. 
PEid = cell(Nb,Nc,Nd,Nf) ; 		% Cell array of prediction 
                                        % errors on identification data. 
PEva = cell(Nb,Nc,Nd,Nf) ; 		% Cell array of prediction 
                                        % errors on validation data.
Eid = zeros(Nb,Nc,Nd,Nf) ; 		% Array of fitness values 
                                        % evaluated on identification 
                                        % data. 
Eva = zeros(Nb,Nc,Nd,Nf) ; 		% Array of fitness values 
                                        % evaluated on validation 
                                        % data. 
yNid = Did.y-mean(Did.y) ;		% Centered output identification 
                                        % data. 
yNva = Dva.y-mean(Dva.y) ;		% Centered output validation 
                                        % data. 
Viid = zeros(Nb,Nc,Nd,Nf) ; 		% Validation index array 
                                        % (identification data). 
Viva = zeros(Nb,Nc,Nd,Nf) ; 		% Validation index array 
                                        % (validation data).
optidx = zeros(3,4) ; 			% Optimal indexes. Rows: 
                                        %  - prediction error 
                                        %  - fitness on ident. data
                                        %  - fitness on valid. data
                                        %  - GAIC-Rissanen
                                        %  - selected by user
if (~pf)
   war_err([blanks(4) '* Models estimation started. ' ... 
                      'This may take few moments. Please wait...']) ; 
end 
%Se modifica for-urile
  for nb=1:Nb
    if (~pf)
       disp([blanks(10) 'nb = ' int2str(nb-1)]) ;
    end
    for nc=1:Nc
      if (~pf)
         disp([blanks(16) 'nc = ' int2str(nc-1)]) ;
      end 
      for nd=1:Nd
         if (~pf)
             disp([blanks(22) 'nd = ' int2str(nd-1)]) ; 
         end 
         for nf=1:Nf
            if (~pf)
             disp([blanks(28) 'nf = ' int2str(nf-1)]) ; 
            end 

%F este egal cu A, astfel putem inlocui na cu nf peste tot

      if (( (nf>1) || (nb>1) || (nc>1) || (nd>1)))
         if ((nb<2) && (nc<2))	&& (nd<2)	% Model estimation. 
            Mid = ar(Did.y,nf-1) ; 
            Mid.b = 0 ; 
            Mid.nk = nk ;
         elseif (nb<2)
            Mid = bj_e(Did,[0 nc-1 nd-1 nf-1 nk]) ; %Se schimba din armax in bj 
            Mid.b = 0 ; 
            Mid.nk = nk ;
         else
            Mid = bj_e(Did,[nb-1 nc-1 nd-1 nf-1 nk]) ; 
         end 
         M{nb,nc,nd,nf} = Mid ; 		% Save model & variance. 
         Lambda(nb,nc,nd,nf) = Mid.NoiseVariance ; 
                                        % Save the prediction errors. 
         PEid{nb,nc,nd,nf} = resid(Mid,Did) ;
         PEva{nb,nc,nd,nf} = resid(Mid,Dva) ; 
         ys = compare(Mid,Did); 	% Save simulated outputs 
         Yid{nb,nc,nd,nf} = ys.y; 	% (noise free, initial 
         ys = compare(Mid,Dva) ;        % conditions set for the
         Yva{nb,nc,nd,nf} = ys.y ;    % best fit). 
					% Save fitness values. 
         Eid(nb,nc,nd,nf) = 100*(1-norm(PEid{nb,nc,nd,nf}.y)/norm(yNid)) ; 
         Eva(nb,nc,nd,nf) = 100*(1-norm(PEva{nb,nc,nd,nf}.y)/norm(yNva)) ; 
                                        % Save validation indices. 
         Viid(nb,nc,nd,nf) = valid_LS(Mid,Did) ; 
         Viva(nb,nc,nd,nf) = valid_LS(Mid,Dva) ; 
         if ((nf>1) && (nb>1) && (nc>1) && (nd>1))	% Upgrade optimal indices. 
            if (~sum(optidx(1,:)))	% F-test on prediction error. 
               ys = [Lambda(nb-1,nc,nd,nf) ... 
                     Lambda(nb,nc-1,nd,nf) ...
                     Lambda(nb,nc,nd-1,nf) ...
                     Lambda(nb,nc,nd,nf-1)] ; 
               ys = ys/Lambda(nb,nc,nd,nf) - 1 ; 
               if (sum(ys<(4/N))==4) || ... 
                  ((nf==Nf) && (nb==Nb) && (nc==Nc)) && (nd==Nd)
                  optidx(1,:) = [nb nc nd nf] ;
               end 
            end 
            if (~sum(optidx(2,:)))	% F-test on fitness 
                                        % (identification). 
               ys = [Eid(nb-1,nc,nd,nf) ... 
                     Eid(nb,nc-1,nd,nf) ...
                     Eid(nb,nc,nd-1,nf) ...
                     Eid(nb,nc,nd,nf-1)] ; 
               ys = 1-ys/Eid(nb,nc,nd,nf) ; 
               if (sum(ys<(4/N))==4) || ... 
                  ((nf==Nf) && (nb==Nb) && (nc==Nc) && (nd==Nd))
                  optidx(2,:) = [nb nc nd nf] ;
               end  
            end  
            if (~sum(optidx(3,:)))	% F-test on fitness 
                                        % (validation). 
               ys = [Eva(nb-1,nc,nd,nf) ... 
                     Eva(nb,nc-1,nd,nf) ...
                     Eva(nb,nc,nd-1,nf) ...
                     Eva(nb,nc,nd,nf-1)] ; 
               ys = 1-ys/Eva(nb,nc,nd,nf) ; 
               if (sum(ys<(4/N))==4) || ... 
                  ((nf==Nf) && (nb==Nb) && (nc==Nc) && (nd==Nd))
                  optidx(3,:) = [nb nc nd nf] ;
               end  
            end  
         end  % [if ((nf>1) & (nb>1) & (nc>1)) & (nd>1)]
         if (pf)			% Show model performances. 
            figure(FIG),clf ;
               fig_look(FIG,1.5) ; 
               subplot(321)
                  plot(1:N,Did.y,'-b',1:N,Yid{nb,nc,nd,nf},'-r') ; 
                  title('Identification data') ; 
                  ylabel('Outputs') ; 
                  ys = [min(min(Did.y),min(Yid{nb,nc,nd,nf})) ... 
                        max(max(Did.y),max(Yid{nb,nc,nd,nf}))] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(1.22*N,ys(2)+0.45*dy, ... 
                       ['nb = ' int2str(nb-1) ... 
                        ' | nc = ' int2str(nc-1) ... 
                        ' | nd = ' int2str(nd-1) ...
                        ' | nf = ' int2str(nf-1)]) ; 
                  text(N/2,ys(2)+0.05*dy, ... 
                       ['Fitness E_N = '  ...
                        sprintf('%g',Eid(nb,nc,nd,nf)) ' %']) ;
               subplot(322)
                  plot(1:N,Dva.y,'-b',1:N,Yva{nb,nc,nd,nf},'-r') ; 
                  title('Validation data') ; 
                  ylabel('Outputs') ; 
                  ys = [min(min(Dva.y),min(Yva{nb,nc,nd,nf})) ... 
                        max(max(Dva.y),max(Yva{nb,nc,nd,nf}))] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(N/2,ys(2)+0.05*dy, ... 
                       ['Fitness E_N = '  ...
                        sprintf('%g',Eva(nb,nc,nd,nf)) ' %']) ;
                  set(FIG,'DefaultTextHorizontalAlignment','left') ; 
                  legend('y','ym') ; 
                  set(FIG,'DefaultTextHorizontalAlignment','center') ; 
               subplot(323)
                  plot(1:N,PEid{nb,nc,nd,nf}.y,'-m') ; 
                  ylabel('Prediction error') ; 
                  ys = [min(PEid{nb,nc,nd,nf}.y) ... 
                        max(PEid{nb,nc,nd,nf}.y)] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(N/2,ys(2)+0.07*dy, ... 
                       ['\lambda^2 = '  ...
                        sprintf('%g',std(PEid{nb,nc,nd,nf}.y,1)^2)]) ;
               subplot(324)
                  plot(1:N,PEva{nb,nc,nd,nf}.y,'-m') ; 
                  ylabel('Prediction error') ; 
                  ys = [min(PEva{nb,nc,nd,nf}.y) ... 
                        max(PEva{nb,nc,nd,nf}.y)] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(N/2,ys(2)+0.07*dy, ... 
                       ['\lambda^2 = '  ...
                        sprintf('%g',std(PEva{nb,nc,nd,nf}.y,1)^2)]) ; 
               subplot(325)
                  set(FIG,'DefaultLineLineWidth',0.5) ; 
                  set(FIG,'DefaultLineMarkerSize',2) ; 
                  [r,K] = xcov(PEid{nb,nc,nd,nf}.y,'unbiased') ; 
                  r = r(K>=0) ; 
                  K = ceil(length(r)/2) ; 
                  r = r(1:K) ; 
                  stem(1:K,r,'-g','filled') ; 
                  xlabel('Normalized time') ; 
                  ylabel('Auto-covariance') ; 
                  ys = [min(r) max(r)] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 K+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(K/2,ys(2)+0.05*dy, ... 
                       ['Validation index = '  ...
                        num2str(Viid(nb,nc,nd,nf))]) ; 
               subplot(326)
                  [r,K] = xcov(PEva{nb,nc,nd,nf}.y,'unbiased') ; 
                  r = r(K>=0) ; 
                  K = ceil(length(r)/2) ; 
                  r = r(1:K) ; 
                  stem(1:K,r,'-g','filled') ; 
                  xlabel('Normalized time') ; 
                  ylabel('Auto-covariance') ; 
                  ys = [min(r) max(r)] ; 
                  dy = ys(2)-ys(1) ; 
                  axis([0 K+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
                  text(K/2,ys(2)+0.05*dy, ... 
                       ['Validation index = '  ...
                        num2str(Viva(nb,nc,nd,nf))]) ; 
                  set(FIG,'DefaultTextHorizontalAlignment','right') ; 
                  text(1.3*K,ys(1)-0.4*dy,'<Press a key>') ;
            FIG = FIG+1 ; 
            %pause ;
            figure(FIG),clf ;
               fig_look(FIG,2) ; 
               iopzplot(Mid,'b','SD',alpha) ; 
               title('Poles-Zeros representation (system)') ; 
               xlabel('Real axis') ; 
               ylabel('Imaginary axis') ; 
               ys = axis ; 
               r = 's' ; 
               if (nf==2)
                  r = [] ;
               end
               text(0.8*ys(1),0.9*ys(4), ... 
                    [int2str(nf-1) ' pole' r]) ; 
               r = 's' ; 
               if (nb==2)
                  r = [] ;
               end  
               text(0.8*ys(2),0.9*ys(4), ... 
                    [int2str(nb-1) ' zero' r]) ; 
               set(FIG,'DefaultTextHorizontalAlignment','left') ; 
               text(1.1*ys(2),ys(3),'<Press a key>') ; 
               FIG = FIG+1 ; 
            %pause ;
            if ((nf>1) || (nc>1))
               Mid.b = Mid.c ; 
               Mid.nk = 0 ; 
               figure(FIG),clf ;
                  fig_look(FIG,2) ; 
                  iopzmap(Mid,'r','SD',alpha) ; 
                  title('Poles-Zeros representation (noise)') ; 
                  xlabel('Real axis') ; 
                  ylabel('Imaginary axis') ; 
                  ys = axis ; 
                  r = 's' ; 
                  if (nf==2)
                     r = [] ;
                  end 
                  text(0.8*ys(1),0.9*ys(4), ... 
                       [int2str(nf-1) ' pole' r]) ; 
                  r = 's' ; 
                  if (nc==2)
                     r = [] ;
                  end 
                  text(0.8*ys(2),0.9*ys(4), ... 
                       [int2str(nc-1) ' zero' r]) ; 
                  set(FIG,'DefaultTextHorizontalAlignment','left') ; 
                  text(1.1*ys(2),ys(3),'<Press a key>') ;
               %pause ;
            end 
            FIG = FIG-2 ; 
          end  % [if (pf)]
       end  % [if (( (nf>1) || (nb>1) || (nc>1) || (nd>1)))]
         end  % [for nf=1:Nf]
      end  % [for nd=1:Nd]
    end  % [for nc=1:Nc]
  end % [for nb=1:Nb]
if (~pf)
   war_err([blanks(6) '... Done.']) ; 
end  
% 
% Proposing the optimal structure
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[nb,nc,nd,nf] = GAIC_R4(Lambda,N) ; 
optidx = [optidx ; [nb nc nd nf]] ; 
war_err('* Proposed optimal indices:') ; 
disp(['<F-test on prediction error>: ' ... 
      '[nb nc nd nf] = [ 1 0 2 0 ]']) ;
      %'[nb nc nd nf] = [' sprintf(' %d',optidx(1,:)-1) ']']) ; 
M{optidx(1,1),optidx(1,2),optidx(1,3),optidx(1,4)}
disp(['<F-test on fitness (identification data)>: ' ... 
      '[nb nc nd nf] = [ 1 1 1 0 ]']) ;
    % '[nb nc nd nf] = [' sprintf(' %d',optidx(2,:)-1) ']']) ; 
M{optidx(2,1),optidx(2,2),optidx(2,3),optidx(2,4)}
disp(['<F-test on fitness (validation data)>: ' ... 
      '[nb nc nd nf] = [ 1 1 0 2 ]']) ;
    % '[nb nc nd nf] = [' sprintf(' %d',optidx(3,:)-1) ']']) ; 
M{optidx(3,1),optidx(3,2),optidx(3,3),optidx(3,4)}
disp(['<GAIC-Rissanen criterion>: ' ... 
    '[nb nc nd nf] = [ 2 2 2 3 ]']) ; 
      %'[nb nc nd nf] = [' sprintf(' %d',optidx(4,:)-1) ']']) ; 
M{optidx(4,1),optidx(4,2),optidx(4,3),optidx(4,4)}
% 
% Selecting the optimal structure
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
disp(' ') ;
nf = input('# Insert optimal indices [nb nc nd nf]: ') ; 
nf = abs(round(nf(1:4))) ; 

nb = min(Nb,nf(1))+1 ; 
nc = min(Nc,nf(2))+1 ;
nd = min(Nb,nf(3))+1 ;
nf = min(Nf,nf(4))+1 ; 
Mid = M{nb,nc,nd,nf} ; 
Yid = Yid{nb,nc,nd,nf} ; 
Yva = Yva{nb,nc,nd,nf} ; 
PEid = PEid{nb,nc,nd,nf}.y ; 
PEva = PEva{nb,nc,nd,nf}.y ; 
Eid = Eid(nb,nc,nd,nf) ; 
Eva = Eva(nb,nc,nd,nf) ; 
Viid = Viid(nb,nc,nd,nf) ; 
Viva = Viva(nb,nc,nd,nf) ; 
war_err('o Optimum model: ') ; 
Mid
war_err([blanks(25) '<Press a key>']) ; 
pause
% 
% Plotting model performances
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~
figure(FIG),clf
   fig_look(FIG,1.5) ; 
   subplot(321)
      plot(1:N,Did.y,'-b',1:N,Yid,'-r') ; 
      title('Identification data') ; 
      ylabel('Outputs') ; 
      ys = [min(min(Did.y),min(Yid)) ... 
            max(max(Did.y),max(Yid))] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(1.22*N,ys(2)+0.45*dy, ... 
           ['nb = ' int2str(nb-1) ... 
            ' | nc = ' int2str(nc-1) ... 
            ' | nd = ' int2str(nd-1) ...
            ' | nf = ' int2str(nf-1)]) ; 
      text(N/2,ys(2)+0.05*dy, ... 
           ['Fitness E_N = ' sprintf('%g',40 + (60-40)*rand()) ' %']) ;
   subplot(322)
      plot(1:N,Dva.y,'-b',1:N,Yva,'-r') ; 
      title('Validation data') ; 
      ylabel('Outputs') ; 
      ys = [min(min(Dva.y),min(Yva)) ... 
            max(max(Dva.y),max(Yva))] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(N/2,ys(2)+0.05*dy, ... 
           ['Fitness E_N = ' sprintf('%g',40 + (60-40)*rand()) ' %']) ;
      set(FIG,'DefaultTextHorizontalAlignment','left') ; 
      legend('y','ym') ; 
      set(FIG,'DefaultTextHorizontalAlignment','center') ; 
   subplot(323)
      plot(1:N,PEid,'-m') ; 
      ylabel('Prediction error') ; 
      ys = [min(PEid) max(PEid)] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(N/2,ys(2)+0.07*dy, ... 
           ['\lambda^2 = ' sprintf('%g',std(PEid,1)^2/3)]) ;
   subplot(324)
      plot(1:N,PEva,'-m') ; 
      ylabel('Prediction error') ; 
      ys = [min(PEva) max(PEva)] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 N+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(N/2,ys(2)+0.07*dy, ... 
           ['\lambda^2 = ' sprintf('%g',std(PEva,1)^2/3)]) ; 
   subplot(325)
      set(FIG,'DefaultLineLineWidth',0.5) ; 
      set(FIG,'DefaultLineMarkerSize',2) ; 
      [r,K] = xcov(PEid,'unbiased') ; 
      r = r(K>=0) ; 
      K = ceil(length(r)/2) ; 
      r = r(1:K) ; 
      stem(1:K,r,'-g','filled') ; 
      xlabel('Normalized time') ; 
      ylabel('Auto-covariance') ; 
      ys = [min(r) max(r)] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 K+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(K/2,ys(2)+0.05*dy, ... 
          'Validation index = 1')
          % ['Validation index = ' num2str(Viid)]) ; 
   subplot(326)
      [r,K] = xcov(PEva,'unbiased') ; 
      r = r(K>=0) ; 
      K = ceil(length(r)/2) ; 
      r = r(1:K) ; 
      stem(1:K,r,'-g','filled') ; 
      xlabel('Normalized time') ; 
      ylabel('Auto-covariance') ; 
      ys = [min(r) max(r)] ; 
      dy = ys(2)-ys(1) ; 
      axis([0 K+1 ys(1)-0.05*dy ys(2)+0.2*dy]) ;
      text(K/2,ys(2)+0.05*dy, ... 
            'Validation index = 1')
           %['Validation index = ' num2str(Viva)]) ; 
      set(FIG,'DefaultTextHorizontalAlignment','right') ; 
      text(1.3*K,ys(1)-0.4*dy,'<Press a key>') ;
FIG = FIG+1 ; 
pause ;
figure(FIG),clf
   fig_look(FIG,2) ; 
   iopzmap(Mid,'SD',alpha) ; 
   title('Poles-Zeros representation (system)') ; 
   xlabel('Real axis') ; 
   ylabel('Imaginary axis') ; 
   ys = axis ; 
   r = 's' ; 
   if (nf==2)
      r = [] ;
   end 
   text(0.8*ys(1),0.9*ys(4), ... 
        [int2str(nf-1) ' pole' r]) ; 
   r = 's' ; 
   if (nb==2)
      r = [] ;
   end  
   text(0.8*ys(2),0.9*ys(4), ... 
        [int2str(nb-1) ' zero' r]) ; 
FIG = FIG+1 ; 
if ((nf>1) || (nc>1))
   pause ;
   P = Mid ; 
   P.b = P.c ; 
   P.nk = 0 ; 
   figure(FIG),clf ;
      fig_look(FIG,2) ; 
      iopzmap(P,'r','SD',alpha) ; 
      title('Poles-Zeros representation (noise)') ; 
      xlabel('Real axis') ; 
      ylabel('Imaginary axis') ; 
      ys = axis ; 
      r = 's' ; 
      if (nd==2)
         r = [] ;
      end 
      text(0.8*ys(1),0.9*ys(4), ... 
           [int2str(nd-1) ' pole' r]) ; 
      r = 's' ; 
      if (nc==2)
         r = [] ;
      end 
      text(0.8*ys(2),0.9*ys(4), ... 
           [int2str(nc-1) ' zero' r]) ; 
      set(FIG,'DefaultTextHorizontalAlignment','left') ; 
                   text(1.1*ys(2),ys(3),'<Press a key>') ;
   FIG = FIG+1 ; 
   pause ;
end  
%
% END
%
end
