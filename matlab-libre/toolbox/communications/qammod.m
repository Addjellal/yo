function y = qammod(x, M, varargin)
%QAMMOD Modulation d'amplitude en quadrature à M états (M carré).
%   Y = QAMMOD(X,M) place chaque symbole entier de X (0 à M-1) sur la
%   grille carrée de M points, d'espacement deux, comme MATLAB : en ordre
%   de Gray par défaut.
%   Y = QAMMOD(X,M,SYMORDER) choisit l'ordre : 'gray', 'bin', ou un
%   vecteur d'ordre personnalisé dont le premier élément est le symbole du
%   point en haut à gauche, les suivants descendant chaque colonne, de la
%   gauche vers la droite.
%
%   Options (nom, valeur) :
%      'InputType'         'integer' (défaut) ou 'bit' : X porte alors
%                          log2(M) bits par symbole, le plus fort en tête,
%                          sur un nombre de lignes multiple de log2(M)
%      'UnitAveragePower'  true ramène la puissance moyenne de la
%                          constellation à un watt (défaut false)
%      'OutputDataType'    'double' (défaut) ou 'single'
%      'PlotConstellation' true trace la constellation et ses étiquettes
%
%   La place d'un symbole : en ordre binaire, le symbole s occupe la
%   colonne floor(s/racine(M)) et la ligne mod(s,racine(M)), comptées
%   depuis le coin en haut à gauche ; en ordre de Gray, les bits forts
%   portent le code de Gray de la colonne, les bits faibles celui de la
%   ligne, si bien que deux points voisins ne diffèrent que d'un bit.
%   En 16-QAM de Gray, les colonnes portent de haut en bas 0 1 3 2,
%   4 5 7 6, 12 13 15 14 et 8 9 11 10.
%
%   Exemple :
%      qammod(0, 16)                          % -3 + 3i : le coin en haut à gauche
%      c = qammod(0:63, 64, 'UnitAveragePower', true);
%      mean(abs(c) .^ 2)                      % 1
%
%   Voir aussi QAMDEMOD, PSKMOD, GENQAMMOD, MODNORM.
    [ordre, o] = matlibre_qam_options(M, varargin, 'qammod', ...
        struct('InputType', 'integer', 'UnitAveragePower', false, ...
               'OutputDataType', 'double', 'PlotConstellation', false));
    cote = round(sqrt(M));
    k = round(log2(M));
    if strcmpi(o.InputType, 'bit')
        if mod(size(x, 1), k) ~= 0 || any(x(:) ~= 0 & x(:) ~= 1)
            error('comm:qammod:Bits', ...
                  ['Input must be bits 0 or 1, with a number of rows that is a multiple of ' ...
                   'log2(M) = %d.'], k);
        end
        poids = 2 .^ (k - 1:-1:0);
        nCol = size(x, 2);
        groupes = reshape(x, k, []);
        x = reshape(poids * groupes, [], nCol);
    elseif ~strcmpi(o.InputType, 'integer')
        error('comm:qammod:InputType', 'InputType must be ''integer'' or ''bit''.');
    end
    if any(x(:) < 0) || any(x(:) > M - 1) || any(x(:) ~= fix(x(:)))
        error('comm:qammod:Symboles', 'Symbols must be integers from 0 to M-1 = %d.', M - 1);
    end
    [colonne, ligne] = matlibre_qam_place(double(x), cote, ordre);
    y = (2 * colonne - cote + 1) + 1i * (cote - 1 - 2 * ligne);
    if o.UnitAveragePower
        y = y / sqrt(2 * (M - 1) / 3);
    end
    if strcmpi(o.OutputDataType, 'single')
        y = single(y);
    elseif ~strcmpi(o.OutputDataType, 'double')
        error('comm:qammod:OutputDataType', ...
              'MatLibre produces ''double'' or ''single'' outputs, not fixed-point.');
    end
    if o.PlotConstellation
        points = qammod(0:M - 1, M, ordre, 'UnitAveragePower', o.UnitAveragePower);
        plot(real(points), imag(points), 'o');
        for s = 0:M - 1
            text(real(points(s + 1)), imag(points(s + 1)), sprintf(' %d', s));
        end
        xlabel('In-Phase Amplitude');
        ylabel('Quadrature Amplitude');
        title(sprintf('%d-QAM', M));
    end
end
