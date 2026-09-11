function writestruct(s, nomFichier, varargin)
%WRITESTRUCT Écrit une structure en XML ou en JSON.
%   WRITESTRUCT(S,FICHIER) reconnaît le format à l'extension : .xml ou
%   .json. WRITESTRUCT(...,'FileType',TYPE) l'impose.
%   WRITESTRUCT(...,'StructNodeName',NOM) nomme la racine du XML ;
%   « struct » par défaut, comme dans MATLAB.
%
%   Un champ devient un élément ; un champ dont le nom finit par
%   « Attribute » devient un attribut de l'élément parent. Un tableau de
%   structures devient une suite d'éléments frères de même nom.
%
%   Exemple :
%      f = [tempname '.xml'];
%      s = struct('nom', "essai", 'valeur', 42);
%      writestruct(s, f);
%      r = readstruct(f);
%      r.valeur == 42                  % l'aller-retour revient
%      delete(f);
%
%   Voir aussi READSTRUCT, XMLWRITE, JSONENCODE, WRITETABLE.
    options = matlibre_lire_options(varargin, ...
                                    struct('FileType', '', 'StructNodeName', 'struct'));
    type = char(options.FileType);
    if isempty(type)
        [~, ~, extension] = fileparts(char(nomFichier));
        type = lower(strrep(extension, '.', ''));
    end
    switch lower(type)
        case 'json'
            texte = jsonencode(s);
        case 'xml'
            texte = ['<?xml version="1.0" encoding="UTF-8"?>' sprintf('\n') ...
                     matlibre_structure_en_xml(s, char(options.StructNodeName), 0)];
        otherwise
            error('MATLAB:writestruct:type', ...
                  'WRITESTRUCT écrit le XML et le JSON, pas « %s ».', type);
    end
    identifiant = fopen(nomFichier, 'w');
    if identifiant < 0
        error('MATLAB:writestruct:ouverture', ...
              'Impossible d''ouvrir %s en écriture.', nomFichier);
    end
    fprintf(identifiant, '%s', texte);
    fclose(identifiant);
end
