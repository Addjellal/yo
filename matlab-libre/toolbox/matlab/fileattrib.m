function [reussi, message, attributs] = fileattrib(nom, mode, varargin)
%FILEATTRIB Lit ou change les attributs d'un fichier.
%   [OK,MSG,A] = FILEATTRIB(F) rend une structure décrivant F : son nom
%   complet, s'il est un dossier, et les droits de lecture, d'écriture et
%   d'exécution de l'utilisateur.
%
%   FILEATTRIB(F,MODE) change les droits. MODE s'écrit comme dans un
%   terminal : '+w' donne le droit d'écriture, '-w' le retire, '+x'
%   rend exécutable.
%
%   Exemple :
%      f = fullfile(tempdir, 'essai.txt');
%      fid = fopen(f, 'w'); fclose(fid);
%      [ok, ~, a] = fileattrib(f);
%
%   Voir aussi DIR, EXIST, ISFILE, ISFOLDER, DELETE.
    if nargin < 1
        nom = pwd();
    end
    nom = char(nom);
    reussi = false;
    message = '';
    attributs = struct();
    if ~isfile(nom) && ~isfolder(nom)
        message = sprintf('%s : fichier introuvable.', nom);
        return;
    end
    if nargin >= 2 && ~isempty(mode)
        mode = char(mode);
        [etat, sortie] = system(sprintf('chmod %s "%s"', mode, nom));
        if etat ~= 0
            message = strtrim(sortie);
            return;
        end
    end
    complet = nom;
    if ~isAbsolu(nom)
        complet = fullfile(pwd(), nom);
    end
    attributs = struct('Name', complet, ...
                       'archive', 0, ...
                       'system', 0, ...
                       'hidden', double(estCache(nom)), ...
                       'directory', double(isfolder(nom)), ...
                       'UserRead', double(droit(nom, '-r')), ...
                       'UserWrite', double(droit(nom, '-w')), ...
                       'UserExecute', double(droit(nom, '-x')));
    reussi = true;
end

function tf = droit(nom, test)
% Le shell sait dire si un fichier est lisible, inscriptible ou
% exécutable ; c'est plus sûr que de deviner d'après le mode affiché.
    etat = system(sprintf('test %s "%s"', test, nom));
    tf = (etat == 0);
end

function tf = estCache(nom)
    [~, base, ext] = fileparts(nom);
    base = [base ext];
    tf = ~isempty(base) && base(1) == '.';
end

function tf = isAbsolu(nom)
    tf = ~isempty(nom) && (nom(1) == '/' || nom(1) == '\' || ...
        (numel(nom) > 1 && nom(2) == ':'));
end
