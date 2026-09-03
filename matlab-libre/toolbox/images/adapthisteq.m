function J = adapthisteq(I, varargin)
%ADAPTHISTEQ Égalisation d'histogramme adaptative à contraste limité.
%   J = ADAPTHISTEQ(I) découpe l'image en tuiles, égalise l'histogramme
%   de chacune, puis interpole entre les tuiles voisines pour effacer
%   les coutures. Contrairement à HISTEQ, qui traite l'image entière,
%   elle révèle le détail des zones sombres sans écraser les zones
%   claires.
%
%   L'histogramme de chaque tuile est écrêté avant égalisation — c'est
%   le « contraste limité » —, faute de quoi le bruit d'une zone uniforme
%   serait amplifié jusqu'à devenir visible.
%
%   ADAPTHISTEQ(...,'NumTiles',[L C]) donne le découpage (8 par 8 par
%   défaut), 'ClipLimit',C l'écrêtage entre 0 et 1 (0,01 par défaut),
%   'NBins',N le nombre de niveaux (256), 'Range','original' garde
%   l'étendue de l'image au lieu de l'étaler.
%
%   ADAPTHISTEQ(...,'Distribution',D) choisit la forme visée par
%   l'histogramme de sortie : 'uniform' (défaut), 'rayleigh' ou
%   'exponential', et 'Alpha',A en règle le paramètre (0,4 par défaut).
%   L'uniforme aplatit l'histogramme ; la loi de Rayleigh lui donne une
%   forme en cloche, ce qui relève les tons sombres ; l'exponentielle
%   les concentre vers le bas et assombrit l'image.
%
%   Exemple :
%      I = mat2gray(peaks(128));
%      J = adapthisteq(I, 'ClipLimit', 0.02);
%
%   Voir aussi HISTEQ, IMADJUST, IMHIST, IMLOCALBRIGHTEN, STRETCHLIM.
    tuiles = [8 8];
    ecretage = 0.01;
    nBins = 256;
    etendue = 'full';
    loi = 'uniform';
    alpha = 0.4;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'numtiles',     tuiles = round(double(varargin{k+1}));
            case 'cliplimit',    ecretage = double(varargin{k+1});
            case 'nbins',        nBins = round(varargin{k+1});
            case 'range',        etendue = lower(char(varargin{k+1}));
            case 'distribution', loi = lower(char(varargin{k+1}));
            case 'alpha',        alpha = double(varargin{k+1});
            otherwise
                error('images:adapthisteq:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if numel(tuiles) == 1
        tuiles = [tuiles tuiles];
    end
    if ~any(strcmp(loi, {'uniform', 'rayleigh', 'exponential'}))
        error('images:adapthisteq:Loi', ...
              'Distribution inconnue : %s.', loi);
    end
    if alpha <= 0
        error('images:adapthisteq:Alpha', 'Alpha doit être positif.');
    end
    classeEntree = class(I);
    I = im2double(I);
    if size(I, 3) > 1
        error('images:adapthisteq:Couleur', ...
              'ADAPTHISTEQ traite une image en niveaux de gris ; convertissez-la d''abord.');
    end
    [m, n] = size(I);
    hauteur = ceil(m / tuiles(1));
    largeur = ceil(n / tuiles(2));
    % Une table de correspondance par tuile.
    tables = cell(tuiles(1), tuiles(2));
    bas = min(I(:));
    haut = max(I(:));
    if strcmp(etendue, 'full') || haut <= bas
        bas = 0;
        haut = 1;
    end
    for ti = 1:tuiles(1)
        for tj = 1:tuiles(2)
            lignes = ((ti - 1) * hauteur + 1):min(ti * hauteur, m);
            colonnes = ((tj - 1) * largeur + 1):min(tj * largeur, n);
            bloc = I(lignes, colonnes);
            tables{ti, tj} = tableEgalisation(bloc, nBins, ecretage, bas, haut, loi, alpha);
        end
    end
    % Interpolation bilinéaire entre les quatre tuiles voisines : c'est
    % elle qui efface les coutures que donnerait un traitement par blocs.
    J = zeros(m, n);
    for i = 1:m
        centreI = (i - 0.5) / hauteur + 0.5;
        ti0 = max(1, min(tuiles(1), floor(centreI)));
        ti1 = max(1, min(tuiles(1), ti0 + 1));
        poidsI = max(0, min(1, centreI - ti0));
        for j = 1:n
            centreJ = (j - 0.5) / largeur + 0.5;
            tj0 = max(1, min(tuiles(2), floor(centreJ)));
            tj1 = max(1, min(tuiles(2), tj0 + 1));
            poidsJ = max(0, min(1, centreJ - tj0));
            valeur = I(i, j);
            indice = niveau(valeur, nBins, bas, haut);
            haut1 = (1 - poidsJ) * tables{ti0, tj0}(indice) + ...
                    poidsJ * tables{ti0, tj1}(indice);
            bas1 = (1 - poidsJ) * tables{ti1, tj0}(indice) + ...
                   poidsJ * tables{ti1, tj1}(indice);
            J(i, j) = (1 - poidsI) * haut1 + poidsI * bas1;
        end
    end
    J = min(max(J, 0), 1);
    if ~strcmp(classeEntree, 'double') && ~strcmp(classeEntree, 'single')
        J = cast(J * double(intmax(classeEntree)), classeEntree);
    end
end

function table = tableEgalisation(bloc, nBins, ecretage, bas, haut, loi, alpha)
% L'histogramme écrêté, redistribué, puis cumulé : c'est la table de
% correspondance de la tuile.
    valeurs = niveau(bloc(:), nBins, bas, haut);
    histogramme = zeros(nBins, 1);
    for k = 1:numel(valeurs)
        histogramme(valeurs(k)) = histogramme(valeurs(k)) + 1;
    end
    if ecretage > 0
        % La limite va de l'histogramme plat — aucun rehaussement — à
        % l'absence d'écrêtage : c'est la convention de MATLAB, où
        % ClipLimit vaut entre 0 et 1.
        moyenne = numel(valeurs) / nBins;
        limite = max(1, moyenne + ecretage * (numel(valeurs) - moyenne));
        excedent = sum(max(histogramme - limite, 0));
        histogramme = min(histogramme, limite);
        % Ce qui dépasse est réparti également : l'aire de l'histogramme
        % ne change pas, et la pente de la table reste bornée.
        histogramme = histogramme + excedent / nBins;
    end
    cumul = cumsum(histogramme);
    if cumul(end) > 0
        cumul = cumul / cumul(end);
    end
    % L'égalisation uniforme prend le cumul tel quel ; les deux autres
    % lois passent le cumul par l'inverse de leur répartition, ce qui
    % donne à l'histogramme de sortie la forme voulue. L'inverse diverge
    % en un : le cumul est d'abord mis à l'échelle par la valeur qui
    % ramène exactement à un le dernier niveau, si bien que la table
    % couvre toute l'étendue sans qu'on ait à l'écrêter.
    switch loi
        case 'rayleigh'
            constante = 2 * alpha ^ 2;
            maximum = 1 - exp(-1 / constante);
            p = min(maximum * cumul, 1 - eps);
            forme = sqrt(-constante * log(1 - p));
        case 'exponential'
            maximum = 1 - exp(-alpha);
            p = min(maximum * cumul, 1 - eps);
            forme = -log(1 - p) / alpha;
        otherwise
            forme = cumul;
    end
    table = bas + (haut - bas) * min(max(forme, 0), 1);
end

function indice = niveau(valeur, nBins, bas, haut)
% Le niveau discret d'une intensité, sur l'étendue retenue.
    indice = min(max(round((valeur - bas) / max(haut - bas, eps) * (nBins - 1)) + 1, 1), nBins);
end
