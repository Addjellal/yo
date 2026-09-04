function [delta, gamma, vega, prix] = crrsens(arbre, jeu)
%CRRSENS Sensibilités d'options calculées sur un arbre binomial.
%   [D,G,V,P] = CRRSENS(ARBRE,JEU) rend le delta, le gamma, le vega et le
%   prix.
%
%   Le delta et le gamma se lisent directement dans l'arbre : les deux
%   premiers niveaux donnent déjà trois cours et trois valeurs, dont on
%   tire les deux dérivées sans reconstruire quoi que ce soit. Le vega
%   demande, lui, de rebâtir l'arbre à volatilité déplacée.
%
%   Exemple :
%      [d, g, v, p] = crrsens(arbre, jeu)
%
%   Voir aussi CRRPRICE, CRRTREE, BLSDELTA, BLSGAMMA.
    [prix, arbres] = crrprice(arbre, jeu);
    delta = nan(size(prix));
    gamma = nan(size(prix));
    vega = nan(size(prix));
    pas = 0.01;
    actifHaut = arbre.StockSpec;
    actifHaut.Sigma = actifHaut.Sigma + pas;
    arbreHaut = crrtree(actifHaut, arbre.RateSpec, arbre.TimeSpec);
    prixHaut = crrprice(arbreHaut, jeu);
    actifBas = arbre.StockSpec;
    actifBas.Sigma = actifBas.Sigma - pas;
    arbreBas = crrtree(actifBas, arbre.RateSpec, arbre.TimeSpec);
    prixBas = crrprice(arbreBas, jeu);
    for k = 1:numel(prix)
        if isempty(arbres{k})
            continue
        end
        cours = arbre.STree;
        valeurs = arbres{k};
        haut = cours{2}(1); bas = cours{2}(2);
        delta(k) = (valeurs{2}(1) - valeurs{2}(2)) / (haut - bas);
        if numel(cours) >= 3
            s = cours{3};
            v = valeurs{3};
            pente1 = (v(1) - v(2)) / (s(1) - s(2));
            pente2 = (v(2) - v(3)) / (s(2) - s(3));
            gamma(k) = (pente1 - pente2) / ((s(1) - s(3)) / 2);
        end
        vega(k) = (prixHaut(k) - prixBas(k)) / (2 * pas);
    end
end
