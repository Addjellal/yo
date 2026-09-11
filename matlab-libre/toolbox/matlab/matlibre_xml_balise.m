function [nom, attributs] = matlibre_xml_balise(balise)
%MATLIBRE_XML_BALISE Nom et attributs d'une balise ouvrante.
%   Les attributs sont rendus dans une structure : un champ par attribut,
%   sa valeur étant le texte entre guillemets, déjà déséchappé.
%
%   La valeur peut être entourée de guillemets ou d'apostrophes : le XML
%   accepte les deux, et le délimiteur choisi permet d'écrire l'autre tel
%   quel à l'intérieur.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [n, a] = matlibre_xml_balise('point x="1" y="2"');
%      n                               % 'point'
%      a.x                             % '1'
%
%   Voir aussi MATLIBRE_XML_ANALYSER, READSTRUCT.
    balise = strtrim(balise);
    espace = find(balise == ' ' | balise == sprintf('\t') | balise == sprintf('\n'), 1);
    if isempty(espace)
        nom = balise;
        attributs = struct();
        return
    end
    nom = balise(1:espace-1);
    reste = strtrim(balise(espace:end));
    attributs = struct();
    while ~isempty(reste)
        egal = find(reste == '=', 1);
        if isempty(egal)
            break
        end
        cle = strtrim(reste(1:egal-1));
        reste = strtrim(reste(egal+1:end));
        if isempty(reste)
            break
        end
        delimiteur = reste(1);
        if delimiteur ~= '"' && delimiteur ~= ''''
            break
        end
        ferme = find(reste(2:end) == delimiteur, 1);
        if isempty(ferme)
            error('MATLAB:xml:attribut', ...
                  'Valeur d''attribut non fermée dans « %s ».', nom);
        end
        valeur = reste(2:ferme);
        reste = strtrim(reste(ferme+2:end));
        if ~isempty(cle)
            attributs.(matlibre_nom_valide(cle)) = matlibre_xml_desechapper(valeur);
        end
    end
end
