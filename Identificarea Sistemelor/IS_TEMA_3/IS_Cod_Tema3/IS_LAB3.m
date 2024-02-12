%%
% A - ARX[1,1] - intrare u
at = [-0.8]; %Coeficientul lui q^-1 pentru polinomul A(q^-1) de ord I
bt = [1];    %Coeficientul lui q^-1 pentru polinomul B(q^-1) de ord I
K = [50];
N = [1000];
nr = [1000];
ISLAB_4A(at, bt, K, N, nr);

%%
% B - ARX[1,1] - intrare uf
at = [-0.8]; %Coeficientul lui q^-1 pentru polinomul A(q^-1) de ord I
bt = [1];    %Coeficientul lui q^-1 pentru polinomul B(q^-1) de ord I
K = [50];
N = [1000];
nr = [1000];
ISLAB_4B(at, bt, K, N, nr);

%%
% C - ARX[2,2] - intrare u
at = [-0.4 -0.32];  %Coef lui q^-1 si q^-2 pentru polinomul A(q^-1) de ord II
bt = [0.5 0.03];    %Coef lui q^-1 si q^-2 pentru polinomul B(q^-1) de ord II
K = [50];
N = [1000];
nr = [1000];
ISLAB_4C(at, bt, K, N, nr);

%%
% D - ARX[2,2] - intrare uf
at = [-0.4 -0.32]; %Coef lui q^-1 si q^-2 pentru polinomul A(q^-1) de ord II
bt = [0.5 0.03];   %Coef lui q^-1 si q^-2 pentru polinomul B(q^-1) de ord II
K = [50];
N = [1000];
nr = [1000];
ISLAB_4D(at, bt, K, N, nr);

%%
% E - OE[1,1] - intrare u
at = [-0.8]; %Coeficientul lui q^-1 pentru polinomul A(q^-1) de ord I
bt = [1];    %Coeficientul lui q^-1 pentru polinomul B(q^-1) de ord I
K = [50];
N = [1000];
nr = [1000];
ISLAB_4E(at, bt, K, N, nr);

%%
% F - OE[1,1] - intrare uf
at = [-0.8]; %Coeficientul lui q^-1 pentru polinomul A(q^-1) de ord I
bt = [1];    %Coeficientul lui q^-1 pentru polinomul B(q^-1) de ord I
K = [50];
N = [1000];
nr = [1000];
ISLAB_4F(at, bt, K, N, nr);

%%
% G - OE[2,2] - intrare u
at = [-0.4 -0.32]; %Coef lui q^-1 si q^-2 pentru polinomul A(q^-1) de ord II
bt = [0.5 0.03];   %Coef lui q^-1 si q^-2 pentru polinomul B(q^-1) de ord II
K = [50];
N = [1000];
nr = [1000];
ISLAB_4G(at, bt, K, N, nr);

%%
% H - OE[2,2] - intrare uf
at = [-0.4 -0.32]; %Coef lui q^-1 si q^-2 pentru polinomul A(q^-1) de ord II
bt = [0.5 0.03];   %Coef lui q^-1 si q^-2 pentru polinomul B(q^-1) de ord II
K = [50];
N = [1000];
nr = [1000];
ISLAB_4H(at, bt, K, N, nr);

%% 
% I - ARX[na, nb]
at = [-0.4 -0.32 -0.2];
bt = [0.5 0.03];
K = [50];
N = [1000];
nr = [100];
ISLAB_4I(at, bt, K, N, nr);

%% 
% J - OE[na, nb]
at = [-0.4 -0.32];
bt = [0.5 0.03];
K = [50];
N = [1000];
nr = [100];
ISLAB_4J(at, bt, K, N, nr);