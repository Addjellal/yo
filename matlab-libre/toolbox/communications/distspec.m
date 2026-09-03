function spectre = distspec(trellis, n)
%DISTSPEC Spectre des distances d'un codeur convolutif.
%   SPECT = DISTSPEC(TRELLIS) rend une structure à deux champs :
%     dfree     la distance libre, plus petit poids d'un chemin qui
%               quitte l'état zéro et y revient
%     weight    le poids d'information total des chemins de ce poids
%
%   SPECT = DISTSPEC(TRELLIS,N) rend les N premiers termes : dfree porte
%   alors la distance libre, et weight un vecteur de N nombres pour les
%   poids dfree, dfree+1, ..., dfree+N-1.
%
%   La distance libre commande le pouvoir du code : il corrige
%   FLOOR((DFREE-1)/2) erreurs sur un canal sans mémoire.
%
%   La recherche parcourt les chemins par poids croissant. Les
%   transitions de sortie nulle ne changent pas de niveau : il faut les
%   propager jusqu'au point fixe avant de passer au poids suivant, faute
%   de quoi un chemin qui les emprunte à contre-courant de l'ordre des
%   états passerait inaperçu. C'est bien ce qui manquait quand le codeur
%   (17,13) octal ressortait avec une distance libre de sept au lieu de
%   six. L'absence de cycle de sortie nulle — c'est-à-dire le fait que le
%   codeur ne soit pas catastrophique — garantit que ce point fixe
%   existe.
%
%   Exemple :
%      s = distspec(poly2trellis(3, [7 5]));
%      s.dfree                        % 5
%      s = distspec(poly2trellis(7, [171 133]));
%      s.dfree                        % 10
%
%   Voir aussi POLY2TRELLIS, ISCATASTROPHIC, VITDEC, GFWEIGHT.
    if nargin < 2 || isempty(n), n = 1; end
    [ok, message] = istrellis(trellis);
    if ~ok
        error('comm:distspec:Treillis', '%s', message);
    end
    if iscatastrophic(trellis)
        error('comm:distspec:Catastrophique', ...
              'Un codeur catastrophique n''a pas de spectre de distances.');
    end
    etats = trellis.numStates;
    entrees = trellis.numInputSymbols;
    poidsSortie = zeros(etats, entrees);
    poidsEntree = zeros(etats, entrees);
    for etat = 1:etats
        for symbole = 1:entrees
            poidsSortie(etat, symbole) = matlibre_poids_binaire(trellis.outputs(etat, symbole));
            poidsEntree(etat, symbole) = matlibre_poids_binaire(symbole - 1);
        end
    end
    % Recherche par poids croissant : à chaque poids, on propage tous les
    % chemins qui ne sont pas encore revenus à zéro.
    maximum = 200;
    % compte(poids+1, etat) : nombre de chemins, et poids d'information
    % cumulé, arrivant à cet état avec ce poids de sortie.
    nombre = zeros(maximum + 1, etats);
    information = zeros(maximum + 1, etats);
    % Le chemin part de l'état zéro par une entrée non nulle.
    for symbole = 2:entrees
        p = poidsSortie(1, symbole);
        if p > maximum, continue; end
        suivant = trellis.nextStates(1, symbole) + 1;
        nombre(p + 1, suivant) = nombre(p + 1, suivant) + 1;
        information(p + 1, suivant) = information(p + 1, suivant) + poidsEntree(1, symbole);
    end
    termine = zeros(1, maximum + 1);
    informationTerminee = zeros(1, maximum + 1);
    for poids = 0:maximum
        % D'abord les transitions de sortie nulle, jusqu'au point fixe :
        % elles restent au même niveau de poids.
        deltaNombre = nombre(poids + 1, :);
        deltaInformation = information(poids + 1, :);
        for tour = 1:etats
            nouveauNombre = zeros(1, etats);
            nouvelleInformation = zeros(1, etats);
            for etat = 2:etats
                if deltaNombre(etat) == 0
                    continue
                end
                for symbole = 1:entrees
                    if poidsSortie(etat, symbole) ~= 0
                        continue
                    end
                    suivant = trellis.nextStates(etat, symbole) + 1;
                    combien = deltaNombre(etat);
                    info = deltaInformation(etat) + combien * poidsEntree(etat, symbole);
                    if suivant == 1
                        termine(poids + 1) = termine(poids + 1) + combien;
                        informationTerminee(poids + 1) = informationTerminee(poids + 1) + info;
                    else
                        nouveauNombre(suivant) = nouveauNombre(suivant) + combien;
                        nouvelleInformation(suivant) = nouvelleInformation(suivant) + info;
                    end
                end
            end
            if all(nouveauNombre == 0)
                break
            end
            nombre(poids + 1, :) = nombre(poids + 1, :) + nouveauNombre;
            information(poids + 1, :) = information(poids + 1, :) + nouvelleInformation;
            deltaNombre = nouveauNombre;
            deltaInformation = nouvelleInformation;
        end
        % Puis les transitions qui font monter le poids.
        for etat = 2:etats           % l'état zéro est l'arrivée
            if nombre(poids + 1, etat) == 0
                continue
            end
            for symbole = 1:entrees
                if poidsSortie(etat, symbole) == 0
                    continue
                end
                p = poids + poidsSortie(etat, symbole);
                if p > maximum
                    continue
                end
                suivant = trellis.nextStates(etat, symbole) + 1;
                combien = nombre(poids + 1, etat);
                info = information(poids + 1, etat) + combien * poidsEntree(etat, symbole);
                if suivant == 1
                    termine(p + 1) = termine(p + 1) + combien;
                    informationTerminee(p + 1) = informationTerminee(p + 1) + info;
                else
                    nombre(p + 1, suivant) = nombre(p + 1, suivant) + combien;
                    information(p + 1, suivant) = information(p + 1, suivant) + info;
                end
            end
        end
    end
    premier = find(termine > 0, 1);
    if isempty(premier)
        error('comm:distspec:Aucun', ...
              'Aucun chemin ne revient à l''état zéro.');
    end
    dfree = premier - 1;
    fin = min(premier + n - 1, maximum + 1);
    spectre = struct('dfree', dfree, ...
                     'weight', informationTerminee(premier:fin), ...
                     'nombre', termine(premier:fin));
end
