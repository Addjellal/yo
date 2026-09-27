classdef fimath
%FIMATH Les règles de calcul des nombres à virgule fixe.
%   F = FIMATH rend les règles par défaut : arrondi au plus proche
%   (Nearest), saturation au débordement (Saturate), produits et sommes en
%   pleine précision (FullPrecision).
%   F = FIMATH('Nom', valeur, ...) les règle :
%      RoundingMethod   Ceiling, Convergent, Floor, Nearest, Round, Zero
%      OverflowAction   Saturate, Wrap
%      ProductMode      FullPrecision, KeepLSB, KeepMSB, SpecifyPrecision
%      ProductWordLength, ProductFractionLength   (32 et 30)
%      SumMode          FullPrecision, KeepLSB, KeepMSB, SpecifyPrecision
%      SumWordLength, SumFractionLength           (32 et 30)
%      MaxProductWordLength, MaxSumWordLength     (65535)
%      CastBeforeSum    true
%
%   En pleine précision, une somme garde la plus fine des échelles et
%   prend un bit de plus pour sa partie entière ; un produit additionne
%   les tailles et les bits après la virgule. KeepLSB garde les bits de
%   poids faible sur ProductWordLength (SumWordLength) bits, KeepMSB ceux
%   de poids fort ; SpecifyPrecision impose taille et virgule.
%
%   Exemple :
%      F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
%      a = fi(pi, 1, 8, 5, F)            % 3.1250
%
%   Voir aussi FI, NUMERICTYPE.
    properties
        RoundingMethod = 'Nearest'
        OverflowAction = 'Saturate'
        ProductMode = 'FullPrecision'
        ProductWordLength = 32
        ProductFractionLength = 30
        MaxProductWordLength = 65535
        SumMode = 'FullPrecision'
        SumWordLength = 32
        SumFractionLength = 30
        MaxSumWordLength = 65535
        CastBeforeSum = true
    end
    methods
        function F = fimath(varargin)
            if mod(nargin, 2) ~= 0
                error('fixed:fimath:invalidPVPairs', ...
                      'Les proprietes de FIMATH se donnent par paires nom, valeur.');
            end
            for i = 1:2:nargin
                F = poserRegle(F, char(varargin{i}), varargin{i + 1});
            end
        end
        function F = set.RoundingMethod(F, v)
            F.RoundingMethod = choisirRegle(v, {'Ceiling', 'Convergent', 'Floor', 'Nearest', ...
                                                'Round', 'Zero'}, 'RoundingMethod');
        end
        function F = set.OverflowAction(F, v)
            F.OverflowAction = choisirRegle(v, {'Saturate', 'Wrap'}, 'OverflowAction');
        end
        function F = set.ProductMode(F, v)
            F.ProductMode = choisirRegle(v, {'FullPrecision', 'KeepLSB', 'KeepMSB', ...
                                             'SpecifyPrecision'}, 'ProductMode');
        end
        function F = set.SumMode(F, v)
            F.SumMode = choisirRegle(v, {'FullPrecision', 'KeepLSB', 'KeepMSB', ...
                                         'SpecifyPrecision'}, 'SumMode');
        end
        function oui = isequal(A, B, varargin)
            noms = {'RoundingMethod', 'OverflowAction', 'ProductMode', 'ProductWordLength', ...
                    'ProductFractionLength', 'SumMode', 'SumWordLength', 'SumFractionLength', ...
                    'CastBeforeSum'};
            oui = isa(B, 'embedded.fimath');
            for i = 1:numel(noms)
                oui = oui && isequal(A.(noms{i}), B.(noms{i}));
            end
            for i = 1:numel(varargin)
                oui = oui && isequal(A, varargin{i});
            end
        end
        function L = lignes(F)
            L = {'RoundingMethod', F.RoundingMethod; 'OverflowAction', F.OverflowAction; ...
                 'ProductMode', F.ProductMode};
            if ~strcmp(F.ProductMode, 'FullPrecision')
                L(end + 1, :) = {'ProductWordLength', sprintf('%d', F.ProductWordLength)};
                if strcmp(F.ProductMode, 'SpecifyPrecision')
                    L(end + 1, :) = {'ProductFractionLength', ...
                                     sprintf('%d', F.ProductFractionLength)};
                end
            end
            L(end + 1, :) = {'SumMode', F.SumMode};
            if ~strcmp(F.SumMode, 'FullPrecision')
                L(end + 1, :) = {'SumWordLength', sprintf('%d', F.SumWordLength)};
                if strcmp(F.SumMode, 'SpecifyPrecision')
                    L(end + 1, :) = {'SumFractionLength', sprintf('%d', F.SumFractionLength)};
                end
                L(end + 1, :) = {'CastBeforeSum', mat2str(logical(F.CastBeforeSum))};
            end
        end
        function disp(F)
            L = lignes(F);
            for i = 1:size(L, 1)
                fprintf('%22s: %s\n', L{i, 1}, L{i, 2});
            end
        end
    end
end

function F = poserRegle(F, nom, v)
    noms = properties(F);
    k = find(strcmpi(nom, noms), 1);
    if isempty(k)
        error('fixed:fimath:invalidProperty', 'FIMATH n''a pas de propriete ''%s''.', nom);
    end
    F.(noms{k}) = v;
end

function v = choisirRegle(v, choix, nom)
    k = find(strcmpi(char(v), choix), 1);
    if isempty(k)
        error('fixed:fimath:invalidValue', '%s vaut %s.', nom, strjoin(choix, ', '));
    end
    v = choix{k};
end
