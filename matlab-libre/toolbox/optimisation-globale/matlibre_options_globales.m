function options = matlibre_options_globales(defauts, nomFonction, varargin)
%MATLIBRE_OPTIONS_GLOBALES Rouage commun des trois fonctions d'options.
%   Le premier argument peut être une structure existante, qu'on complète
%   au lieu de repartir des défauts. Un nom inconnu est refusé : c'est ce
%   qui distingue une faute de frappe d'un réglage.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    options = defauts;
    debut = 1;
    if ~isempty(varargin) && isstruct(varargin{1})
        fournies = varargin{1};
        noms = fieldnames(fournies);
        for k = 1:numel(noms)
            options.(noms{k}) = fournies.(noms{k});
        end
        debut = 2;
    end
    arguments_ = varargin(debut:end);
    if mod(numel(arguments_), 2) ~= 0
        error('globaloptim:options:Couples', ...
              '%s attend des couples nom-valeur.', nomFonction);
    end
    champs = fieldnames(defauts);
    for k = 1:2:numel(arguments_)
        nom = char(arguments_{k});
        trouve = '';
        for j = 1:numel(champs)
            if strcmpi(champs{j}, nom)
                trouve = champs{j};
                break
            end
        end
        if isempty(trouve)
            error('globaloptim:options:Inconnue', ...
                  '%s ne connaît pas l''option ''%s''.', nomFonction, nom);
        end
        options.(trouve) = arguments_{k + 1};
    end
end
