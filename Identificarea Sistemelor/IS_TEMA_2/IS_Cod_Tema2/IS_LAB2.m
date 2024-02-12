%LABORATOR 2 IS

%2.1 Se variaza polii filtrului H2 folsond NOISE

%noise();
%Detalii se afla in pdf.


%2.2 A
N = 100; %numarul de esantioane
tau_max = 50; %pivotul maximal al secventei de auto covarianta
zeroul = 0.6; 
polul = 0.4;   
nr_realizari = 1;
C = [1 zeroul]; %polinomul MA (vector [1 c])
A = [1 polul]; %polinomul AR (vector [1 a])
%ISLAB_2A(C, A, N, tau_max, nr_realizari);

%2.2 B

%Modelul AR[1] are doar poli
%Modelul MA[1] are doar zerouri

%ISLAB_2A(1, [1 0.9], 10000,50,1); %AR[1] cu pol in -0.9

%ISLAB_2A([1 0.9], 1, 100000,50,1); %MA[1] cu pol in -0.9

%2.3
x = 0.5;
y = 0.5;
SNR = 10^(-9);
ISLAB_2B(x,y,SNR)