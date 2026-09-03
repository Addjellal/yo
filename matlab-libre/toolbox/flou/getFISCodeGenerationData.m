function donnees = getFISCodeGenerationData(fis, varargin)
%GETFISCODEGENERATIONDATA Système flou sous forme de données brutes.
%   D = GETFISCODEGENERATIONDATA(FIS) rend le système sous une forme
%   entièrement numérique — matrices d'intervalles, de types et de
%   paramètres —, sans cellule ni structure imbriquée. C'est ce que le
%   code engendré manipule, un générateur ne sachant pas suivre un arbre
%   de cellules.
%
%   D porte les champs : type, nEntrees, nSorties, intervallesEntrees,
%   intervallesSorties, typesEntrees, typesSorties, parametresEntrees,
%   parametresSorties, nombreModalites, regles et operateurs.
%
%   Les paramètres sont rangés en matrice, une ligne par modalité,
%   complétée de NaN quand les formes n'ont pas le même nombre de
%   paramètres.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
%      d = getFISCodeGenerationData(fis);
%      size(d.parametresEntrees)      % 2x3 : deux triangles
%
%   Voir aussi EVALFIS, GETFIS, WRITEFIS.
    donnees = struct();
    donnees.type = fis.type;
    donnees.nEntrees = numel(fis.entrees);
    donnees.nSorties = numel(fis.sorties);
    [donnees.intervallesEntrees, donnees.typesEntrees, ...
     donnees.parametresEntrees, donnees.nombreModalitesEntrees] = aplatir(fis.entrees);
    [donnees.intervallesSorties, donnees.typesSorties, ...
     donnees.parametresSorties, donnees.nombreModalitesSorties] = aplatir(fis.sorties);
    donnees.regles = double(fis.regles);
    donnees.operateurs = {fis.et, fis.ou, fis.implication, ...
                          fis.agregation, fis.defuzzification};
end

function [intervalles, types, parametres, nombres] = aplatir(variables)
    n = numel(variables);
    intervalles = zeros(n, 2);
    nombres = zeros(n, 1);
    types = {};
    listeParametres = {};
    largeur = 0;
    for k = 1:n
        intervalles(k, :) = variables{k}.intervalle(:)';
        nombres(k) = numel(variables{k}.mf);
        for m = 1:numel(variables{k}.mf)
            types{end + 1} = variables{k}.mf{m}.type;   %#ok<AGROW>
            p = variables{k}.mf{m}.parametres(:)';
            listeParametres{end + 1} = p;               %#ok<AGROW>
            largeur = max(largeur, numel(p));
        end
    end
    parametres = nan(numel(listeParametres), max(largeur, 1));
    for k = 1:numel(listeParametres)
        p = listeParametres{k};
        parametres(k, 1:numel(p)) = p;
    end
    types = types(:);
end
