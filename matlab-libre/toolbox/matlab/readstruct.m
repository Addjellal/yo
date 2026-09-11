function s = readstruct(nomFichier, varargin)
%READSTRUCT Lit un fichier XML ou JSON dans une structure.
%   S = READSTRUCT(FICHIER) reconnaît le format à l'extension : .xml ou
%   .json. S = READSTRUCT(...,'FileType',TYPE) l'impose.
%
%   Un élément XML devient un champ ; ses attributs deviennent des champs
%   dont le nom porte le suffixe « Attribute », comme dans MATLAB. Des
%   éléments frères de même nom deviennent un tableau de structures.
%
%   Le texte d'un élément est converti en nombre quand il en est un :
%   c'est ce que fait MATLAB, et c'est ce qui permet de relire un fichier
%   écrit par WRITESTRUCT sans rien reconvertir.
%
%   Exemple :
%      f = [tempname '.xml'];
%      writestruct(struct('a', 1, 'b', "deux"), f);
%      s = readstruct(f);
%      s.a                             % 1, en nombre
%      delete(f);
%
%   Voir aussi WRITESTRUCT, XMLREAD, JSONDECODE, READTABLE.
    options = matlibre_lire_options(varargin, struct('FileType', ''));
    type = char(options.FileType);
    if isempty(type)
        [~, ~, extension] = fileparts(char(nomFichier));
        type = lower(strrep(extension, '.', ''));
    end
    texte = fileread(nomFichier);
    switch lower(type)
        case 'json'
            s = jsondecode(texte);
        case 'xml'
            s = matlibre_xml_en_structure(matlibre_xml_analyser(texte));
        otherwise
            error('MATLAB:readstruct:type', ...
                  'READSTRUCT lit le XML et le JSON, pas « %s ».', type);
    end
end
