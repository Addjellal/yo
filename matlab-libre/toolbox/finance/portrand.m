function [risques, rendements, poids] = portrand(actifs, rendementsAttendus, nombre)
%PORTRAND Portefeuilles tirés au hasard.
%   [R,M,W] = PORTRAND(ACTIFS,MU,N) tire N jeux de poids positifs de somme
%   un et rend le risque, le rendement et les poids de chacun. ACTIFS est
%   une matrice de rendements observés, une colonne par actif ; MU, s'il
%   est donné, remplace la moyenne empirique.
%
%   Le nuage obtenu montre ce que la frontière efficiente a de
%   remarquable : aucun point ne se trouve à sa gauche.
%
%   Exemple :
%      [r, m] = portrand(randn(200, 3) / 20 + 0.01, [], 500);
%
%   Voir aussi PORTOPT, FRONTCON, PORTSTATS, PORTSIM.
    actifs = double(actifs);
    if size(actifs, 1) == 1
        actifs = actifs.';
    end
    n = size(actifs, 2);
    covariance = cov(actifs);
    if nargin < 2 || isempty(rendementsAttendus)
        rendementsAttendus = mean(actifs, 1);
    end
    rendementsAttendus = double(rendementsAttendus(:));
    if nargin < 3 || isempty(nombre)
        nombre = 1000;
    end
    nombre = round(nombre);
    % Des poids uniformes sur le simplexe : la loi de Dirichlet de
    % paramètres tous égaux à un s'obtient en normalisant des
    % exponentielles.
    brut = -log(rand(nombre, n));
    poids = brut ./ repmat(sum(brut, 2), 1, n);
    rendements = poids * rendementsAttendus;
    risques = zeros(nombre, 1);
    for k = 1:nombre
        w = poids(k, :).';
        risques(k) = sqrt(w.' * covariance * w);
    end
end
