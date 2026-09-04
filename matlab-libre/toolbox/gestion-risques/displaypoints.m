function [bareme, minimum, maximum] = displaypoints(grille)
%DISPLAYPOINTS Barème d'une grille de score.
%   [B,MIN,MAX] = DISPLAYPOINTS(SC) rend les points attribués à chaque
%   tranche de chaque caractéristique, ainsi que les scores minimal et
%   maximal atteignables. Sans sortie, le bareme est écrit.
%
%   Les points d'une tranche sont son poids de la preuve multiplié par le
%   coefficient de sa caractéristique, plus une part de la constante,
%   le tout mis à l'échelle par FORMATPOINTS. Additionner les points d'un
%   dossier revient exactement à évaluer la régression logistique.
%
%   Exemple :
%      [b, bas, haut] = displaypoints(sc);
%
%   Voir aussi FORMATPOINTS, SCORE, PROBDEFAULT, FITMODEL.
    [parVariable, extremes] = matlibre_score_extremes(grille);
    lignes = {};
    for j = 1:numel(parVariable)
        bloc = parVariable{j};
        for k = 1:numel(bloc.etiquettes)
            lignes{end+1} = struct('Predictors', bloc.nom, ...
                                   'Bin', bloc.etiquettes{k}, ...
                                   'Points', grille.Shift / numel(parVariable) + ...
                                             grille.Slope * bloc.points(k));   %#ok<AGROW>
        end
    end
    bareme = lignes;
    minimum = grille.Shift + grille.Slope * extremes(1);
    maximum = grille.Shift + grille.Slope * extremes(2);
    if nargout == 0
        fprintf('\n  %-16s %-24s %10s\n', 'Caractéristique', 'Tranche', 'Points');
        for k = 1:numel(lignes)
            fprintf('  %-16s %-24s %10.4f\n', lignes{k}.Predictors, ...
                    lignes{k}.Bin, lignes{k}.Points);
        end
        fprintf('\n  score minimal %.4f, maximal %.4f\n\n', minimum, maximum);
        clear bareme
    end
end
