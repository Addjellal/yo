function [D, gamma, info] = cmsclsyn(R, options)
%CMSCLSYN Mise à l'échelle constante qui minimise une norme.
%   [D,GAMMA] = CMSCLSYN(R) cherche la matrice diagonale D, à termes
%   positifs, qui minimise la plus grande valeur singulière de D*R*inv(D)
%   sur toutes les tranches de R.
%
%   C'est l'étape D de l'itération D-K, isolée : quand on a la boucle
%   fermée, cette mise à l'échelle donne la meilleure borne haute de mu
%   qu'une mise à l'échelle constante permette.
%
%   R est une matrice, ou un tableau à trois dimensions dont chaque
%   tranche est une matrice — la réponse à une fréquence, par exemple.
%
%   [D,GAMMA,INFO] = CMSCLSYN(R) rend en outre la valeur avant mise à
%   l'échelle, pour mesurer ce qu'elle a gagné.
%
%   La recherche est celle d'Osborne : on équilibre les normes de chaque
%   ligne et de la colonne correspondante, ce qui converge en quelques
%   tours et donne l'optimum pour une matrice à structure scalaire.
%
%   Exemples :
%      R = [1 100; 0.01 1];
%      [D, g] = cmsclsyn(R);
%      g                               % bien plus petit que max(svd(R))
%      max(svd(R))
%
%   Voir aussi MUSSV, DKSYN, MUSYN, SVD.
    if nargin < 2
        options = struct();
    end
    if ndims(R) == 3
        tranches = size(R, 3);
    else
        tranches = 1;
    end
    n = size(R, 1);
    d = ones(1, n);
    avant = 0;
    for t = 1:tranches
        if tranches > 1
            M = R(:, :, t);
        else
            M = R;
        end
        avant = max(avant, max(svd(M)));
    end
    for iteration = 1:300
        change = false;
        for k = 1:n
            ligne = 0;
            colonne = 0;
            for t = 1:tranches
                if tranches > 1
                    M = R(:, :, t);
                else
                    M = R;
                end
                A = diag(d) * M / diag(d);
                ligne = max(ligne, norm(A(k, :), 'fro'));
                colonne = max(colonne, norm(A(:, k), 'fro'));
            end
            if ligne > 0 && colonne > 0
                facteur = sqrt(colonne / ligne);
                if abs(facteur - 1) > 1e-12
                    d(k) = d(k) * facteur;
                    change = true;
                end
            end
        end
        if ~change
            break
        end
    end
    D = diag(d);
    gamma = 0;
    for t = 1:tranches
        if tranches > 1
            M = R(:, :, t);
        else
            M = R;
        end
        gamma = max(gamma, max(svd(D * M / D)));
    end
    info = struct('Before', avant, 'Scaling', d);
end
