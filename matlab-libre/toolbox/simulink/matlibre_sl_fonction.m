function varargout = matlibre_sl_fonction(action, varargin)
%MATLIBRE_SL_FONCTION Les blocs de code : Fcn, MATLAB Function, S-Function.
%   H = MATLIBRE_SL_FONCTION('expression',TEXTE,CHEMIN) rend la poignée
%   @(u) TEXTE d'un bloc Fcn ou Interpreted MATLAB Function. Elle est
%   créée dans l'espace de travail de base : les variables qu'elle nomme y
%   sont prises au moment de la compilation, comme dans Simulink.
%   L'écriture ancienne u[2] vaut u(2). Un nom de fonction seul — « sin »
%   — donne la fonction appliquée à u.
%
%   [NE,NS,ENTREES,SORTIES] = MATLIBRE_SL_FONCTION('signature',SCRIPT)
%   lit la ligne « function [y1,y2] = f(u,v) » du texte d'un bloc MATLAB
%   Function : ses arguments sont les entrées du bloc, ses sorties les
%   sorties.
%
%   H = MATLIBRE_SL_FONCTION('installer',SCRIPT,CHEMIN) écrit le texte
%   dans un fichier de fonction, sous un nom tiré du texte, dans un
%   dossier de la session mis sur le chemin, et rend la poignée de la
%   fonction. Ses variables persistantes sont remises à zéro.
%
%   [TAILLES,X0,TS] = MATLIBRE_SL_FONCTION('sfonction',F,PARAMETRES,
%   CHEMIN) interroge une S-fonction de niveau 1, [sys,x0,str,ts] =
%   f(t,x,u,flag,p1,p2,...), par le drapeau 0 : TAILLES porte le nombre
%   d'états continus et discrets, de sorties et d'entrées, la transmission
%   directe, et TS la période.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      h = matlibre_sl_fonction('expression', 'u(1)^2 + u[2]', 'm/f');
%      h([3; 1])                              % 10
%      [ne, ns] = matlibre_sl_fonction('signature', ...
%                 sprintf('function [a, b] = f(x, y, z)\na = x; b = y + z;'))
%
%   Voir aussi ADD_BLOCK, SIM.
    switch lower(char(action))
        case 'expression'
            varargout{1} = expression(varargin{:});
        case 'signature'
            [varargout{1:4}] = signature(varargin{1});
        case 'installer'
            varargout{1} = installer(varargin{:});
        case 'sfonction'
            [varargout{1:3}] = sfonction(varargin{:});
        otherwise
            error('Simulink:Fonction:Action', 'Action inconnue : %s.', char(action));
    end
end

function h = expression(texte, chemin)
    texte = strtrim(char(texte));
    if isempty(texte)
        error('Simulink:blocks:FcnExpressionEmpty', ...
              'Le bloc ''%s'' n''a pas d''expression.', chemin);
    end
    % u[i] est l'écriture de Simulink pour u(i).
    texte = regexprep(texte, '(^|[^A-Za-z0-9_])u\[([^\]]*)\]', '$1u($2)');
    if isvarname(texte) && ~strcmp(texte, 'u') && any(exist(texte) == [2 3 5 6]) %#ok<EXIST>
        texte = [texte '(u)'];
    end
    try
        h = evalin('base', ['@(u) ' texte]);
    catch err
        error('Simulink:blocks:FcnExpressionInvalid', ...
              'L''expression ''%s'' du bloc ''%s'' ne se lit pas : %s', texte, chemin, ...
              err.message);
    end
end

function [nEntrees, nSorties, entrees, sorties] = signature(script)
    lignes = regexp(char(script), '\r?\n', 'split');
    entete = '';
    for k = 1:numel(lignes)
        ligne = strtrim(regexprep(lignes{k}, '%.*$', ''));
        if ~isempty(regexp(ligne, '^function(\s|\[|$)', 'once'))
            entete = ligne;
            break
        end
    end
    if isempty(entete)
        error('Simulink:blocks:MATLABFunctionNoFunction', ...
              'Le texte d''un bloc MATLAB Function commence par une ligne « function ».');
    end
    jetons = regexp(entete, ['^function\s*(?:(\[[^\]]*\]|\w+)\s*=\s*)?' ...
                             '(\w+)\s*(?:\(([^)]*)\))?'], 'tokens', 'once');
    if isempty(jetons)
        error('Simulink:blocks:MATLABFunctionNoFunction', ...
              'La ligne ''%s'' n''est pas une declaration de fonction.', entete);
    end
    sorties = decouper(regexprep(jetons{1}, '[\[\]]', ''));
    entrees = decouper(jetons{3});
    nEntrees = numel(entrees);
    nSorties = numel(sorties);
