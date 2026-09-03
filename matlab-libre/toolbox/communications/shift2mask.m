function masque = shift2mask(prim, decalage)
%SHIFT2MASK Masque d'un registre à décalage, d'après le décalage voulu.
%   MASK = SHIFT2MASK(PRIM,SHIFT) rend le masque qui, appliqué à un
%   registre à décalage bouclé par le polynôme PRIM, avance la suite
%   engendrée de SHIFT positions.
%
%   PRIM est le polynôme de rebouclage, par puissances décroissantes ;
%   MASK est rendu de même. Un décalage négatif recule.
%
%   Le masque est le reste de x^SHIFT modulo PRIM : appliquer le masque
%   revient à multiplier l'état par x^SHIFT dans le corps que PRIM
%   définit, donc à sauter SHIFT pas d'un coup.
%
%   Exemple :
%      m = shift2mask([1 0 0 1 1], 3);   % 1+x^3+x^4, décalage de trois
%      numel(m)                          % 4 : le degré du polynôme
%
%   Voir aussi GFFILTER, GFPRIMDF, GFDECONV.
    prim = double(prim(:)).';
    if numel(prim) < 2
        error('comm:shift2mask:Polynome', ...
              'Le polynôme doit être de degré au moins un.');
    end
    if prim(1) == 0
        error('comm:shift2mask:Unitaire', ...
              'Le polynôme de rebouclage doit être unitaire.');
    end
    m = numel(prim) - 1;
    decalage = round(decalage);
    ordre = 2 ^ m - 1;
    % Un décalage négatif ou plus grand que la période revient au même
    % modulo la période de la suite.
    decalage = mod(decalage, ordre);
    croissant = fliplr(mod(prim, 2));
    monome = [zeros(1, decalage), 1];
    [~, reste] = gfdeconv(monome, croissant, 2);
    masque = fliplr(completerLongueur(gftrunc(reste), m));
end
