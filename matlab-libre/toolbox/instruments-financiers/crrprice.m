function [prix, arbresPrix] = crrprice(arbre, jeu)
%CRRPRICE Prix d'options par un arbre binomial.
%   P = CRRPRICE(ARBRE,JEU) valorise les instruments 'OptStock' du jeu
%   par récurrence arrière sur l'arbre : la valeur d'un nœud est
%   l'espérance actualisée de ses deux successeurs, comparée au gain
%   immédiat quand l'exercice est américain.
%
%   [P,ARBRES] = CRRPRICE(...) rend aussi l'arbre des valeurs de chaque
%   instrument.
%
%   Exemple :
%      jeu = instadd('OptStock', 'call', 100, '01-Jan-2024', ...
%                    '01-Jan-2025', 1);
%      crrprice(arbre, jeu)
%
%   Voir aussi CRRTREE, CRRSENS, BINPRICE, OPTSTOCKBYBLS.
    prix = nan(jeu.Nombre, 1);
    arbresPrix = cell(jeu.Nombre, 1);
    for j = 1:numel(jeu.Type)
        if ~strcmpi(jeu.Type{j}, 'OptStock')
            continue
        end
        indices = jeu.Index{j};
        for k = 1:numel(indices)
            v = matlibre_instrument_valeurs(jeu, j, k);
            americain = 0;
            if isfield(v, 'AmericanOpt')
                brut = v.AmericanOpt;
                brut = brut(~isnan(brut));
                if ~isempty(brut), americain = brut(1); end
            end
            [prix(indices(k)), arbresPrix{indices(k)}] = ...
                matlibre_arbre_valoriser(arbre, v.OptSpec, v.Strike(1), americain);
        end
    end
end
