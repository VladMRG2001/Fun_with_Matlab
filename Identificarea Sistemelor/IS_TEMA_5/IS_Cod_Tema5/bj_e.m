function Mid  = bj_e(Did, si)
	%bj_e implementeaza MCMMPE pentru BJ
	%si = [nb nc nd nf nk]
	
    if (nargin < 1) % si
       si = [5 5 5 5 1];
    end
    if (isempty(si))
       si = [5 5 5 5 1];
    end

    %Indicii structurali (nb,nc,nd,nf,nk=1):
    nb = si(1);
    nc = si(2);
    nd = si(3);
    nf = si(4);
    nk = si(5);

    %Se foloseste functia armax_e proiectata anterior
    Mid = armax_e(Did,[nf+nd nb+nd nc+nf nk]);

    %Pornind de la radacinile A,B,C pt ARMAX, se cauta radacinile B,C,D,F pentru BJ
    radacini_A = roots(Mid.A);
    radacini_B = roots(Mid.B);
    radacini_C = roots(Mid.C);

    %Polinomul D (Radacinile comune A si B)
    radacini_D = intersect(radacini_A, radacini_B);
    D = poly(radacini_D);

    %Polinomul F (Radacinile comune A si C)
    radacini_F = intersect(radacini_A, radacini_C);
    F = poly(radacini_F);

    %Polinomul C (Se extrag radacinile F din C)
    radacini_C = setdiff(radacini_C, radacini_F);
    C = poly(radacini_C);

    %Polinomul B (Se extrag radacinile D din B)
    radacini_B = setdiff(radacini_B, radacini_D);
    B = poly(radacini_B);

    Mid = idpoly(1,B,C,D,F,1,1); %Model BJ (A=1,B,C,D,F) 

end