function z = qamdemod(y, M, varargin)
%QAMDEMOD Démodulation QAM par décision sur la grille de MATLAB.
%   Z = QAMDEMOD(Y,M) rend, pour chaque échantillon reçu, le symbole du
%   point le plus proche de la grille carrée de QAMMOD (ordre de Gray).
%   Z = QAMDEMOD(Y,M,SYMORDER) reprend l'ordre employé à la modulation :
%   'gray', 'bin' ou un vecteur personnalisé.
%
%   Options (nom, valeur) :
%      'OutputType'        'integer' (défaut) ou 'bit' : chaque symbole
%                          rend log2(M) bits, le plus fort en tête, les uns
%                          sous les autres
%      'UnitAveragePower'  true si la constellation émise était ramenée à
%                          un watt (défaut false)
%      'OutputDataType'    'double' (défaut)
%   Les sorties souples de MATLAB ('llr', 'approxllr') ne sont pas
%   encore là : QAMDEMOD les refuse en le disant.
%
%   La grille étant un produit de deux axes, la décision se prend axe par
%   axe : arrondir la partie réelle et la partie imaginaire suffit.
%
%   Exemple :
%      qamdemod(qammod(0:15, 16), 16)          % 0:15
%      qamdemod(-3 + 3i, 16)                   % 0
%
%   Voir aussi QAMMOD, PSKDEMOD, GENQAMDEMOD.
    [ordre, o] = matlibre_qam_options(M, varargin, 'qamdemod', ...
        struct('OutputType', 'integer', 'UnitAveragePower', false, ...
               'OutputDataType', 'double', 'NoiseVariance', 1, 'PlotConstellation', false));
    if ~strcmpi(o.OutputDataType, 'double')
        error('comm:qamdemod:OutputDataType', 'MatLibre produces ''double'' outputs only.');
    end
    if o.UnitAveragePower
        y = y * sqrt(2 * (M - 1) / 3);
    end
    cote = round(sqrt(M));
    colonne = min(max(round((real(y) + cote - 1) / 2), 0), cote - 1);
    ligne = min(max(round((cote - 1 - imag(y)) / 2), 0), cote - 1);
    z = matlibre_qam_symbole(colonne, ligne, cote, ordre);
    switch lower(char(o.OutputType))
        case 'integer'
        case 'bit'
            k = round(log2(M));
            if isrow(z)
                z = z(:);
            end
            nCol = size(z, 2);
            bits = zeros(k, numel(z));
            reste = z(:).';
            for b = k:-1:1
                bits(b, :) = mod(reste, 2);
                reste = floor(reste / 2);
            end
            z = reshape(bits, [], nCol);
        case {'llr', 'approxllr'}
            error('comm:qamdemod:Souple', ...
                  'MatLibre does not compute log-likelihood ratios yet (''%s'').', ...
                  lower(char(o.OutputType)));
        otherwise
            error('comm:qamdemod:OutputType', 'OutputType must be ''integer'' or ''bit''.');
    end
end
