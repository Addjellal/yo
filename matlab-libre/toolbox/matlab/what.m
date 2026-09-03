function s = what(dossier)
%WHAT Inventaire des fichiers MATLAB d'un dossier.
%   S = WHAT(D) rend une structure décrivant le contenu de D : les
%   fichiers .m, .mat, .mlx, .mex, les classes (@) et les paquets (+).
%   Sans sortie, l'inventaire s'affiche.
%
%   Sans argument, WHAT décrit le dossier courant.
%
%   Exemple :
%      s = what(fullfile(matlabroot, 'toolbox', 'matlab'));
%      numel(s.m)
%
%   Voir aussi DIR, WHICH, EXIST, LS.
    if nargin < 1
        dossier = pwd();
    end
    dossier = char(dossier);
    if ~isfolder(dossier)
        error('MATLAB:what:NotAFolder', 'Dossier introuvable : %s.', dossier);
    end
    s = struct('path', dossier, 'm', {{}}, 'mlx', {{}}, 'mat', {{}}, ...
               'mex', {{}}, 'mdl', {{}}, 'slx', {{}}, 'p', {{}}, ...
               'classes', {{}}, 'packages', {{}});
    entrees = dir(dossier);
    for k = 1:numel(entrees)
        e = entrees(k);
        nom = e.name;
        if strcmp(nom, '.') || strcmp(nom, '..')
            continue;
        end
        if e.isdir
            if nom(1) == '@'
                s.classes{end+1} = nom(2:end);
            elseif nom(1) == '+'
                s.packages{end+1} = nom(2:end);
            end
            continue;
        end
        [~, ~, ext] = fileparts(nom);
        switch lower(ext)
            case '.m',   s.m{end+1} = nom;
            case '.mlx', s.mlx{end+1} = nom;
            case '.mat', s.mat{end+1} = nom;
            case '.mex', s.mex{end+1} = nom;
            case '.mdl', s.mdl{end+1} = nom;
            case '.slx', s.slx{end+1} = nom;
            case '.p',   s.p{end+1} = nom;
        end
    end
    if nargout == 0
        afficher(s);
        clear s;
    end
end

function afficher(s)
    fprintf('\nFichiers MATLAB dans le dossier %s\n\n', s.path);
    champs = {'m', 'mlx', 'mat', 'mex', 'p', 'classes', 'packages'};
    titres = {'Fichiers M', 'Fichiers MLX', 'Fichiers MAT', 'Fichiers MEX', ...
              'Fichiers P', 'Classes', 'Paquets'};
    for k = 1:numel(champs)
        liste = s.(champs{k});
        if isempty(liste)
            continue;
        end
        fprintf('%s :\n\n', titres{k});
        for j = 1:numel(liste)
            fprintf('    %s\n', liste{j});
        end
        fprintf('\n');
    end
end
