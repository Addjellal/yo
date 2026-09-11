function texte = matlibre_xml_ecrire(noeud, profondeur)
%MATLIBRE_XML_ECRIRE Écrit un arbre XML, récursivement.
%   Un élément sans enfant ni texte s'écrit en balise seule ; un élément
%   qui ne porte que du texte tient sur une ligne ; les autres ouvrent un
%   bloc indenté. C'est la forme que produit un éditeur XML, et celle qui
%   se relit le mieux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      t = matlibre_xml_ecrire(matlibre_xml_analyser('<a>1</a>'), 0);
%      ~isempty(strfind(t, '<a>1</a>'))
%
%   Voir aussi XMLWRITE, XMLREAD.
    marge = repmat('  ', 1, profondeur);
    attributs = '';
    noms = fieldnames(noeud.Attributes);
    for k = 1:numel(noms)
        attributs = [attributs, ' ', noms{k}, '="', ...
                     matlibre_xml_echapper(char(noeud.Attributes.(noms{k}))), '"'];   %#ok<AGROW>
    end
    contenu = strtrim(char(noeud.Text));
    if isempty(noeud.Children)
        if isempty(contenu)
            texte = [marge, '<', noeud.Name, attributs, '/>', sprintf('\n')];
        else
            texte = [marge, '<', noeud.Name, attributs, '>', ...
                     matlibre_xml_echapper(contenu), ...
                     '</', noeud.Name, '>', sprintf('\n')];
        end
        return
    end
    corps = '';
    for k = 1:numel(noeud.Children)
        corps = [corps, matlibre_xml_ecrire(noeud.Children{k}, profondeur + 1)];   %#ok<AGROW>
    end
    texte = [marge, '<', noeud.Name, attributs, '>', sprintf('\n'), ...
             corps, marge, '</', noeud.Name, '>', sprintf('\n')];
end
