function fichiers = unzip(archive, dossier)
%UNZIP Extrait une archive ZIP.
%   UNZIP(ARCHIVE,DOSSIER) extrait dans le dossier donné, le dossier
%   courant par défaut.
    if nargin < 2 || isempty(dossier), dossier = pwd(); end
    [codeVersion, ~] = system('unzip -v');
    if codeVersion ~= 0
        error('MATLAB:unzip:NoUnzipCommand', 'La commande « unzip » est introuvable.');
    end
    if ~isfolder(dossier)
        mkdir(dossier);
    end
    [code, message] = system(sprintf('unzip -o -q ''%s'' -d ''%s''', archive, dossier));
    if code ~= 0
        error('MATLAB:unzip:Failed', 'L''extraction a echoue : %s', message);
    end
    entrees = dir(dossier);
    fichiers = {};
    for k = 1:numel(entrees)
        if ~entrees(k).isdir
            fichiers{end + 1} = fullfile(dossier, entrees(k).name); %#ok<AGROW>
        end
    end
end
