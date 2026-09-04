function texte = cur2frac(valeur, denominateur)
%CUR2FRAC Montant décimal écrit en fraction.
%   T = CUR2FRAC(VALEUR,D) écrit la partie fractionnaire comme un nombre
%   de D-ièmes, à la manière des cours obligataires américains : 101.5
%   avec un dénominateur de 32 s'écrit 101.16, ces 16 étant des
%   trente-deuxièmes.
%
%   Exemple :
%      cur2frac(12.125, 8)      % 12.1
%      cur2frac(101.5, 32)      % 101.16
%
%   Voir aussi FRAC2CUR, DEC2THIRTYTWO, CUR2STR.
    if nargin < 2 || isempty(denominateur)
        denominateur = 32;
    end
    valeur = double(valeur);
    signe = '';
    if valeur < 0
        signe = '-';
        valeur = -valeur;
    end
    entier = floor(valeur);
    numerateur = round((valeur - entier) * denominateur);
    if numerateur >= denominateur
        entier = entier + 1;
        numerateur = 0;
    end
    chiffres = numel(sprintf('%d', denominateur - 1));
    texte = sprintf('%s%d.%0*d', signe, entier, chiffres, numerateur);
end
