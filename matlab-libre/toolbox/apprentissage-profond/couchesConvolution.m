function varargout = couchesConvolution(action, varargin)
%COUCHESCONVOLUTION Propagation avant et arrière des couches spatiales.
%   Regroupe ici ce qui touche aux images : convolution, agrégation par
%   maximum ou par moyenne, aplatissement. TRAINNETWORK et PREDICT
%   appellent les actions 'avant' et 'arriere'.
%
%   [Y,C] = COUCHESCONVOLUTION('avant', C, X)
%   [DELTA,GW,GB] = COUCHESCONVOLUTION('arriere', C, X, Y, DELTA)
%
%   Les tableaux d'images sont rangés H x L x P x N : hauteur, largeur,
%   plans, observations.
%
%   Le calcul est organisé par décalage de noyau plutôt que par fenêtre :
%   pour un noyau MH x ML il n'y a que MH*ML tranches à combiner, chacune
%   portant d'un coup toutes les positions, tous les plans et toutes les
%   images. C'est la transposition du produit par une matrice de Toeplitz,
%   et cela évite les boucles sur les pixels.
    switch lower(char(action))
        case 'avant'
            [varargout{1}, varargout{2}] = avant(varargin{:});
        case 'arriere'
            [varargout{1}, varargout{2}, varargout{3}] = arriere(varargin{:});
        otherwise
            error('nnet:couchesConvolution:UnknownAction', ...
                  'Action inconnue : %s.', action);
    end
end

function [y, c] = avant(c, x)
    switch c.type
        case 'conv2d'
            [y, c] = convoluerAvant(c, x);
        case 'maxpool'
            y = agregerAvant(x, c.taille, c.pas, true);
        case 'avgpool'
            y = agregerAvant(x, c.taille, c.pas, false);
        case 'flatten'
            c.forme = size(x);
            d = c.forme;
            d(end+1:4) = 1;
            y = reshape(x, [], d(4));
        otherwise
            y = x;
    end
end

function [delta, gW, gB] = arriere(c, x, y, delta)
    gW = 0;
    gB = 0;
    switch c.type
        case 'conv2d'
            [delta, gW, gB] = convoluerArriere(c, x, delta);
        case 'maxpool'
            delta = agregerArriere(x, y, delta, c.taille, c.pas, true);
        case 'avgpool'
            delta = agregerArriere(x, y, delta, c.taille, c.pas, false);
        case 'flatten'
            delta = reshape(delta, c.forme);
        otherwise
            % rien à faire
    end
end

% --------------------------------------------------------------- convolution

function [y, c] = convoluerAvant(c, x)
    [h, l, p, n] = tailleImage(x);
    mh = c.taille(1);
    ml = c.taille(2);
    if isempty(c.W)
        % Glorot : la variance dépend du nombre d'entrées et de sorties
        % d'une unité, soit mh*ml*p et mh*ml*filtres.
        limite = sqrt(6 / (mh * ml * p + mh * ml * c.filtres));
        c.W = (rand(mh, ml, p, c.filtres) * 2 - 1) * limite;
        c.b = zeros(1, c.filtres);
    end
    marge = margeEffective(c, [mh ml]);
    xp = remplir(x, marge);
    hs = floor((h + 2 * marge(1) - mh) / c.pas(1)) + 1;
    ls = floor((l + 2 * marge(2) - ml) / c.pas(2)) + 1;
    y = zeros(hs, ls, c.filtres, n);
    for f = 1:c.filtres
        accumulateur = zeros(hs, ls, 1, n);
        for plan = 1:p
            noyau = c.W(:, :, plan, f);
            for i = 1:mh
                lignes = i:c.pas(1):(hs - 1) * c.pas(1) + i;
                for j = 1:ml
                    if noyau(i, j) == 0, continue, end
                    colonnes = j:c.pas(2):(ls - 1) * c.pas(2) + j;
                    accumulateur = accumulateur + ...
                        noyau(i, j) * xp(lignes, colonnes, plan, :);
                end
            end
        end
        y(:, :, f, :) = accumulateur + c.b(f);
    end
end

