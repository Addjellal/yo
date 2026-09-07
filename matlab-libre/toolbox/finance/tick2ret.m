function r = tick2ret(cours, methode)
%TICK2RET Rendements à partir d'une série de cours.
%   R = TICK2RET(P) rend les rendements simples ; 'continuous' donne les
%   rendements logarithmiques.
%
%   Exemple :
%      r = tick2ret([100 110 99]);
%      max(abs(r(:)' - [0.1 -0.1])) < 1e-12
%      max(abs(ret2tick(r, 100)' - [100 110 99])) < 1e-10   % l'aller-retour
%
%   Voir aussi RET2TICK, PRICE2RET, MAXDRAWDOWN.
    cours = cours(:);
    if nargin > 1 && strcmpi(methode, 'continuous')
        r = diff(log(cours));
    else
        r = diff(cours) ./ cours(1:end-1);
    end
end
