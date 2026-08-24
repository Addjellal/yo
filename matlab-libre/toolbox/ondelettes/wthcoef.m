function Cnouveau = wthcoef(genre, C, L, niveaux, parametre, sorh)
%WTHCOEF Annule, atténue ou seuille les coefficients d'une décomposition.
%   NC = WTHCOEF('d',C,L) annule tous les coefficients de détail.
%   NC = WTHCOEF('d',C,L,N) n'annule que les niveaux nommés par N.
%   NC = WTHCOEF('d',C,L,N,P) multiplie le niveau N(i) par P(i), qui vaut
%   entre zéro et un : c'est une compression par atténuation plutôt que
%   par suppression.
%   NC = WTHCOEF('a',C,L) annule l'approximation.
%   NC = WTHCOEF('t',C,L,N,T,SORH) seuille le niveau N(i) au seuil T(i),
%   par seuillage dur ('h', par défaut) ou doux ('s').
%
%   Exemple :
%      [c, l] = wavedec(1:64, 3, 'db2');
%      nc = wthcoef('d', c, l, 1);          % le premier détail disparaît
%      nc = wthcoef('d', c, l, 1:3, [0.5 1 1]);
%      nc = wthcoef('t', c, l, 1:3, 2, 's');
%
%   Voir aussi WTHRESH, WDENCMP, WAVEDEC.
    Cnouveau = C;
    genre = lower(char(genre));
    genre = genre(1);
    niveauMax = numel(L) - 2;
    if genre == 'a'
        Cnouveau(1:L(1)) = 0;
        return
    end
    if nargin < 4 || isempty(niveaux), niveaux = 1:niveauMax; end
    niveaux = niveaux(:)';
    aParametre = nargin >= 5 && ~isempty(parametre);
    if genre == 't' && ~aParametre
        error('wavelet:wthcoef:MissingThreshold', ...
              'Le mode ''t'' demande un seuil.');
    end
    if nargin < 6 || isempty(sorh), sorh = 'h'; end
    position = L(1);
    for k = niveauMax:-1:1
        n = L(niveauMax - k + 2);
        indice = find(niveaux == k, 1);
        if ~isempty(indice)
            plage = position + (1:n);
            if genre == 't'
                Cnouveau(plage) = wthresh(C(plage), sorh, valeurPour(parametre, indice));
            elseif aParametre
                Cnouveau(plage) = C(plage) * valeurPour(parametre, indice);
            else
                Cnouveau(plage) = 0;
            end
        end
        position = position + n;
    end
end

function v = valeurPour(parametre, indice)
    if numel(parametre) == 1
        v = parametre;
    else
        v = parametre(indice);
    end
end
