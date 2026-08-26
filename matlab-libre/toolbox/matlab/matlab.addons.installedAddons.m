function t = matlab.addons.installedAddons()
%MATLAB.ADDONS.INSTALLEDADDONS Liste les toolboxes installées.
%   T = MATLAB.ADDONS.INSTALLEDADDONS rend une table à colonnes Name,
%   Version, Enabled et Identifier — une ligne par dossier de la racine
%   des toolboxes.
%
%   Exemple :
%      t = matlab.addons.installedAddons;
%      height(t)
    racine = matlibre_racine_toolbox();
    if isempty(racine) || ~isfolder(racine)
        t = table(cell(0, 1), cell(0, 1), false(0, 1), cell(0, 1), ...
                  'VariableNames', {'Name', 'Version', 'Enabled', 'Identifier'});
        return
    end
    entrees = dir(racine);
    noms = {};
    versions = {};
    actives = [];
    identifiants = {};
    for k = 1:numel(entrees)
        if ~entrees(k).isdir || entrees(k).name(1) == '.'
            continue
        end
        nom = entrees(k).name;
        contenu = fullfile(racine, nom, 'Contents.m');
        titre = nom;
        if isfile(contenu)
            texte = fileread(contenu);
            lignes = strsplit(texte, sprintf('\n'));
            if ~isempty(lignes) && numel(lignes{1}) > 2
                titre = strtrim(lignes{1}(2:end));
            end
        end
        noms{end + 1} = titre;                                     %#ok<AGROW>
        versions{end + 1} = version();                             %#ok<AGROW>
        actives(end + 1) = true;                                   %#ok<AGROW>
        identifiants{end + 1} = nom;                               %#ok<AGROW>
    end
    t = table(noms(:), versions(:), logical(actives(:)), identifiants(:), ...
              'VariableNames', {'Name', 'Version', 'Enabled', 'Identifier'});
end
