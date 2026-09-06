function noeuds = matlibre_rob_xml(texte)
%MATLIBRE_ROB_XML Lecture d'un document XML simple.
%   NOEUDS = MATLIBRE_ROB_XML(TEXTE) rend un tableau de structures à
%   quatre champs : Nom, Attributs — une structure nom-valeur —, Enfants,
%   et Texte.
%
%   Le lecteur couvre ce qu'un fichier URDF emploie : éléments, attributs
%   entre guillemets simples ou doubles, balises auto-fermantes,
%   commentaires et déclaration initiale. Il ne prétend pas lire le XML
%   dans toute sa généralité — ni entités, ni espaces de noms, ni
%   sections littérales — parce qu'un URDF n'en a pas besoin.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    texte = char(texte(:)).';
    % Commentaires et déclarations, qui ne portent rien d'utile ici.
    texte = regexprep(texte, '<!--.*?-->', '');
    texte = regexprep(texte, '<\?.*?\?>', '');
    texte = regexprep(texte, '<!DOCTYPE[^>]*>', '');
    [noeuds, ~] = lireSuite(texte, 1);
end

function [noeuds, position] = lireSuite(texte, position)
%LIRESUITE Lit les frères jusqu'à la balise fermante qui les termine.
    noeuds = struct('Nom', {}, 'Attributs', {}, 'Enfants', {}, 'Texte', {});
    n = numel(texte);
    while position <= n
        debut = strfind(texte(position:end), '<');
        if isempty(debut)
            break
        end
        avant = texte(position:position + debut(1) - 2);
        position = position + debut(1) - 1;
        if position < n && texte(position + 1) == '/'
            % Fin du parent : on rend la main, la balise fermante étant
            % consommée par l'appelant.
            fin = find(texte(position:end) == '>', 1);
            position = position + fin;
            noeuds = attacherTexte(noeuds, avant);
            return
        end
        fin = find(texte(position:end) == '>', 1);
        if isempty(fin)
            break
        end
        contenu = texte(position + 1 : position + fin - 2);
        position = position + fin;
        auto = ~isempty(contenu) && contenu(end) == '/';
        if auto
            contenu = contenu(1:end-1);
        end
        [nom, attributs] = lireBalise(contenu);
        noeud = struct('Nom', nom, 'Attributs', attributs, ...
                       'Enfants', struct('Nom', {}, 'Attributs', {}, ...
                                         'Enfants', {}, 'Texte', {}), ...
                       'Texte', '');
        if ~auto
            [enfants, position] = lireSuite(texte, position);
            noeud.Enfants = enfants;
            noeud.Texte = texteDe(enfants);
        end
        noeuds(end + 1) = noeud;   %#ok<AGROW>
    end
end

function noeuds = attacherTexte(noeuds, ~)
%ATTACHERTEXTE Point d'accroche du texte libre, inutile pour un URDF.
end

function t = texteDe(~)
    t = '';
end

function [nom, attributs] = lireBalise(contenu)
%LIREBALISE Sépare le nom de l'élément de ses attributs.
    contenu = strtrim(contenu);
    espace = find(isspace(contenu), 1);
    if isempty(espace)
        nom = contenu;
        attributs = struct();
        return
    end
    nom = contenu(1:espace-1);
    reste = contenu(espace+1:end);
    attributs = struct();
    motif = '([A-Za-z_:][\w.:-]*)\s*=\s*("([^"]*)"|''([^'']*)'')';
    trouves = regexp(reste, motif, 'tokens');
    for k = 1:numel(trouves)
        cle = trouves{k}{1};
        valeur = trouves{k}{2};
        valeur = valeur(2:end-1);
        attributs.(matlab.lang.makeValidName(cle)) = valeur;
    end
end
