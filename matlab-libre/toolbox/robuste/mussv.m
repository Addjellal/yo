function [bornes, D, G] = mussv(M, blocs, options)
%MUSSV Valeur singulière structurée.
%   BORNES = MUSSV(M,BLOCS) rend un encadrement de la valeur singulière
%   structurée de la matrice M pour la structure d'incertitude décrite
%   par BLOCS : [BORNE_HAUTE, BORNE_BASSE].
%
%   La valeur singulière structurée — le mu — mesure la plus petite
%   perturbation, de la structure donnée, qui rende I - M*DELTA singulière :
%
%      mu(M) = 1 / min { sigma_max(DELTA) : det(I - M DELTA) = 0 }
%
%   Elle vaut zéro s'il n'en existe aucune. C'est la quantité centrale de
%   l'analyse de robustesse : la boucle tient tant que mu reste sous un.
%
%   BLOCS compte une ligne par bloc de la structure :
%      [-N 0]   un bloc scalaire réel répété N fois ;
%      [N 0]    un bloc scalaire complexe répété N fois ;
%      [N M]    un bloc plein complexe de taille N x M.
%
%   La borne haute vient de la mise à l'échelle : mu est inférieur à
%   l'infimum, sur les D qui commutent avec la structure, de
%   sigma_max(D M D^-1). MatLibre cherche ce minimum par la mise à
%   l'échelle d'Osborne, qui équilibre les lignes et les colonnes en
%   quelques itérations.
%
%   La borne basse vient d'une recherche de la plus grande valeur propre
%   atteignable par une perturbation de la structure : elle est toujours
%   valable, sans être forcément atteinte.
%
%   Pour un bloc plein complexe unique, mu est exactement la plus grande
%   valeur singulière ; pour une structure diagonale complexe, la borne
%   haute est exacte jusqu'à trois blocs.
%
%   [BORNES,D] = MUSSV(...) rend en outre la mise à l'échelle trouvée.
%
%   Exemples :
%      M = [1 2; 3 4];
%      mussv(M, [2 0])                % structure scalaire complexe
%      mussv(M, [2 2])                % un bloc plein : c'est sigma_max
%      max(svd(M))
%
%   Voir aussi ROBSTAB, WCGAIN, HINFNORM, SVD, LOOPMARGIN.
    if nargin < 2 || isempty(blocs)
        blocs = [size(M, 1), size(M, 2)];
    end
    if nargin < 3
        options = '';
    end
    n = size(M, 1);
    if size(M, 2) ~= n
        error('robust:mussv:NotSquare', 'M must be square.');
    end
    tailles = tailleDesBlocs(blocs, n);
    % Un seul bloc plein : mu vaut la plus grande valeur singuliere.
    if size(blocs, 1) == 1 && blocs(1, 1) == n && size(blocs, 2) >= 2 && blocs(1, 2) == n
        haute = max(svd(M));
        bornes = [haute, haute];
        D = eye(n);
        G = zeros(n);
        return;
    end
    % Borne haute par la mise a l'echelle d'Osborne, restreinte aux D qui
    % commutent avec la structure : un scalaire par bloc.
    d = ones(1, numel(tailles));
    for iteration = 1:200
        Dm = diag(matlibre_etendre_blocs(d, tailles));
        A = Dm * M / Dm;
        change = false;
        for k = 1:numel(tailles)
            lignes = indicesBloc(tailles, k);
            ligne = norm(A(lignes, :), 'fro');
            colonne = norm(A(:, lignes), 'fro');
            if ligne > 0 && colonne > 0
                facteur = sqrt(colonne / ligne);
                if abs(facteur - 1) > 1e-12
                    d(k) = d(k) * facteur;
                    change = true;
                end
            end
        end
        if ~change
            break;
        end
    end
    D = diag(matlibre_etendre_blocs(d, tailles));
    haute = max(svd(D * M / D));
    % Borne basse : le rayon spectral de M, qui minore toujours mu, et
    % l'amelioration qu'apporte une perturbation diagonale de phase.
    basse = max(abs(eig(M)));
    basse = max(basse, meilleurRayon(M, tailles));
    basse = min(basse, haute);
    bornes = [haute, basse];
    G = zeros(n);
end

function tailles = tailleDesBlocs(blocs, n)
%TAILLEDESBLOCS La taille de chaque bloc, en lignes de M.
    tailles = [];
    for k = 1:size(blocs, 1)
        premier = abs(blocs(k, 1));
        if size(blocs, 2) >= 2 && blocs(k, 2) ~= 0
            tailles(end + 1) = premier;      %#ok<AGROW>
        else
            for r = 1:premier
                tailles(end + 1) = 1;        %#ok<AGROW>
            end
        end
    end
    if sum(tailles) ~= n
        error('robust:mussv:BadBlocks', ...
              'The block structure must add up to the size of M.');
    end
end

function idx = indicesBloc(tailles, k)
%INDICESBLOC Les lignes qu'occupe le k-ième bloc.
    debut = sum(tailles(1:k - 1)) + 1;
    idx = debut:debut + tailles(k) - 1;
end

function r = meilleurRayon(M, tailles)
%MEILLEURRAYON Le plus grand rayon spectral atteint par une phase diagonale.
%   On tire des perturbations unitaires de la structure et l'on garde le
%   plus grand rayon spectral obtenu : c'est un minorant de mu, valable
%   sans etre necessairement atteint.
    etat = rng();
    rng(20240120);
    r = 0;
    n = size(M, 1);
    for essai = 1:200
        phases = exp(2i * pi * rand(1, numel(tailles)));
        Delta = diag(matlibre_etendre_blocs(phases, tailles));
        r = max(r, max(abs(eig(M * Delta))));
    end
    rng(etat);
end
