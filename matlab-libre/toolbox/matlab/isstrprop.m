function masque = isstrprop(texte, propriete)
%ISSTRPROP Nature de chaque caractère d'un texte.
%   M = ISSTRPROP(TEXTE,PROPRIETE) rend un tableau logique de la taille du
%   texte, vrai là où le caractère a la propriété demandée.
%
%   Propriétés reconnues : 'alpha', 'alphanum', 'digit', 'xdigit',
%   'lower', 'upper', 'punct', 'wspace', 'cntrl', 'graphic', 'print'.
%
%   TEXTE peut être un tableau de caractères, un tableau de cellules de
%   chaînes — le résultat est alors une cellule de masques — ou un
%   tableau de nombres, lus comme des codes de caractères.
%
%   Exemple :
%      isstrprop('a1 ', 'digit')      % 0 1 0
%
%   Voir aussi ISLETTER, ISSPACE, REGEXP.
    if iscell(texte)
        masque = cell(size(texte));
        for k = 1:numel(texte)
            masque{k} = isstrprop(texte{k}, propriete);
        end
        return
    end
    codes = double(texte);
    switch lower(char(propriete))
        case 'alpha'
            masque = (codes >= 65 & codes <= 90) | (codes >= 97 & codes <= 122);
        case 'digit'
            masque = codes >= 48 & codes <= 57;
        case 'alphanum'
            masque = isstrprop(texte, 'alpha') | isstrprop(texte, 'digit');
        case 'xdigit'
            masque = isstrprop(texte, 'digit') | ...
                     (codes >= 65 & codes <= 70) | (codes >= 97 & codes <= 102);
        case 'lower'
            masque = codes >= 97 & codes <= 122;
        case 'upper'
            masque = codes >= 65 & codes <= 90;
        case 'wspace'
            masque = codes == 32 | (codes >= 9 & codes <= 13);
        case 'cntrl'
            masque = codes < 32 | codes == 127;
        case 'punct'
            % Ce qui s'imprime sans être ni lettre, ni chiffre, ni espace.
            masque = codes >= 33 & codes <= 126 & ~isstrprop(texte, 'alphanum');
        case 'graphic'
            masque = codes > 32 & codes ~= 127;
        case 'print'
            masque = codes >= 32 & codes ~= 127;
        otherwise
            error('MATLAB:isstrprop:Propriete', ...
                  'Propriété inconnue : %s.', char(propriete));
    end
    masque = reshape(logical(masque), size(codes));
end
