function lignes = readlines(nomFichier, varargin)
%READLINES Lit un fichier texte, une ligne par élément.
%   L = READLINES(FICHIER) rend un tableau de chaînes, une par ligne du
%   fichier, les fins de ligne retirées.
%   L = READLINES(FICHIER,'EmptyLineRule','skip') saute les lignes vides.
%   L = READLINES(FICHIER,'LineEnding',SEP) découpe sur SEP plutôt que sur
%   les fins de ligne usuelles.
%
%   Les trois conventions de fin de ligne sont reconnues : celle d'Unix,
%   celle de Windows et celle des anciens Mac. Un fichier écrit sur l'une
%   se relit donc sur l'autre, ce qui est le seul comportement utile.
%
%   Une dernière ligne vide — celle qu'un fichier bien formé laisse après
%   son dernier retour — n'est pas rendue : sans quoi tout aller-retour
%   par WRITELINES ajouterait un élément à chaque passage.
%
%   Exemple :
%      f = [tempname '.txt'];
%      writelines(["premiere"; "deuxieme"], f);
%      l = readlines(f);
%      numel(l)                        % 2
%      delete(f);
%
%   Voir aussi WRITELINES, FILEREAD, READTABLE, STRSPLIT, SPLITLINES.
    options = matlibre_lire_options(varargin, ...
                                    struct('EmptyLineRule', 'read', ...
                                           'LineEnding', ''));
    texte = fileread(nomFichier);
    if isempty(options.LineEnding)
        % On ramene tout a un seul separateur avant de decouper : c'est
        % plus simple que de reconnaitre les trois formes au decoupage.
        texte = strrep(texte, sprintf('\r\n'), sprintf('\n'));
        texte = strrep(texte, sprintf('\r'), sprintf('\n'));
        morceaux = strsplit(texte, sprintf('\n'), 'CollapseDelimiters', false);
    else
        morceaux = strsplit(texte, char(options.LineEnding), ...
                            'CollapseDelimiters', false);
    end
    if ~isempty(morceaux) && isempty(morceaux{end})
        morceaux(end) = [];
    end
    if strcmpi(options.EmptyLineRule, 'skip')
        morceaux = morceaux(~cellfun(@isempty, morceaux));
    end
    lignes = string(morceaux(:));
end
