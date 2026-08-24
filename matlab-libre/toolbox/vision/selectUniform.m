function [choisis, indices] = selectUniform(positions, nombre, tailleImage)
%SELECTUNIFORM Sélection de points répartis sur toute l'image.
%   [P,I] = SELECTUNIFORM(POSITIONS,N,TAILLE) retient N points en les
%   prenant dans une grille de cases, une case après l'autre : au lieu de
%   garder les N plus forts, qui se concentrent souvent sur une seule
%   texture, on garantit une couverture de toute l'image.
%
%   C'est ce qu'il faut pour estimer une transformation géométrique : des
%   points groupés au même endroit contraignent mal.
%
%   Exemple :
%      p = selectUniform(rand(500, 2) * 100, 20, [100 100]);
%      size(p, 1)   % 20
%
%   Voir aussi SELECTSTRONGEST, DETECTHARRISFEATURES.
    P = double(positions);
    n = size(P, 1);
    nombre = min(round(nombre), n);
    if nombre <= 0
        choisis = zeros(0, size(P, 2));
        indices = zeros(0, 1);
        return
    end
    tailleImage = double(tailleImage);
    % Grille de cases dont le nombre approche celui des points demandés.
    cotes = max(round(sqrt(nombre)), 1);
    lignesGrille = cotes;
    colonnesGrille = ceil(nombre / cotes);
    caseLigne = min(max(ceil(P(:, 2) / (tailleImage(1) / lignesGrille)), 1), lignesGrille);
    caseColonne = min(max(ceil(P(:, 1) / (tailleImage(2) / colonnesGrille)), 1), colonnesGrille);
    numeroCase = (caseColonne - 1) * lignesGrille + caseLigne;
    indices = [];
    restants = true(n, 1);
    nCases = lignesGrille * colonnesGrille;
    while numel(indices) < nombre && any(restants)
        pris = false;
        for c = 1:nCases
            if numel(indices) >= nombre, break, end
            candidats = find(restants & numeroCase == c, 1);
            if ~isempty(candidats)
                indices(end+1, 1) = candidats;      %#ok<AGROW>
                restants(candidats) = false;
                pris = true;
            end
        end
        if ~pris, break, end
    end
    choisis = P(indices, :);
end
