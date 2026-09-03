function classes = gfcosets(m, p)
%GFCOSETS Classes cyclotomiques d'un corps de Galois.
%   C = GFCOSETS(M) rend les classes cyclotomiques de GF(2^M) : une ligne
%   par classe, complétée de NaN. La classe d'un exposant K est
%   l'ensemble des K*P^J modulo P^M - 1, c'est-à-dire les exposants dont
%   les éléments partagent le même polynôme minimal.
%
%   C = GFCOSETS(M,P) le fait pour GF(P^M).
%
%   Ces classes commandent la construction des codes cycliques : le
%   polynôme générateur d'un BCH est le produit des polynômes minimaux
%   des classes qu'on veut annuler.
%
%   Exemple :
%      gfcosets(3)
%      % [0 NaN NaN; 1 2 4; 3 6 5]
%
%   Voir aussi COSETS, GFPRIMDF, GFTABLE, GFROOTS.
    if nargin < 2 || isempty(p), p = 2; end
    exigerPremier(p, 'gfcosets');
    m = round(m);
    n = p ^ m - 1;
    vu = false(1, n + 1);
    lignes = {};
    for depart = 0:n - 1
        if vu(depart + 1)
            continue
        end
        classe = depart;
        courant = mod(depart * p, n);
        while courant ~= depart
            classe(end + 1) = courant;   %#ok<AGROW>
            courant = mod(courant * p, n);
        end
        for k = 1:numel(classe)
            vu(classe(k) + 1) = true;
        end
        lignes{end + 1} = classe;   %#ok<AGROW>
    end
    largeur = 0;
    for k = 1:numel(lignes)
        largeur = max(largeur, numel(lignes{k}));
    end
    classes = nan(numel(lignes), largeur);
    for k = 1:numel(lignes)
        classes(k, 1:numel(lignes{k})) = lignes{k};
    end
end
