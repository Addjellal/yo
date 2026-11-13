function [noms, valeurs] = matlibre_sdi_sources(source, args, premierNom)
%MATLIBRE_SDI_SOURCES Ce qu'on range dans un run, et sous quels noms.
%   [NOMS,VALEURS] = MATLIBRE_SDI_SOURCES(SOURCE,ARGS,NOM) lit les
%   arguments de SIMULINK.SDI.CREATERUN et de ADD : SOURCE 'vars' et des
%   variables (la première nommée NOM, les autres var2...), 'namevalue',
%   une cellule de noms et une cellule de valeurs, 'base' et une cellule
%   de noms de variables de l'espace de base, 'file' et un fichier MAT.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [n, v] = matlibre_sdi_sources('namevalue', {{'a'}, {timeseries(1)}}, '');
%      n{1}                               % 'a'
%
%   Voir aussi SIMULINK.SDI.CREATERUN.
    if ~(ischar(source) || (isstring(source) && isscalar(source)))
        error('SDI:sdi:InvalidSourceType', ...
              'La source d''un run se dit par ''vars'', ''namevalue'', ''base'' ou ''file''.');
    end
    switch lower(char(source))
        case 'vars'
            valeurs = args;
            noms = cell(1, numel(args));
            for k = 1:numel(args)
                noms{k} = sprintf('var%d', k);
            end
            if ~isempty(args) && ~isempty(premierNom)
                noms{1} = premierNom;
            end
        case 'namevalue'
            if numel(args) ~= 2 || ~iscellstr(args{1}) || ~iscell(args{2}) || ...
               numel(args{1}) ~= numel(args{2})
                error('SDI:sdi:InvalidSourceType', ...
                      ['''namevalue'' prend une cellule de noms et une cellule de valeurs, ' ...
                       'autant de l''une que de l''autre.']);
            end
            noms = args{1};
            valeurs = args{2};
        case 'base'
            if isempty(args)
                noms = evalin('base', 'who').';
            else
                noms = cellstr(args{1});
            end
            valeurs = cell(size(noms));
            for k = 1:numel(noms)
                if evalin('base', sprintf('exist(''%s'', ''var'')', noms{k})) ~= 1
                    error('SDI:sdi:VariableNotFound', ...
                          'L''espace de travail de base n''a pas de variable ''%s''.', noms{k});
                end
                valeurs{k} = evalin('base', noms{k});
            end
        case 'file'
            if isempty(args)
                error('SDI:sdi:InvalidSourceType', '''file'' prend le nom d''un fichier MAT.');
            end
            try
                contenu = load(char(args{1}));
            catch err
                error('SDI:sdi:FileNotFound', 'Le fichier ''%s'' ne se lit pas : %s', ...
                      char(args{1}), err.message);
            end
            noms = fieldnames(contenu).';
            valeurs = cellfun(@(n) contenu.(n), noms, 'UniformOutput', false);
        otherwise
            error('SDI:sdi:InvalidSourceType', ...
                  ['La source ''%s'' n''en est pas une : ''vars'', ''namevalue'', ''base'' ' ...
                   'ou ''file''.'], char(source));
    end
end
