function nom = matlibre_nom_valide(texte)
%MATLIBRE_NOM_VALIDE Fait d'un texte un nom de champ acceptable.
%   Les caractères qui ne peuvent pas figurer dans un nom deviennent des
%   soulignés, et un nom qui commence par un chiffre reçoit un « x » en
%   tête : un champ de structure ne peut pas commencer par un chiffre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB —
%   c'est MATLAB.LANG.MAKEVALIDNAME qui y répond.
%
%   Exemple :
%      matlibre_nom_valide('a-b')      % 'a_b'
%      matlibre_nom_valide('2x')       % 'x2x'
%
%   Voir aussi MATLIBRE_XML_BALISE, GENVARNAME, ISVARNAME.
    nom = char(texte);
    garde = isstrprop(nom, 'alphanum') | nom == '_';
    nom(~garde) = '_';
    if isempty(nom)
        nom = 'x';
    elseif ~isstrprop(nom(1), 'alpha')
        nom = ['x' nom];
    end
end
