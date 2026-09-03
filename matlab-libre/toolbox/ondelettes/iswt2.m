function x = iswt2(swa, swh, swv, swd, nom)
%ISWT2 Transformée stationnaire inverse d'une image.
%   X = ISWT2(A,H,V,D,NOM) reconstruit l'image à partir des quatre
%   familles que rend SWT2.
%
%   La transformée étant redondante, chaque niveau se reconstruit en
%   moyennant les décimations possibles : le facteur est un quart en deux
%   dimensions, contre un demi en une.
%
%   Exemple :
%      [a, h, v, d] = swt2(magic(8), 2, 'haar');
%      max(max(abs(iswt2(a, h, v, d, 'haar') - magic(8))))   % nul
%
%   Voir aussi SWT2, ISWT, WAVEREC2, IDWT2.
    if nargin < 5 || isempty(nom), nom = 'haar'; end
    [bas, haut] = wfilters(nom, 'r');
    niveaux = size(swh, 3);
    courant = swa(:, :, niveaux);
    for k = niveaux:-1:1
        [basK, hautK] = dilaterFiltres(bas, haut, k - 1);
        % Adjoint du filtrage séparable, dans l'ordre inverse : colonnes
        % d'abord, puis lignes.
        parColonne = adjointLignes(courant.', basK).' + adjointLignes(swh(:, :, k).', hautK).';
        parColonneHaut = adjointLignes(swv(:, :, k).', basK).' + adjointLignes(swd(:, :, k).', hautK).';
        courant = (adjointLignes(parColonne, basK) + adjointLignes(parColonneHaut, hautK)) / 4;
    end
    x = courant;
end

function y = adjointLignes(x, h)
%ADJOINTLIGNES Adjoint de la corrélation circulaire, ligne par ligne.
    [lignes, colonnes] = size(x);
    y = zeros(lignes, colonnes);
    m = numel(h);
    for i = 1:lignes
        for k = 1:colonnes
            valeur = x(i, k);
            if valeur == 0, continue; end
            for j = 1:m
                if h(j) == 0, continue; end
                indice = mod(k - 1 + j - 1, colonnes) + 1;
                y(i, indice) = y(i, indice) + h(j) * valeur;
            end
        end
    end
end
