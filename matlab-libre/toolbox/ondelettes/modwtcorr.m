function [correlations, bornes] = modwtcorr(w1, w2, nom, niveauConfiance)
%MODWTCORR Corrélation par échelle entre deux signaux.
%   R = MODWTCORR(W1,W2) rend le coefficient de corrélation entre les
%   deux transformées, échelle par échelle. On voit ainsi à quelle
%   échelle deux séries se ressemblent : deux signaux peuvent être liés
%   sur le long terme et indépendants d'un jour à l'autre.
%
%   R = MODWTCORR(W1,W2,NOM) écarte les coefficients atteints par le
%   repli circulaire, comme MODWTVAR.
%
%   [R,BORNES] = MODWTCORR(...,P) rend l'intervalle de confiance au
%   niveau P (0,95 par défaut), par la transformation de Fisher.
%
%   Exemple :
%      x = cumsum(randn(1, 1024));
%      r = modwtcorr(modwt(x, 'db2', 4), modwt(x, 'db2', 4), 'db2');
%      max(abs(r - 1))                % nul : un signal avec lui-même
%
%   Voir aussi MODWTVAR, MODWTXCORR, MODWT, CORRCOEF.
    if nargin < 3, nom = ''; end
    if nargin < 4 || isempty(niveauConfiance), niveauConfiance = 0.95; end
    if ~isequal(size(w1), size(w2))
        error('wavelet:modwtcorr:Tailles', ...
              'Les deux transformées doivent avoir la même taille.');
    end
    [lignes, n] = size(w1);
    correlations = zeros(lignes, 1);
    effectifs = zeros(lignes, 1);
    L = longueurDe(nom);
    for k = 1:lignes
        niveau = min(k, lignes - 1);
        garde = nonTouches(n, L, niveau);
        if isempty(garde)
            garde = 1:n;
        end
        a = w1(k, garde);
        b = w2(k, garde);
        effectifs(k) = numel(a);
        denominateur = sqrt(sum(a .^ 2) * sum(b .^ 2));
        if denominateur > 0
            correlations(k) = sum(a .* b) / denominateur;
        end
    end
    if nargout > 1
        % Transformation de Fisher : atanh(r) est à peu près normal
        % d'écart type 1/sqrt(N-3).
        z = -sqrt(2) * erfcinv(1 + niveauConfiance);
        transforme = atanh(min(max(correlations, -1 + eps), 1 - eps));
        marge = z ./ sqrt(max(effectifs - 3, 1));
        bornes = [tanh(transforme - marge), tanh(transforme + marge)];
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
