function [modeles, styles, w, options] = matlibre_arguments_lti(entrees)
%MATLIBRE_ARGUMENTS_LTI Découpe la liste d'arguments d'un tracé LTI.
%   [MODELES,STYLES,W] = MATLIBRE_ARGUMENTS_LTI(ENTREES) sépare la liste
%   (SYS1,'STYLE1',SYS2,'STYLE2',...,W) que partagent BODE, BODEMAG,
%   SIGMA, STEP et les autres tracés de l'automatique.
%
%   ENTREES est le tableau de cellules des arguments reçus — VARARGIN.
%   MODELES rend les modèles dans l'ordre, STYLES la chaîne de style de
%   chacun — vide là où l'appelant n'en a pas donné —, et W le dernier
%   argument lorsqu'il vient après un modèle : la grille de pulsations
%   d'un tracé fréquentiel, l'horizon ou la grille de temps d'un tracé
%   temporel. Les bornes {WMIN,WMAX} sont acceptées et développées en
%   deux cents points logarithmiquement espacés, comme dans MATLAB.
%
%   [MODELES,STYLES,W,OPTIONS] rend en outre la structure d'options
%   passée en dernier — celle que rendent BODEOPTIONS ou
%   STEPDATAOPTIONS —, vide s'il n'y en a pas. Un modèle est un objet
%   (« tf », « ss », « zpk », « frd ») ; une structure nue en dernière
%   place est donc sans ambiguïté un jeu d'options.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Voir aussi BODE, BODEMAG, SIGMA, STEP, BODEOPTIONS, STEPDATAOPTIONS.
    modeles = {};
    styles = {};
    w = [];
    options = [];
    entrees = entrees(:).';
    % Les options viennent en dernier ; on les retire avant de lire le
    % reste, pour que la grille reste « le dernier argument numérique ».
    if numel(entrees) > 1 && isstruct(entrees{end})
        options = entrees{end};
        entrees(end) = [];
    end
    n = numel(entrees);
    for k = 1:n
        a = entrees{k};
        if ischar(a) || isstring(a)
            if isempty(modeles)
                error('Control:general:InvalidArgument', ...
                      'A line style must follow a model.');
            end
            styles{numel(modeles)} = char(a);
        elseif k == n && ~isempty(modeles) && iscell(a) && numel(a) == 2
            w = logspace(log10(double(a{1})), log10(double(a{2})), 200).';
        elseif k == n && ~isempty(modeles) && isnumeric(a)
            w = a;
        else
            modeles{end+1} = a;      %#ok<AGROW>
            styles{end+1} = '';      %#ok<AGROW>
        end
    end
end
