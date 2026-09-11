function texte = matlibre_structure_en_xml(valeur, nom, profondeur)
%MATLIBRE_STRUCTURE_EN_XML Écrit une valeur en XML, récursivement.
%   Un champ dont le nom finit par « Attribute » devient un attribut de
%   l'élément qui le porte ; les autres deviennent des éléments enfants.
%   Un tableau de structures devient une suite d'éléments frères de même
%   nom, ce qui est la façon dont le XML exprime une liste.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      t = matlibre_structure_en_xml(struct('a', 1), 'racine', 0);
%      ~isempty(strfind(t, '<a>1</a>'))
%
%   Voir aussi WRITESTRUCT, READSTRUCT.
    marge = repmat('  ', 1, profondeur);
    if isstruct(valeur) && numel(valeur) > 1
        parties = cell(numel(valeur), 1);
        for k = 1:numel(valeur)
            parties{k} = matlibre_structure_en_xml(valeur(k), nom, profondeur);
        end
        texte = strjoin(parties', '');
        return
    end
    if isstruct(valeur)
        champs = fieldnames(valeur);
        attributs = '';
        corps = '';
        for k = 1:numel(champs)
            champ = champs{k};
            if numel(champ) > 9 && strcmp(champ(end-8:end), 'Attribute')
                attributs = [attributs, ' ', champ(1:end-9), '="', ...
                             matlibre_xml_echapper(enTexte(valeur.(champ))), '"'];   %#ok<AGROW>
            else
                corps = [corps, matlibre_structure_en_xml(valeur.(champ), champ, ...
                                                          profondeur + 1)];   %#ok<AGROW>
            end
        end
        if isempty(corps)
            texte = [marge, '<', nom, attributs, '/>', sprintf('\n')];
        else
            texte = [marge, '<', nom, attributs, '>', sprintf('\n'), ...
                     corps, marge, '</', nom, '>', sprintf('\n')];
        end
        return
    end
    if iscell(valeur)
        parties = cell(numel(valeur), 1);
        for k = 1:numel(valeur)
            parties{k} = matlibre_structure_en_xml(valeur{k}, nom, profondeur);
        end
        texte = strjoin(parties', '');
        return
    end
    if ~ischar(valeur) && numel(valeur) > 1
        parties = cell(numel(valeur), 1);
        for k = 1:numel(valeur)
            parties{k} = matlibre_structure_en_xml(valeur(k), nom, profondeur);
        end
        texte = strjoin(parties', '');
        return
    end
    texte = [marge, '<', nom, '>', matlibre_xml_echapper(enTexte(valeur)), ...
             '</', nom, '>', sprintf('\n')];
end

function t = enTexte(v)
% Un nombre s'ecrit avec tous ses chiffres : sans cela l'aller-retour
% perdrait de la precision en silence.
    if ischar(v)
        t = v;
    elseif isstring(v)
        t = char(v);
    elseif islogical(v)
        t = char(string(double(v)));
    elseif isnumeric(v)
        if v == floor(v) && abs(v) < 1e15
            t = sprintf('%d', v);
        else
            t = sprintf('%.17g', v);
        end
    else
        t = char(string(v));
    end
end
