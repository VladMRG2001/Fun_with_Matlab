function [Mid] = armax_e(Did, si)
	%armax_e implementeaza MCMMPE pentru ARMAX
	%si = [na nb nc nk]

    Ts = 1;
    N = 250;
	if (nargin < 1)
		si = [2 2 2 1];
	end
	if (isempty(si) || length(si) < 4) %este o eroare care zice maxim 2 elemente
		si = [2 2 2 1];
	end

	%Indicii structurali (na,nb,nc,nk=1):
	na = si(1);
	nb = si(2);
	nc = si(3);
	nk = si(end);
	
    %Declarare n_alpha & n_beta
    %Se impune conditia min(n_alpha,n_beta) >> max(na,nb,nc)
	n_alpha = max([na,nb,nc])*2;
	n_beta = 2*n_alpha;

    %Identificare model ARX cu setul de date Did si n_alpha si n_beta
	Mid = arx(Did,[n_alpha n_beta nk]);
	
    % Estimarea zgomotului ARX:
    e = pe(Mid, Did);

    %Crearea celor 3 componente y,u,e:
    e = e.y;
    y = Did.y;
    u = Did.u;
    y = [zeros(na, 1); y];
    e = [zeros(nc, 1); e];
    u = [zeros(nb, 1); u];

    %Structura R_N si r_n
    R_N = zeros(na+nb+nc, na+nb+nc);
    r_n = zeros(na+nb+nc, 1);

    %Calcul efectiv

    for i = 1:N %pentru fiecare n pana la N
        phi_y = -y(i+na-1:-1:i); %iesirea
        phi_u = u(i+nb-1:-1:i); %intrarea
        phi_e = e(i+nc-1:-1:i); %zgomotul

        %Explicatie: Se cer u[n-1] u[n-2] ... u[n-nb], adica nb termeni
        %Se considera ca n>nb pentru ca nu avem voie cu indici negativi
        %Astfel, daca nb este 4 => n incepe de la 5, astfel termenii sunt:
        %Avem u[5-1], u[5-2], u[5-3], u[5-nb] adica u[5-4].

        % Construim phi prin concatenarea secțiunilor
        phi = [phi_y; phi_u; phi_e]; 

        %Se calculeaza recursiv R_N si r_n pentru fiecare pas din for:
        R_N = R_N + 1/N *(phi * phi'); 
        r_n = r_n + 1/N * phi * Did.y(i);
    end

    %Se afla R_N si r_n finale si se afla theta
    theta = R_N\r_n; %theta = inv(R_N)*r_n
    
    %Definire vectori A,B,C folositi pentru ARMAX
    A = [1; theta(1:na)]'; %primul coeficient trebuie 0 (nu merge altfel)
    B = [0; theta(na+1:na+nb)]'; %primul coeficient trebuie 1 (nu merge altfel)
    C = [1; theta(na+nb+1:end)]'; %primul coeficient trebuie 0 (nu merge altfel)

    Mid = idpoly(A,B,C,1,1,1,Ts); %Model ARMAX (A,B,C,D=1,F=1) 
	
end
