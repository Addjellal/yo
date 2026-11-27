function machine = sftruthtable(machine, nom, entrees, sorties, conditions, decisions, actions)
%SFTRUTHTABLE Ajoute une table de vérité à la machine.
%   MACHINE = SFTRUTHTABLE(MACHINE,NOM,ENTREES,SORTIES,CONDITIONS,
%   DECISIONS,ACTIONS) donne à la machine une fonction décrite, comme
%   dans Stateflow, par une table de vérité :
%      ENTREES      les noms de ses arguments, {'x', 'y'}
%      SORTIES      les noms de ce qu'elle rend, {'z'} — zéro au départ
%      CONDITIONS   une condition par ligne, écrite en texte sur les
%                   entrées : {'x > 0', 'y == 1'}
%      DECISIONS    une matrice de caractères, une ligne par condition,
%                   une colonne par décision : 'T' la condition doit être
%                   vraie, 'F' fausse, '-' peu importe
%      ACTIONS      une action par décision, en texte, qui pose les
%                   sorties : {'z = 1;', 'z = 2;', 'z = 0;'}
%   Les décisions s'essaient de gauche à droite ; la première dont toutes
%   les conditions s'accordent fait son action. Une colonne toute de '-'
%   est la décision par défaut, et se met en dernier.
%
%   Les gardes et les actions de la machine l'appellent par son nom.
%
%   Exemple :
%      m = sfchart('signe');
%      m = sftruthtable(m, 'classe', {'x'}, {'k'}, {'x > 0', 'x < 0'}, ...
%                       ['TF-'; 'FT-'], {'k = 1;', 'k = -1;', 'k = 0;'});
%      m = sfstate(m, 'mesure', 'du: s = classe(u);');
%      [~, c] = sfrun(m, [3 -2]);
%      c.s                          % -1
%
%   Voir aussi SFFUNCTION, SFSTATE, SFTRANSITION.
    entrees = cellstr(entrees);
    sorties = cellstr(sorties);
    conditions = cellstr(conditions);
    actions = cellstr(actions);
    decisions = char(decisions);
    if size(decisions, 1) ~= numel(conditions)
        error('Stateflow:TableDeVeriteInvalide', ...
              ['Truth table ''%s'' has %d condition(s), and its decisions %d row(s): ' ...
               'one per condition is required.'], char(nom), numel(conditions), ...
              size(decisions, 1));
    end
    if numel(actions) ~= size(decisions, 2)
        error('Stateflow:TableDeVeriteInvalide', ...
              ['Truth table ''%s'' has %d decision(s), and %d action(s): one ' ...
               'per decision is required.'], char(nom), size(decisions, 2), numel(actions));
    end
    if ~all(ismember(decisions(:), 'TF-'))
        error('Stateflow:TableDeVeriteInvalide', ...
              ['The decisions of truth table ''%s'' are written with T (true), F ' ...
               '(false), and - (don''t care).'], char(nom));
    end
    table = struct('nom', char(nom), 'entrees', {entrees}, 'sorties', {sorties}, ...
                   'conditions', {conditions}, 'decisions', decisions, 'actions', {actions});
    machine = sffunction(machine, nom, @(varargin) matlibre_sf_verite(table, varargin{:}));
end
