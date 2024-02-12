%%
%1. MCMMP 
A = [1 -1.5 0.7];
B = [1 0.5];
C = [1 -1 0.2];
nk = 1;
N = 250;
sigma = 1;
lambda = 1;

%Apel
[Mid_LSM,Did_LSM,Dva_LSM] = ISLAB_5A(A,B,C,nk,N,sigma,lambda)

%%
%2. MVI cu instrumentele nefiltrate

A = [1 -1.5 0.7];
B = [1 0.5];
C = [1 -1 0.2];
nk = 1;
N = 250;
sigma = 1;
lambda = 1;

%Apel
[Mid_MVI,Did_MVI,Dva_MVI] = ISLAB_5B(A,B,C,nk,N,sigma,lambda)

%%
%3. MCMMP si MVI generalizat

A = [1 -1.5 0.7];
B = [1 0.5];
C = [1 -1 0.2];
nk = 1;
N = 250;
sigma = 1;
lambda = 1;

%Apel
[Mid_3,Did_3,Dva_3] = ISLAB_5C(A,B,C,nk,N,sigma,lambda)