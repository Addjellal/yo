function noeud = matlibre_xml_analyser(texte)
%MATLIBRE_XML_ANALYSER Arbre d'un document XML.
%   Le nœud rendu porte les champs Name, Attributes, Children et Text.
%   L'analyse est descendante : on lit les balises dans l'ordre, on
%   empile à l'ouverture et l'on dépile à la fermeture, en vérifiant que
%   le nom concorde — un document mal fermé est refusé, non deviné.
%
%   Ce qui n'est pas traité : les entités autres que les cinq
%   prédéfinies, les espaces de noms, les définitions de type. Une balise
%   de traitement — la déclaration en tête — et un commentaire sont
%   sautés.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      n = matlibre_xml_analyser('<a><b>1</b></a>');
%      n.Name                          % 'a'
%      numel(n.Children)               % 1
%
%   Voir aussi READSTRUCT, XMLREAD.
    texte = char(texte);
    position = 1;
    pile = {};
    racine = [];
    while position <= numel(texte)
        debut = strfind(texte(position:end), '<');
        if isempty(debut)
            break
        end
        debut = position + debut(1) - 1;
        % Le texte qui precede la balise appartient a l'element ouvert.
        if debut > position && ~isempty(pile)
            contenu = strtrim(texte(position:debut-1));
            if ~isempty(contenu)
                pile{end}.Text = [pile{end}.Text, matlibre_xml_desechapper(contenu)];
            end
        end
        fin = strfind(texte(debut:end), '>');
        if isempty(fin)
            error('MATLAB:xml:balise', 'Balise non fermée à la position %d.', debut);
        end
        fin = debut + fin(1) - 1;
        balise = texte(debut+1:fin-1);
        position = fin + 1;

        if isempty(balise)
            continue
        end
        if balise(1) == '?' || balise(1) == '!'
            continue                    % declaration, commentaire, doctype
        end
        if balise(1) == '/'
            nom = strtrim(balise(2:end));
            if isempty(pile)
                error('MATLAB:xml:fermeture', ...
                      'Fermeture de « %s » sans ouverture.', nom);
            end
            ferme = pile{end};
            if ~strcmp(ferme.Name, nom)
                error('MATLAB:xml:concordance', ...
                      'Fermeture de « %s » alors que « %s » est ouvert.', ...
                      nom, ferme.Name);
            end
            pile(end) = [];
            if isempty(pile)
                racine = ferme;
            else
                pile{end}.Children{end+1} = ferme;
            end
            continue
        end
        seul = ~isempty(balise) && balise(end) == '/';
        if seul
            balise = balise(1:end-1);
        end
        [nom, attributs] = matlibre_xml_balise(balise);
        element = struct('Name', nom, 'Attributes', attributs, ...
                         'Children', {{}}, 'Text', '');
        if seul
            if isempty(pile)
                racine = element;
            else
                pile{end}.Children{end+1} = element;
            end
        else
            pile{end+1} = element;   %#ok<AGROW>
        end
    end
    if ~isempty(pile)
        error('MATLAB:xml:ouvert', ...
              'L''élément « %s » n''est pas fermé.', pile{end}.Name);
    end
    if isempty(racine)
        error('MATLAB:xml:vide', 'Le document ne porte aucun élément.');
    end
    noeud = racine;
end
