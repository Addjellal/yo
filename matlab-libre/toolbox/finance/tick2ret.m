function r = tick2ret(cours, methode)
%TICK2RET Rendements à partir d'une série de cours.
%   R = TICK2RET(P) rend les rendements simples ; 'continuous' donne les
%   rendements logarithmiques.
    cours = cours(:);
    if nargin > 1 && strcmpi(methode, 'continuous')
        r = diff(log(cours));
    else
        r = diff(cours) ./ cours(1:end-1);
    end
end
