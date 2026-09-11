function writelines(lignes, nomFichier, varargin)
%WRITELINES Écrit un texte dans un fichier, une ligne par élément.
%   WRITELINES(L,FICHIER) écrit chaque élément de L sur sa propre ligne.
%   WRITELINES(...,'WriteMode','append') ajoute à la suite au lieu de
%   remplacer. WRITELINES(...,'LineEnding',SEP) choisit la fin de ligne.
%
%   Le fichier se termine par une fin de ligne, comme le veut l'usage :
%   c'est ce qui fait qu'un outil de ligne de commande affiche la dernière
%   ligne correctement, et READLINES ne la compte pas pour autant.
%
%   Exemple :
%      f = [tempname '.txt'];
%      writelines(["une"; "deux"; "trois"], f);
%      isequal(readlines(f), ["une"; "deux"; "trois"])   % l'aller-retour revient
%      delete(f);
%
%   Voir aussi READLINES, FPRINTF, WRITETABLE, FILEWRITE.
    options = matlibre_lire_options(varargin, ...
                                    struct('WriteMode', 'overwrite', ...
                                           'LineEnding', sprintf('\n')));
    if ischar(lignes)
        liste = {lignes};
    elseif iscell(lignes)
        liste = cellfun(@char, lignes, 'UniformOutput', false);
    else
        liste = cellstr(string(lignes));
    end
    fin = char(options.LineEnding);
    texte = '';
    for k = 1:numel(liste)
        texte = [texte, liste{k}, fin];   %#ok<AGROW>
    end
    if strcmpi(options.WriteMode, 'append')
        identifiant = fopen(nomFichier, 'a');
    else
        identifiant = fopen(nomFichier, 'w');
    end
    if identifiant < 0
        error('MATLAB:writelines:ouverture', ...
              'Impossible d''ouvrir %s en écriture.', nomFichier);
    end
    fprintf(identifiant, '%s', texte);
    fclose(identifiant);
end
