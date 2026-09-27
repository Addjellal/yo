function T = numerictype(varargin)
%NUMERICTYPE Le type d'un nombre à virgule fixe : signe, taille, échelle.
%   T = NUMERICTYPE rend le type par défaut : signé, mots de 16 bits dont
%   15 après la virgule.
%   T = NUMERICTYPE(S) et T = NUMERICTYPE(S,W) : signé ou non, mots de W
%   bits ; l'échelle reste à fixer — FI prend alors la meilleure précision.
%   T = NUMERICTYPE(S,W,F) : F bits après la virgule.
%   T = NUMERICTYPE(S,W,PENTE,BIAIS) : une valeur vaut PENTE fois son
%   entier stocké, plus BIAIS.
%   T = NUMERICTYPE(S,W,AJUSTEMENT,EXPOSANT,BIAIS) : la pente vaut
%   AJUSTEMENT * 2^EXPOSANT, AJUSTEMENT allant de 1 à 2.
%   T = NUMERICTYPE('double'), NUMERICTYPE('single'),
%   NUMERICTYPE('boolean').
%   T = NUMERICTYPE(A) rend le type du FI A.
%   Les propriétés se donnent aussi par paires : NUMERICTYPE('Signed',
%   false, 'WordLength', 8, 'FractionLength', 4).
%
%   Propriétés : DataTypeMode, Signed, Signedness, WordLength,
%   FractionLength, Slope, Bias, FixedExponent, SlopeAdjustmentFactor,
%   Scaling ('BinaryPoint', 'SlopeBias' ou 'Unspecified').
%
%   Exemple :
%      T = numerictype(1, 16, 8)
%      T.Slope                        % 0.0039
%      a = fi(pi, T)                  % 3.1406
%      numerictype(0, 8, 0.5, 10)     % pente 0.5, biais 10
%
%   Voir aussi FI, FIMATH, FIXDT.
    if nargin == 1 && isa(varargin{1}, 'embedded.fi')
        T = varargin{1}.Type;
        return
    end
    T = embedded.numerictype(varargin{:});
end
