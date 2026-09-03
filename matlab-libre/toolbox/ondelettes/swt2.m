function [swa, swh, swv, swd] = swt2(x, niveaux, nom)
%SWT2 Transformée stationnaire d'une image.
%   [A,H,V,D] = SWT2(X,N,NOM) rend, pour chacun des N niveaux, une image
%   de la taille de X : approximation, détails horizontal, vertical et
%   diagonal. Le niveau K occupe A(:,:,K) et ses voisins.
%
%   Comme en une dimension, rien n'est décimé : ce sont les filtres qui
%   sont dilatés d'un niveau à l'autre. Le résultat est donc invariant
%   par translation, ce qui vaut pour la détection de contours et le
%   débruitage — au prix de quatre fois plus de coefficients par niveau.
%
%   Les deux dimensions de X doivent être des multiples de 2^N.
%
%   Exemple :
%      [a, h, v, d] = swt2(magic(8), 2, 'haar');
%      size(a)                        % 8x8x2
%
%   Voir aussi ISWT2, SWT, WAVEDEC2, DWT2.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    x = double(x);
    [lignes, colonnes] = size(x);
    if mod(lignes, 2 ^ niveaux) ~= 0 || mod(colonnes, 2 ^ niveaux) ~= 0
        error('wavelet:swt2:BadSize', ...
              'Les deux dimensions doivent être des multiples de 2^N.');
    end
    [analyseBas, analyseHaut] = wfilters(nom, 'd');
    bas = analyseBas(end:-1:1);
    haut = analyseHaut(end:-1:1);
    swa = zeros(lignes, colonnes, niveaux);
    swh = zeros(lignes, colonnes, niveaux);
    swv = zeros(lignes, colonnes, niveaux);
    swd = zeros(lignes, colonnes, niveaux);
    courant = x;
    for k = 1:niveaux
        [basK, hautK] = dilaterFiltres(bas, haut, k - 1);
        % Séparabilité : on filtre les lignes, puis les colonnes.
        parLigneBas = filtrerLignes(courant, basK);
        parLigneHaut = filtrerLignes(courant, hautK);
        swa(:, :, k) = filtrerLignes(parLigneBas.', basK).';
        swh(:, :, k) = filtrerLignes(parLigneBas.', hautK).';
        swv(:, :, k) = filtrerLignes(parLigneHaut.', basK).';
        swd(:, :, k) = filtrerLignes(parLigneHaut.', hautK).';
        courant = swa(:, :, k);
    end
end

function y = filtrerLignes(x, h)
%FILTRERLIGNES Corrélation circulaire de chaque ligne par H.
    y = zeros(size(x));
    for i = 1:size(x, 1)
        y(i, :) = convolutionCirculaire(x(i, :), h);
    end
end
