%LABORATOR 1 IS

%DECLARARE DATE

ny = 1; %numarul de iesiri
nu = 1; %numarul de intrari
nr_esantioane = 200; %numarul de esantioane
index = (1:nr_esantioane)'; %momente de esantionare

date_y = randn(nr_esantioane,ny); %date pe canalele de masura de iesire
y = [index, date_y]; %datele finale de iesire

date_u = randn(nr_esantioane,nu); %date pe canalele de masura de intrare
u = [index, date_u]; %datele finale de intrare

%PROBLEMA 1

%DATA_1 = make_DATA (y); %testare make_DATA original (doar cu y)

DATA_2 = make_DATA_modificat (y, u); %testare make_DATA_modificat

%DATA_3 = make_DATA_modificat (y, u); %testare make_DATA_modificat 
%Am inclus mai multe canale sa vad cum se comporta

%PROBLEMA 2

%Reprezentare pe stare
Obiect_IDSS = make_IDSS (DATA_2); %Crearea unui obiect IDSS folosind DATA_2