function s = matlibre_xml_en_structure(noeud)
%MATLIBRE_XML_EN_STRUCTURE Convertit un arbre XML en structure.
%   Un élément sans enfant ni attribut devient son texte, converti en
%   nombre s'il en est un. Sinon, il devient une structure : un champ par
%   enfant, et un champ « nomAttribute » par attribut.
%
%   Des frères de même nom deviennent un tableau de structures — ou une
%   cellule quand leurs formes diffèrent —, ce qui est la façon dont le
%   XML exprime une liste.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      s = matlibre_xml_en_structure(matlibre_xml_analyser('<a><b>1</b></a>'));
%      s.b                             % 1
%
%   Voir aussi READSTRUCT, MATLIBRE_XML_ANALYSER.
    attributs = fieldnames(noeud.Attributes);
    if isempty(noeud.Children) && isempty(attributs)
        s = matlibre_texte_ou_nombre(noeud.Text);
        return
    end
    s = struct();
    for k = 1:numel(attributs)
        s.([attributs{k} 'Attribute']) = ...
            matlibre_texte_ou_nombre(noeud.Attributes.(attributs{k}));
    end
    noms = cell(numel(noeud.Children), 1);
    for k = 1:numel(noeud.Children)
        noms{k} = matlibre_nom_valide(noeud.Children{k}.Name);
    end
    distincts = unique(noms, 'stable');
    for k = 1:numel(distincts)
        memes = find(strcmp(noms, distincts{k}));
        valeurs = cell(numel(memes), 1);
        for j = 1:numel(memes)
            valeurs{j} = matlibre_xml_en_structure(noeud.Children{memes(j)});
        end
        if numel(valeurs) == 1
            s.(distincts{k}) = valeurs{1};
        elseif all(cellfun(@isstruct, valeurs)) && ...
               all(cellfun(@(v) isequal(sort(fieldnames(v)), ...
                                        sort(fieldnames(valeurs{1}))), valeurs))
            liste = valeurs{1};
            for j = 2:numel(valeurs)
                liste(j) = valeurs{j};
            end
            s.(distincts{k}) = liste;
        elseif all(cellfun(@(v) isnumeric(v) && isscalar(v), valeurs))
            s.(distincts{k}) = cell2mat(valeurs);
        else
            s.(distincts{k}) = valeurs;
        end
    end
    texte = strtrim(noeud.Text);
    if ~isempty(texte)
        s.Text = matlibre_texte_ou_nombre(texte);
    end
end
