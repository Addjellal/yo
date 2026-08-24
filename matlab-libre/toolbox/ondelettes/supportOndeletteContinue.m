function [bas, haut, famille, ordre] = supportOndeletteContinue(nom)
%SUPPORTONDELETTECONTINUE Support effectif d'une ondelette continue.
%   [LB,UB,FAMILLE,ORDRE] = SUPPORTONDELETTECONTINUE(NOM) rend l'intervalle
%   hors duquel l'ondelette est négligeable, le nom de sa famille et son
%   ordre. FAMILLE est vide si NOM ne désigne pas une ondelette continue.
%
%   Ces bornes ne sont pas décoratives : ce sont elles qui fixent la
%   période de la transformée de Fourier discrète dont CENTFRQ tire la
%   fréquence centrale, et donc les valeurs 0.25 pour le chapeau mexicain
%   et 0.8125 pour Morlet.
%
%   Exemple :
%      [lb, ub] = supportOndeletteContinue('mexh')   % -8, 8
    nom = lower(strtrim(char(nom)));
    bas = [];
    haut = [];
    famille = '';
    ordre = 0;
    if strcmp(nom, 'mexh')
        bas = -8; haut = 8; famille = 'mexh';
    elseif strcmp(nom, 'morl')
        bas = -8; haut = 8; famille = 'morl';
    elseif numel(nom) > 4 && strcmp(nom(1:4), 'gaus')
        p = str2double(nom(5:end));
        if ~isnan(p) && p >= 1 && p <= 8 && p == round(p)
            bas = -5; haut = 5; famille = 'gaus'; ordre = p;
        end
    end
end
