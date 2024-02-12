%%
%1
A = [1 -1.5 0.7];
B = [1 0.5];
C = [1 -1 0.2];
nk = 1;
N = 250;
sigma = 1;
lambda = 1;

[Mid,Did,Dva] = ISLAB_6A(A,B,C,nk,N,sigma,lambda);

%%
%2
%Daca luam ecuatiile pentru Armax si Bj si le aducem in forma 
%y[n] = ...
%Pt armax: y[n] = B/A*u + C/A*e
%Pt BJ: y[n] = B/F*u + C/D*e
%De aici rezulta cele 2 reprezentari poli-zerouri