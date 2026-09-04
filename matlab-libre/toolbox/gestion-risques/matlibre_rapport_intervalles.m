function statistique = matlibre_rapport_intervalles(echecs, p)
%MATLIBRE_RAPPORT_INTERVALLES Test de Haas sur les temps entre dépassements.
%   Chaque intervalle entre deux dépassements donne un rapport de
%   vraisemblance de temps d'attente ; leur somme mesure si les
%   dépassements se suivent de trop près ou de trop loin.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    positions = find(echecs(:));
    if isempty(positions)
        statistique = 0;
        return
    end
    intervalles = [positions(1); diff(positions)];
    statistique = 0;
    for k = 1:numel(intervalles)
        statistique = statistique + matlibre_rapport_attente(intervalles(k), p);
    end
end
