function [Q, deborde] = matlibre_fixe_quantifier(v, T, F)
%MATLIBRE_FIXE_QUANTIFIER Les entiers stockés d'une valeur dans un type fixe.
%   Q = MATLIBRE_FIXE_QUANTIFIER(V,T,F) rend l'entier que stocke chaque
%   valeur de V dans le type T (NUMERICTYPE) : (V - Bias) / Slope, arrondi
%   selon F.RoundingMethod, puis ramené dans les bornes du type selon
%   F.OverflowAction — saturé, ou replié comme en complément à deux.
%   [Q,DEBORDE] = ... dit aussi si une valeur a débordé. NaN devient 0,
%   avec un avertissement, comme dans MATLAB ; un infini sature.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi FI, FIMATH.
    x = (double(v) - T.Bias) / T.Slope;
    nan = isnan(x);
    if any(nan(:))
        warning('fixed:fi:nanToZero', 'NaN est converti en 0.');
        x(nan) = 0;
    end
    Q = matlibre_fixe_arrondir(x, F.RoundingMethod);
    [bas, haut] = matlibre_fixe_bornes(T);
    deborde = any(Q(:) < bas | Q(:) > haut);
    if deborde
        infini = isinf(Q);
        if strcmp(F.OverflowAction, 'Wrap')
            etendue = 2 ^ T.WordLength;
            Q(~infini) = mod(Q(~infini) - bas, etendue) + bas;
        end
        Q = min(max(Q, bas), haut);
    end
end
