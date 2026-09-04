function [modele, dedans, dehors, erreurMoyenne] = pcfitplane(entree, distanceMax, vecteurReference, angleMax)
%PCFITPLANE Ajuste un plan à un nuage de points, par tirages aléatoires.
%   [M,DEDANS,DEHORS,E] = PCFITPLANE(P,D) cherche le plan qui rassemble le
%   plus de points à moins de D de lui. M porte les quatre coefficients
%   a, b, c, d du plan a*x + b*y + c*z + d = 0, et sa normale.
%
%   La méthode est celle du consensus par échantillonnage : on tire trois
%   points au hasard, on compte combien de points le plan qu'ils
%   définissent rassemble, et l'on recommence. Contrairement aux moindres
%   carrés, un point aberrant n'y pèse rien : il n'appartient simplement à
%   aucun consensus.
%
%   PCFITPLANE(P,D,VECTEUR,ANGLE) n'accepte que les plans dont la normale
%   s'écarte du vecteur de moins de ANGLE degrés — c'est ainsi qu'on
%   cherche un sol plutôt qu'un mur.
%
%   Exemple :
%      p = pointCloud([rand(500,2)*10, 0.01*randn(500,1)]);
%      m = pcfitplane(p, 0.05);
%      m.Parameters
%
%   Voir aussi PCSEGDIST, PCNORMALS, PCREGISTERICP, POINTCLOUD.
    points = matlibre_nuage_points(entree);
    n = size(points, 1);
    if n < 3
        error('vision:pcfitplane:Points', 'Il faut au moins trois points.');
    end
    if nargin < 3, vecteurReference = []; end
    if nargin < 4 || isempty(angleMax), angleMax = 5; end
    if ~isempty(vecteurReference)
        vecteurReference = double(vecteurReference(:));
        vecteurReference = vecteurReference / norm(vecteurReference);
    end
    meilleurCompte = -1;
    meilleurModele = [];
    tirages = 1000;
    for essai = 1:tirages
        rangs = randperm(n, 3);
        candidat = matlibre_plan_par_trois(points(rangs, :));
        if isempty(candidat)
            continue
        end
        if ~isempty(vecteurReference)
            cosinus = abs(candidat(1:3) * vecteurReference);
            if cosinus < cos(angleMax * pi / 180)
                continue
            end
        end
        distances = abs(points * candidat(1:3).' + candidat(4));
        compte = sum(distances <= distanceMax);
        if compte > meilleurCompte
            meilleurCompte = compte;
            meilleurModele = candidat;
        end
    end
    if isempty(meilleurModele)
        error('vision:pcfitplane:Aucun', ...
              'Aucun plan ne respecte la direction demandée.');
    end
    distances = abs(points * meilleurModele(1:3).' + meilleurModele(4));
    dedans = find(distances <= distanceMax);
    dehors = find(distances > distanceMax);
    % Le consensus trouvé, on réajuste par moindres carrés sur ses seuls
    % points : le tirage donne le bon sous-ensemble, non le meilleur plan.
    if numel(dedans) >= 3
        meilleurModele = matlibre_plan_moindres_carres(points(dedans, :));
        distances = abs(points * meilleurModele(1:3).' + meilleurModele(4));
        dedans = find(distances <= distanceMax);
        dehors = find(distances > distanceMax);
    end
    erreurMoyenne = mean(distances(dedans));
    modele = struct('Parameters', meilleurModele, ...
                    'Normal', meilleurModele(1:3));
end
