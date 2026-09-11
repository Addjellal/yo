function options = matlibre_lire_options(arguments, defauts)
%MATLIBRE_LIRE_OPTIONS Lit une suite de couples nom-valeur.
%   Les valeurs par défaut viennent d'une structure ; chaque couple
%   présent dans les arguments remplace la sienne. Un nom inconnu est
%   refusé plutôt qu'ignoré : une option mal orthographiée qui ne fait
%   rien est plus coûteuse qu'une erreur.
%
%   La comparaison des noms ignore la casse, comme dans MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = matlibre_lire_options({'Seuil', 3}, struct('Seuil', 1));
%      o.Seuil                         % 3
%
%   Voir aussi INPUTPARSER, VARARGIN.
    options = defauts;
    noms = fieldnames(defauts);
    if mod(numel(arguments), 2) ~= 0
        error('MATLAB:options:couples', ...
              'Les options vont par couples nom-valeur.');
    end
    for k = 1:2:numel(arguments)
        nom = char(arguments{k});
        correspond = find(strcmpi(noms, nom), 1);
        if isempty(correspond)
            error('MATLAB:options:inconnue', 'Option inconnue : %s.', nom);
        end
        options.(noms{correspond}) = arguments{k + 1};
    end
end
