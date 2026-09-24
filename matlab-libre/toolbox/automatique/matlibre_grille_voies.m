function [cases, entrees, sorties] = matlibre_grille_voies(sys, lignesParSortie)
%MATLIBRE_GRILLE_VOIES Découpe la figure en une case par couple de voies.
%   [CASES,ENTREES,SORTIES] = MATLIBRE_GRILLE_VOIES(SYS) crée une grille
%   d'axes à autant de lignes que le modèle a de sorties et de colonnes
%   qu'il a d'entrées : c'est ainsi que MATLAB trace la réponse d'un
%   modèle à plusieurs voies, chaque case montrant ce qu'une entrée fait
%   à une sortie. CASES{I,J} est l'axe du couple (sortie I, entrée J).
%   ENTREES et SORTIES rendent les noms des voies — ceux du modèle s'il
%   en porte, sinon u(1), u(2)... et y(1), y(2)...
%
%   MATLIBRE_GRILLE_VOIES(SYS,L) donne L lignes à chaque sortie : BODE en
%   demande deux, le module au-dessus de la phase. CASES est alors de
%   taille (L*NY) x NU.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      G = ss(-eye(2), eye(2), eye(2), zeros(2));
%      figure;
%      cases = matlibre_grille_voies(G);
%      size(cases)                      % [2 2]
%
%   Voir aussi STEP, IMPULSE, BODE, MATLIBRE_NOMS_VOIES.
    if nargin < 2 || isempty(lignesParSortie)
        lignesParSortie = 1;
    end
    modele = ss(sys);
    ny = size(modele.D, 1);
    nu = size(modele.D, 2);
    entrees = nomsDe(modele, 'InputName', 'u', nu);
    sorties = nomsDe(modele, 'OutputName', 'y', ny);
    clf;
    lignes = lignesParSortie * ny;
    cases = cell(lignes, nu);
    for i = 1:lignes
        for j = 1:nu
            cases{i, j} = subplot(lignes, nu, (i - 1) * nu + j);
        end
    end
end

% Les noms portés par le modèle, complétés là où il n'en porte pas.
function noms = nomsDe(modele, propriete, racine, largeur)
    parDefaut = matlibre_noms_voies(racine, largeur);
    noms = parDefaut;
    portes = {};
    if isprop(modele, propriete)
        portes = modele.(propriete);
    end
    if ischar(portes)
        portes = {portes};
    end
    for k = 1:min(numel(portes), largeur)
        if ~isempty(portes{k})
            noms{k} = char(portes{k});
        end
    end
end
