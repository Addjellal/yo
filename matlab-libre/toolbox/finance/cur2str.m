function texte = cur2str(valeur, decimales)
%CUR2STR Montant écrit comme une somme d'argent.
%   T = CUR2STR(VALEUR,N) écrit la valeur avec N décimales, précédée du
%   signe monétaire, les montants négatifs étant mis entre parenthèses
%   comme le veut l'usage comptable. N vaut 2 par défaut.
%
%   Exemple :
%      cur2str(1234.5)        % $1234.50
%      cur2str(-1234.5)       % ($1234.50)
%
%   Voir aussi CUR2FRAC, FRAC2CUR, NUM2STR.
    if nargin < 2 || isempty(decimales)
        decimales = 2;
    end
    valeur = double(valeur);
    format = sprintf('%%.%df', abs(round(decimales)));
    corps = sprintf(format, abs(valeur));
    if valeur < 0
        texte = ['($', corps, ')'];
    else
        texte = ['$', corps];
    end
end
