function grille = formatpoints(grille, varargin)
%FORMATPOINTS Choisit l'échelle des points d'une grille de score.
%   SC = FORMATPOINTS(SC,'PointsOddsAndPDO',[P O D]) fixe l'échelle par
%   trois nombres : au score P le rapport bons sur mauvais vaut O, et il
%   double tous les D points.
%
%   L'échelle n'a aucun effet sur le classement des dossiers ni sur les
%   probabilités de défaut : elle ne fait que rendre les points lisibles.
%   C'est une convention d'affichage, non un choix de modèle.
%
%   FORMATPOINTS(...,'ShiftAndSlope',[S P]) donne directement le décalage
%   et la pente, 'WorstAndBestScores',[W B] les fixe par les scores
%   extrêmes atteignables.
%
%   Exemple :
%      sc = formatpoints(sc, 'PointsOddsAndPDO', [500 2 50]);
%
%   Voir aussi DISPLAYPOINTS, SCORE, FITMODEL, PROBDEFAULT.
    k = 1;
    while k + 1 <= numel(varargin)
        valeur = double(varargin{k+1});
        switch lower(char(varargin{k}))
            case 'pointsoddsandpdo'
                points = valeur(1); rapport = valeur(2); doublement = valeur(3);
                grille.Slope = doublement / log(2);
                grille.Shift = points - grille.Slope * log(rapport);
            case 'shiftandslope'
                grille.Shift = valeur(1);
                grille.Slope = valeur(2);
            case 'worstandbestscores'
                [~, extremes] = matlibre_score_extremes(grille);
                etendue = extremes(2) - extremes(1);
                if etendue == 0
                    grille.Slope = 1;
                else
                    grille.Slope = (valeur(2) - valeur(1)) / etendue;
                end
                grille.Shift = valeur(1) - grille.Slope * extremes(1);
            case 'round'    % l'arrondi se fait à l'affichage
            otherwise
                error('risque:formatpoints:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
end
