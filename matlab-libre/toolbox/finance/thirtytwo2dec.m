function valeur = thirtytwo2dec(entiers, trentedeuxiemes)
%THIRTYTWO2DEC Cours en trente-deuxièmes converti en décimal.
%   V = THIRTYTWO2DEC(ENTIERS,TRENTEDEUXIEMES) est l'inverse de
%   DEC2THIRTYTWO.
%
%   Exemple :
%      thirtytwo2dec(101, 16)     % 101.5
%
%   Voir aussi DEC2THIRTYTWO, FRAC2CUR, CUR2FRAC.
    if nargin < 2 || isempty(trentedeuxiemes)
        trentedeuxiemes = 0;
    end
    valeur = double(entiers) + double(trentedeuxiemes) / 32;
end
