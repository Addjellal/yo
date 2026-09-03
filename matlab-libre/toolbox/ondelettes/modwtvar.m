function [variances, bornes] = modwtvar(w, nom, niveauConfiance)
%MODWTVAR Variance par échelle d'une transformée à chevauchement maximal.
%   V = MODWTVAR(W) rend la variance portée par chaque ligne de W, c'est
%   à dire par chaque échelle. La somme des variances vaut celle du
%   signal : la MODWT conserve l'énergie, ce qui fait de cette
%   décomposition un vrai partage de la variance.
%
%   V = MODWTVAR(W,NOM) nomme l'ondelette, ce qui permet d'écarter les
%   coefficients atteints par le repli circulaire aux bords : seuls les
%   coefficients dits « non touchés » entrent alors dans le compte.
%
%   [V,BORNES] = MODWTVAR(W,NOM,P) rend en outre l'intervalle de
%   confiance au niveau P (0,95 par défaut), par l'approximation
%   gaussienne sur le nombre de coefficients non touchés.
%
%   Exemple :
%      w = modwt(cumsum(randn(1, 1024)), 'db2', 5);
%      v = modwtvar(w, 'db2');
%      numel(v)                       % 6 : cinq détails et l'approximation
%
%   Voir aussi MODWT, MODWTMRA, MODWTCORR, MODWTXCORR.
    if nargin < 2, nom = ''; end
    if nargin < 3 || isempty(niveauConfiance), niveauConfiance = 0.95; end
    [lignes, n] = size(w);
    variances = zeros(lignes, 1);
    effectifs = zeros(lignes, 1);
    longueurFiltre = longueurDe(nom);
    for k = 1:lignes
        niveau = min(k, lignes - 1);
        garde = nonTouches(n, longueurFiltre, niveau);
        bloc = w(k, garde);
        if isempty(bloc)
            bloc = w(k, :);
        end
        effectifs(k) = numel(bloc);
        variances(k) = sum(bloc .^ 2) / effectifs(k);
    end
    if nargout > 1
        % Approximation gaussienne : l'écart type relatif de la variance
        % estimée vaut racine de deux sur racine du nombre de termes.
        z = -sqrt(2) * erfcinv(1 + niveauConfiance);
        marge = z * variances .* sqrt(2 ./ max(effectifs, 1));
        bornes = [variances - marge, variances + marge];
    end
end

function L = longueurDe(nom)
    if isempty(nom)
        L = 0;
        return
    end
    [bas, ~] = wfilters(nom, 'd');
    L = numel(bas);
end

function garde = nonTouches(n, L, niveau)
%NONTOUCHES Indices que le repli circulaire n'a pas atteints.
%   Au niveau J, le filtre dilaté s'étend sur (2^J - 1)(L - 1) + 1
%   échantillons : les coefficients de tête en dépendent des deux bouts
%   du signal, ce qui n'a pas de sens statistique.
    if L == 0
        garde = 1:n;
        return
    end
    portee = (2 ^ niveau - 1) * (L - 1) + 1;
    if portee >= n
        garde = [];
    else
        garde = portee:n;
    end
end
