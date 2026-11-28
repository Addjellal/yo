function k = matlibre_sl_variantes(action, varargin)
%MATLIBRE_SL_VARIANTES La variante active parmi plusieurs.
%   K = MATLIBRE_SL_VARIANTES('choisir',CONTROLES,MODE,ETIQUETTE,ZERO,
%   CHEMIN,NOMS) rend le rang de la variante active : CONTROLES{I} est la
%   condition de la variante I, dont le nom — pour les messages — est
%   NOMS{I}.
%
%   L = MATLIBRE_SL_VARIANTES('liste',V) rend les conditions d'un Variant
%   Source ou d'un Variant Sink en cellule de textes : V est une cellule,
%   ou le texte « {'V == 1', 'V == 2'} » qu'un fichier .slx porte.
%
%   En MODE 'expression', chaque condition s'évalue dans l'espace de
%   travail de base : une expression — 'Mode == 1' —, ou le nom d'un
%   SIMULINK.VARIANT, dont la condition s'évalue alors. Une variante dont
%   la condition vaut '(default)' est active quand aucune autre ne l'est ;
%   une condition vide n'est jamais vraie. En MODE 'label', la variante
%   active est celle dont la condition — une étiquette — vaut ETIQUETTE.
%
%   Aucune variante active : K vaut 0 si ZERO est vrai
%   (AllowZeroVariantControls), sinon une erreur
%   Simulink:Variants:NoActiveVariant nomme le bloc CHEMIN et les
%   conditions. Plusieurs : une erreur Simulink:Variants:
%   MultipleActiveVariants les nomme.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      assignin('base', 'Mode', 2);
%      matlibre_sl_variantes('choisir', {'Mode == 1', 'Mode == 2'}, ...
%                            'expression', '', false, 'm/v', {'un', 'deux'})  % 2
%
%   Voir aussi SIMULINK.VARIANT, ADD_BLOCK, SIM.
    switch action
        case 'choisir'
            k = choisir(varargin{:});
        case 'liste'
            k = liste(varargin{1});
        otherwise
            error('Simulink:Variants:Action', 'Action inconnue : %s.', char(action));
    end
end

function L = liste(v)
    if isstring(v)
        v = cellstr(v);
    end
    if ischar(v)
        texte = strtrim(v);
        if ~isempty(texte) && texte(1) == '{'
            L = regexp(texte, '''((?:[^'']|'''')*)''', 'tokens');
            L = cellfun(@(t) strrep(t{1}, '''''', ''''), L, 'UniformOutput', false);
        else
            L = strtrim(strsplit(texte, ','));
        end
        return
    end
    if iscell(v)
        L = cellfun(@texteDe, v(:).', 'UniformOutput', false);
        return
    end
    error('Simulink:Variants:InvalidVariantControls', ...
          'VariantControls must be a cell array of conditions: {''V == 1'', ''V == 2''}.');
end

function t = texteDe(x)
    if ischar(x) || isstring(x)
        t = char(x);
    elseif isnumeric(x) && isscalar(x)
        t = sprintf('Choix_%d', x);
    else
        error('Simulink:Variants:InvalidVariantControls', ...
              'A variant condition must be text: ''V == 1''.');
    end
end

function k = choisir(controles, mode, etiquette, zeroPermis, chemin, noms)
    n = numel(controles);
    actives = false(1, n);
    defaut = 0;
    if strcmpi(mode, 'label')
        if isempty(etiquette)
            error('Simulink:Variants:NoActiveLabel', ...
                  ['Variant block ''%s'' is in ''label'' mode without an active ' ...
                   'label: LabelModeActiveChoice must name one of its ' ...
                   'variant choices (%s).'], chemin, strjoin(controles, ', '));
        end
        actives = strcmp(controles, etiquette);
        if ~any(actives)
            error('Simulink:Variants:InvalidLabel', ...
                  ['Variant block ''%s'' activates label ''%s'', which none ' ...
                   'of its variant choices has: %s.'], chemin, etiquette, ...
                  strjoin(controles, ', '));
        end
    else
        for i = 1:n
            texte = strtrim(char(controles{i}));
            if strcmpi(texte, '(default)')
                if defaut > 0
                    error('Simulink:Variants:MultipleDefaults', ...
                          ['Variant block ''%s'' has two default variant choices: ' ...
                           '%s and %s.'], chemin, noms{defaut}, noms{i});
                end
                defaut = i;
                continue
            end
            if isempty(texte)
                continue
            end
            actives(i) = vraie(texte, chemin, noms{i});
        end
    end
    trouvees = find(actives);
    if numel(trouvees) > 1
        error('Simulink:Variants:MultipleActiveVariants', ...
              ['Variant block ''%s'' has several active variant choices at once: %s. ' ...
               'Only one condition may be true.'], chemin, ...
              strjoin(cellfun(@(nom, c) sprintf('%s (%s)', nom, c), noms(trouvees), ...
                              controles(trouvees), 'UniformOutput', false), ', '));
    end
    if numel(trouvees) == 1
        k = trouvees;
        return
    end
    if defaut > 0
        k = defaut;
        return
    end
    if zeroPermis
        k = 0;
        return
    end
    error('Simulink:Variants:NoActiveVariant', ...
          ['Variant block ''%s'' has no active variant choice: none of its ' ...
           'conditions is true (%s). Give it a ''(default)'' choice, or ' ...
           'set AllowZeroVariantControls to ''on''.'], chemin, strjoin(controles, ', '));
end

% Une condition : le nom d'un Simulink.Variant, dont on lit la
% condition, ou une expression évaluée dans l'espace de travail de base.
function oui = vraie(texte, chemin, nom)
    condition = texte;
    if isvarname(texte) && evalin('base', sprintf('exist(''%s'', ''var'')', texte)) == 1
        objet = evalin('base', texte);
        if isa(objet, 'Simulink.Variant')
            condition = objet.Condition;
        end
    end
    try
        valeur = matlibre_sl_expression(condition, nom, 'VariantControl');
    catch err
        error('Simulink:Variants:InvalidVariantControl', ...
              ['Condition ''%s'' of variant ''%s'' of block ''%s'' cannot be ' ...
               'evaluated: %s'], texte, nom, chemin, err.message);
    end
    if ~isscalar(valeur)
        error('Simulink:Variants:InvalidVariantControl', ...
              ['Condition ''%s'' of variant ''%s'' of block ''%s'' returns %d ' ...
               'values: it must return a single true or ' ...
               'false.'], texte, nom, chemin, numel(valeur));
    end
    oui = valeur ~= 0;
end
