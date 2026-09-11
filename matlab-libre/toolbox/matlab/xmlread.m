function noeud = xmlread(nomFichier)
%XMLREAD Lit un document XML.
%   N = XMLREAD(FICHIER) rend l'arbre du document : une structure portant
%   Name, Attributes, Children et Text, chaque enfant étant du même
%   genre.
%
%   MATLAB rend ici un objet du modèle DOM de Java. Il n'y a pas de Java
%   dans MatLibre : l'arbre est rendu tel quel, en structures, et se
%   parcourt avec les moyens du langage. Ce qui s'écrit
%   `n.getChildNodes.item(0)` sous MATLAB s'écrit `n.Children{1}` ici.
%
%   Ce qui n'est pas traité : les espaces de noms, les définitions de
%   type, les entités autres que les cinq prédéfinies.
%
%   Exemple :
%      f = [tempname '.xml'];
%      writelines("<mesure unite=""m"">3.5</mesure>", f);
%      n = xmlread(f);
%      n.Name                          % 'mesure'
%      n.Attributes.unite              % 'm'
%      delete(f);
%
%   Voir aussi XMLWRITE, READSTRUCT, WRITESTRUCT, JSONDECODE.
    noeud = matlibre_xml_analyser(fileread(nomFichier));
end
