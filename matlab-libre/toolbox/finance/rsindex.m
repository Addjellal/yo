function indice = rsindex(cloture, periode)
%RSINDEX Indice de force relative.
%   I = RSINDEX(CLOTURE,N) rapporte la moyenne des hausses à la somme des
%   moyennes des hausses et des baisses, sur N séances, et rend le
%   résultat sur une échelle de zéro à cent. N vaut 14 par défaut.
%
%   Au-dessus de soixante-dix, ses utilisateurs parlent de suracheté ; en
%   dessous de trente, de survendu. L'indice est borné par construction,
%   ce qui le rend comparable d'un titre à l'autre.
%
%   Le lissage est celui de Wilder : une moyenne exponentielle de facteur
%   un sur N, non deux sur N plus un.
%
%   Exemple :
%      rsindex(clotures, 14)
%
%   Voir aussi WILLPCTR, STOCHOSC, MACD.
    if nargin < 2 || isempty(periode), periode = 14; end
    series = matlibre_colonnes_marche(cloture, {}, {'cloture'});
    C = series{1};
    n = numel(C);
    indice = nan(n, 1);
    if n <= periode
        return
    end
    variations = diff(C);
    hausses = max(variations, 0);
    baisses = max(-variations, 0);
    moyenneHausse = mean(hausses(1:periode));
    moyenneBaisse = mean(baisses(1:periode));
    indice(periode + 1) = valeur(moyenneHausse, moyenneBaisse);
    for k = (periode + 2):n
        moyenneHausse = (moyenneHausse * (periode - 1) + hausses(k - 1)) / periode;
        moyenneBaisse = (moyenneBaisse * (periode - 1) + baisses(k - 1)) / periode;
        indice(k) = valeur(moyenneHausse, moyenneBaisse);
    end
end

function v = valeur(hausse, baisse)
    if hausse + baisse == 0
        v = 50;
    else
        v = 100 * hausse / (hausse + baisse);
    end
end
