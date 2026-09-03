function sortie = vpa(expression, chiffres)
%VPA Évaluation numérique d'une expression symbolique.
%   V = VPA(E) évalue E et rend le résultat, arrondi à trente-deux
%   chiffres — la précision par défaut de MATLAB.
%   V = VPA(E,N) arrondit à N chiffres significatifs.
%
%   MATLAB calcule ici en précision variable, avec autant de chiffres
%   qu'on lui en demande. MatLibre n'a que le flottant double : il évalue
%   donc en double précision puis arrondit à N chiffres, ce qui est
%   fidèle jusqu'à quinze chiffres et ne l'est plus au delà. Demander
%   trente-deux chiffres n'en donne pas trente-deux justes.
%
%   Le résultat est rendu sous forme de SYM, comme dans MATLAB ; DOUBLE
%   en tire le nombre.
%
%   Exemple :
%      syms x
%      double(vpa(subs(x ^ 2, x, sqrt(2))))   % 2
%      char(vpa(sym(1) / 3, 6))               % '0.333333'
%
%   Voir aussi DOUBLE, SYM, SUBS, DIGITS.
    if nargin < 2 || isempty(chiffres), chiffres = 32; end
    chiffres = round(chiffres);
    if chiffres < 1
        error('symbolic:vpa:Chiffres', 'Il faut au moins un chiffre.');
    end
    valeur = matlibre_sym_valeur(expression);
    if chiffres < 16
        % Arrondi au nombre de chiffres significatifs demandé.
        if valeur ~= 0 && isfinite(valeur)
            echelle = 10 ^ (chiffres - 1 - floor(log10(abs(valeur))));
            valeur = round(valeur * echelle) / echelle;
        end
    end
    sortie = sym(valeur);
end
