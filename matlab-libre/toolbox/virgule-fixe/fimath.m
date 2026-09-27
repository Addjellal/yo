function F = fimath(varargin)
%FIMATH Les règles de calcul des nombres à virgule fixe.
%   F = FIMATH rend les règles par défaut : arrondi au plus proche, les
%   milieux vers +Inf (Nearest), saturation au débordement (Saturate),
%   produits et sommes en pleine précision (FullPrecision).
%   F = FIMATH('Nom', valeur, ...) les règle :
%      RoundingMethod   Ceiling, Convergent, Floor, Nearest, Round, Zero
%      OverflowAction   Saturate, Wrap
%      ProductMode      FullPrecision, KeepLSB, KeepMSB, SpecifyPrecision
%      ProductWordLength, ProductFractionLength   (32 et 30)
%      SumMode          FullPrecision, KeepLSB, KeepMSB, SpecifyPrecision
%      SumWordLength, SumFractionLength           (32 et 30)
%      MaxProductWordLength, MaxSumWordLength     (65535)
%      CastBeforeSum    true
%   F = FIMATH(A) rend les règles du FI A.
%
%   En pleine précision, une somme garde la plus fine des échelles et
%   prend un bit de plus ; un produit additionne tailles et bits après la
%   virgule. KeepLSB garde les bits de poids faible sur ProductWordLength
%   (SumWordLength) bits, KeepMSB ceux de poids fort, SpecifyPrecision
%   impose taille et virgule.
%
%   Exemple :
%      F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
%      a = fi(pi, 1, 8, 5, F)         % 3.1250 : arrondi par défaut
%
%   Voir aussi FI, NUMERICTYPE.
    if nargin == 1 && isa(varargin{1}, 'embedded.fi')
        F = varargin{1}.Maths;
        return
    end
    F = embedded.fimath(varargin{:});
end
