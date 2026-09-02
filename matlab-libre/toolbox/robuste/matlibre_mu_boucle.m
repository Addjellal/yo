function [mu, D] = matlibre_mu_boucle(CL)
%MATLIBRE_MU_BOUCLE La borne haute de mu d'une boucle, et sa mise à l'échelle.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   DKSYN s'en sert à l'étape D. La borne est cherchée sur une grille de
%   fréquences ; c'est le maximum sur cette grille qu'on rend, avec la
%   mise à l'échelle du point le pire.
    CL = ss(CL);
    w = logspace(-3, 3, 60);
    H = freqresp(CL, w);
    mu = 0;
    D = 1;
    for k = 1:numel(w)
        if ndims(H) == 3
            M = H(:, :, k);
        else
            M = H(k);
        end
        % Une boucle carree se prete a MUSSV ; sinon — deux sorties
        % reglees pour une entree exogene, ce qui est le cas ordinaire
        % d'un probleme de sensibilite mixte — mu vaut la plus grande
        % valeur singuliere, le bloc etant plein.
        [lignes, colonnes] = size(M);
        if lignes ~= colonnes
            valeur = max(svd(M));
        elseif lignes == 1
            valeur = abs(M);
        else
            bornes = mussv(M, [lignes 0]);
            valeur = bornes(1);
        end
        echelle = 1;
        if valeur > mu
            mu = valeur;
            D = echelle;
        end
    end
end
