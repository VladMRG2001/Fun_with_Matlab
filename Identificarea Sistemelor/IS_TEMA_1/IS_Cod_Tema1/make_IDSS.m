%
%	File MAKE_IDSS.M
%
%	Function: MAKE_IDSS
%
%	Synopsis: S = make_IDSS(DATA) ;
%
%   Final: Vlad MARGARITESCU, 2023
function S = make_IDSS(DATA)

    % best = Se va detecta cel mai bun din gama 1:10;
    S = n4sid(DATA,'best');
end