function [delta, gW, gB] = convoluerArriere(c, x, deltaSortie)
    [h, l, p, ~] = tailleImage(x);
    mh = c.taille(1);
    ml = c.taille(2);
    marge = margeEffective(c, [mh ml]);
    xp = remplir(x, marge);
    [hs, ls, ~, ~] = tailleImage(deltaSortie);
    gW = zeros(size(c.W));
    gB = zeros(size(c.b));
    deltaEtendu = zeros(size(xp));
    for f = 1:c.filtres
        ds = deltaSortie(:, :, f, :);
        gB(f) = sum(ds(:));
        for plan = 1:p
            noyau = c.W(:, :, plan, f);
            for i = 1:mh
                lignes = i:c.pas(1):(hs - 1) * c.pas(1) + i;
                for j = 1:ml
                    colonnes = j:c.pas(2):(ls - 1) * c.pas(2) + j;
                    % Gradient du noyau : corrélation de l'entrée par le delta.
                    produit = xp(lignes, colonnes, plan, :) .* ds;
                    gW(i, j, plan, f) = sum(produit(:));
                    % Gradient de l'entrée : le delta redistribué par le noyau.
                    if noyau(i, j) ~= 0
                        deltaEtendu(lignes, colonnes, plan, :) = ...
                            deltaEtendu(lignes, colonnes, plan, :) + noyau(i, j) * ds;
                    end
                end
            end
        end
    end
    delta = retirerMarge(deltaEtendu, marge, h, l);
end

% ------------------------------------------------------------- agrégation

function y = agregerAvant(x, taille, pas, maximum)
    [h, l, p, n] = tailleImage(x);
    hs = floor((h - taille(1)) / pas(1)) + 1;
    ls = floor((l - taille(2)) / pas(2)) + 1;
    premier = true;
    y = zeros(hs, ls, p, n);
    for i = 1:taille(1)
        lignes = i:pas(1):(hs - 1) * pas(1) + i;
        for j = 1:taille(2)
            colonnes = j:pas(2):(ls - 1) * pas(2) + j;
            tranche = x(lignes, colonnes, :, :);
            if maximum
                if premier
                    y = tranche;
                    premier = false;
                else
                    y = max(y, tranche);
                end
            else
                y = y + tranche;
            end
        end
    end
    if ~maximum
        y = y / (taille(1) * taille(2));
    end
end

function delta = agregerArriere(x, y, deltaSortie, taille, pas, maximum)
    [h, l, p, n] = tailleImage(x);
    [hs, ls, ~, ~] = tailleImage(y);
    delta = zeros(h, l, p, n);
    surface = taille(1) * taille(2);
    if maximum
        % Le gradient ne remonte qu'au pixel gagnant. En cas d'égalité
        % c'est le premier au sens de l'ordre colonne, comme MAX sur la
        % fenêtre linéarisée : on parcourt donc les colonnes d'abord.
        pris = false(hs, ls, p, n);
        for j = 1:taille(2)
            colonnes = j:pas(2):(ls - 1) * pas(2) + j;
            for i = 1:taille(1)
                lignes = i:pas(1):(hs - 1) * pas(1) + i;
                gagne = (x(lignes, colonnes, :, :) == y) & ~pris;
                pris = pris | gagne;
                delta(lignes, colonnes, :, :) = delta(lignes, colonnes, :, :) + ...
                    gagne .* deltaSortie;
            end
        end
    else
        for i = 1:taille(1)
            lignes = i:pas(1):(hs - 1) * pas(1) + i;
            for j = 1:taille(2)
                colonnes = j:pas(2):(ls - 1) * pas(2) + j;
                delta(lignes, colonnes, :, :) = delta(lignes, colonnes, :, :) + ...
                    deltaSortie / surface;
            end
        end
    end
end

% ------------------------------------------------------------------ outils

function [h, l, p, n] = tailleImage(x)
    d = size(x);
    d(end+1:4) = 1;
    h = d(1); l = d(2); p = d(3); n = d(4);
end

function marge = margeEffective(c, taille)
    if ischar(c.marge) || isstring(c.marge)
        if strcmpi(char(c.marge), 'same')
            marge = floor((taille - 1) / 2);
        else
            marge = [0 0];
        end
    else
        marge = c.marge;
        if numel(marge) < 2, marge = [marge marge]; end
    end
end

function y = remplir(x, marge)
    if all(marge == 0), y = x; return, end
    [h, l, p, n] = tailleImage(x);
    y = zeros(h + 2 * marge(1), l + 2 * marge(2), p, n);
    y(marge(1) + (1:h), marge(2) + (1:l), :, :) = x;
end

function y = retirerMarge(x, marge, h, l)
    if all(marge == 0), y = x; return, end
    y = x(marge(1) + (1:h), marge(2) + (1:l), :, :);
end