end

function noms = decouper(texte)
    noms = regexp(strtrim(char(texte)), '[\s,]+', 'split');
    noms = noms(~cellfun(@isempty, noms));
end

% Le fichier prend un nom tiré du texte : deux blocs au même texte
% partagent leur fonction, et un texte changé en donne une neuve.
function h = installer(script, chemin)
    script = char(script);
    empreinte = 0;
    codes = double(script);
    for k = 1:numel(codes)
        empreinte = mod(empreinte * 131 + codes(k), 2147483647);
    end
    nom = sprintf('matlibre_mfb_%d', empreinte);
    dossier = fullfile(tempdir(), 'matlibre_blocs_fonction');
    if ~exist(dossier, 'dir')
        mkdir(dossier);
    end
    chemins = strsplit(path(), pathsep());
    if ~any(strcmp(chemins, dossier))
        addpath(dossier);
    end
    [~, ~] = signature(script);
    texte = renommer(script, nom);
    fichier = fullfile(dossier, [nom '.m']);
    f = fopen(fichier, 'w');
    if f < 0
        error('Simulink:blocks:MATLABFunctionWrite', ...
              'Le texte du bloc ''%s'' ne peut pas s''ecrire dans %s.', chemin, dossier);
    end
    fprintf(f, '%s\n', texte);
    fclose(f);
    rehash();
    clear(nom);
    h = str2func(nom);
end

% La fonction principale prend le nom du fichier : c'est lui qui l'appelle.
function texte = renommer(script, nom)
    lignes = regexp(char(script), '\r?\n', 'split');
    for k = 1:numel(lignes)
        ligne = strtrim(lignes{k});
        if isempty(regexp(ligne, '^function(\s|\[|$)', 'once'))
            continue
        end
        corps = ligne(9:end);
        egal = strfind(corps, '=');
        parenthese = strfind(corps, '(');
        avant = '';
        if ~isempty(egal) && (isempty(parenthese) || egal(1) < parenthese(1))
            avant = corps(1:egal(1));
            corps = corps(egal(1) + 1:end);
        end
        jeton = regexp(corps, '^\s*([A-Za-z]\w*)', 'tokens', 'once');
        if ~isempty(jeton)
            debut = strfind(corps, jeton{1});
            corps = [corps(1:debut(1) - 1) nom corps(debut(1) + numel(jeton{1}):end)];
        end
        lignes{k} = ['function' avant corps];
        break
    end
    texte = strjoin(lignes, sprintf('\n'));
end

function [tailles, x0, ts] = sfonction(nom, parametres, chemin)
    nom = char(nom);
    if ~(exist(nom) == 2 || exist(nom) == 6) %#ok<EXIST>
        error('Simulink:blocks:SFunctionNotFound', ...
              ['La S-fonction ''%s'' du bloc ''%s'' est introuvable : il faut un ' ...
               'fichier %s.m sur le chemin.'], nom, chemin, nom);
    end
    f = str2func(nom);
    try
        [sys, x0, ~, ts] = f(0, [], [], 0, parametres{:});
    catch err
        error('Simulink:blocks:SFunctionError', ...
              'La S-fonction ''%s'' du bloc ''%s'' echoue au drapeau 0 : %s', nom, ...
              chemin, err.message);
    end
    sys = double(sys(:)).';
    if numel(sys) < 6
        error('Simulink:blocks:SFunctionSizes', ...
              ['Au drapeau 0, la S-fonction ''%s'' doit rendre au moins six tailles : ' ...
               'etats continus, etats discrets, sorties, entrees, 0, transmission ' ...
               'directe.'], nom);
    end
    tailles = sys;
    x0 = double(x0(:));
    if numel(x0) ~= sys(1) + sys(2)
        error('Simulink:blocks:SFunctionInitialStates', ...
              ['La S-fonction ''%s'' annonce %d etat(s) mais rend %d condition(s) ' ...
               'initiale(s).'], nom, sys(1) + sys(2), numel(x0));
    end
    if isempty(ts)
        ts = [-1 0];
    end
    ts = double(ts);
end
