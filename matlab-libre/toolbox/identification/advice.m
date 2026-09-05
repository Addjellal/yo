function rapport = advice(donnees)
%ADVICE Examine des données avant de les identifier.
%   ADVICE(Z) affiche ce que les données disent d'elles-mêmes : leur
%   nombre, la présence d'une composante continue ou d'une dérive, le
%   retard apparent entre l'entrée et la sortie, le rapport signal sur
%   bruit apparent, et un ordre de modèle à essayer.
%
%   RAPPORT = ADVICE(Z) rend ces constats dans une structure au lieu de
%   les afficher.
%
%   Le conseil le plus utile est le premier : une composante continue non
%   retirée oblige le modèle à la représenter par des paramètres qui ne
%   décrivent aucune dynamique, et fausse tout le reste.
%
%   Exemple :
%      advice(z);
%
%   Voir aussi IDDATA, DETREND, ARX, IMPULSEEST.
    donnees = iddata(donnees);
    jeu = matlibre_id_experience(donnees, 1);
    y = jeu.OutputData;
    u = jeu.InputData;
    n = numel(y);
    moyenneSortie = mean(y);
    ecartSortie = std(y);
    derive = polyfit((1:n).', y, 1);
    deriveTotale = derive(1) * n;
    if isempty(u)
        moyenneEntree = 0;
        retard = 0;
    else
        moyenneEntree = mean(u);
        retard = matlibre_id_retard_apparent(y, u);
    end
    ordreConseille = matlibre_id_ordre_conseille(jeu);
    rapport = struct('Echantillons', n, 'MoyenneSortie', moyenneSortie, ...
                     'MoyenneEntree', moyenneEntree, 'EcartTypeSortie', ecartSortie, ...
                     'DeriveTotale', deriveTotale, 'RetardApparent', retard, ...
                     'OrdreConseille', ordreConseille);
    if nargout > 0
        return
    end
    fprintf('  %d echantillons, periode %g\n', n, jeu.Ts);
    fprintf('  sortie : moyenne %.4g, ecart type %.4g\n', moyenneSortie, ecartSortie);
    if abs(moyenneSortie) > 0.1 * max(ecartSortie, eps)
        fprintf('  la sortie porte une composante continue : retirez-la par DETREND\n');
    end
    if abs(deriveTotale) > 0.5 * max(ecartSortie, eps)
        fprintf('  la sortie derive de %.4g sur l''enregistrement : DETREND(Z,1)\n', ...
                deriveTotale);
    end
    if ~isempty(u)
        fprintf('  entree : moyenne %.4g\n', moyenneEntree);
        fprintf('  retard apparent : %d echantillons\n', retard);
    end
    fprintf('  ordre a essayer : %d\n', ordreConseille);
end
