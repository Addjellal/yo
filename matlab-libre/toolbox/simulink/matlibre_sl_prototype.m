function [sorties, nom, entrees] = matlibre_sl_prototype(texte)
%MATLIBRE_SL_PROTOTYPE Les arguments d'un prototype de Simulink Function.
%   [SORTIES,NOM,ENTREES] = MATLIBRE_SL_PROTOTYPE(TEXTE) lit un prototype
%   comme l'écrit un Function Caller — « y = f(u) », « [s, d] = sd(a, b) »,
%   « f(u) », « y = f() », « y = A.f(u) » pour une fonction d'un
%   sous-système — et rend les noms des arguments de sortie, le nom de la
%   fonction (qualifié s'il l'est) et ceux des arguments d'entrée, en
%   cellules. Un texte qui n'est pas un prototype rend NOM vide.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [s, f, e] = matlibre_sl_prototype('[s, d] = sd(a, b)')
%      % s = {'s', 'd'}, f = 'sd', e = {'a', 'b'}
%
%   Voir aussi ADD_BLOCK.
    sorties = {};
    nom = '';
    entrees = {};
    if isstring(texte) && isscalar(texte)
        texte = char(texte);
    end
    if ~ischar(texte) || size(texte, 1) > 1
        return   % un prototype est un texte d'une ligne
    end
    t = strtrim(texte);
    egal = find(t == '=', 1);
    gauche = '';
    if ~isempty(egal)
        gauche = strtrim(t(1:egal - 1));
        t = strtrim(t(egal + 1:end));
    end
    jetons = regexp(t, '^([A-Za-z]\w*(\.[A-Za-z]\w*)?)\s*(\((.*)\))?\s*$', 'tokens', 'once');
    if isempty(jetons)
        return
    end
    gauche = regexprep(gauche, '^\[|\]$', '');
    sorties = noms(gauche);
    entrees = {};
    if numel(jetons) >= 4
        entrees = noms(jetons{4});
    end
    if any(cellfun(@isempty, regexp([sorties, entrees], '^[A-Za-z]\w*$', 'once')))
        sorties = {};
        entrees = {};
        return
    end
    nom = jetons{1};
end

function c = noms(texte)
    c = {};
    texte = strtrim(texte);
    if isempty(texte)
        return
    end
    c = strtrim(strsplit(texte, {',', ' '}));
    c = c(~cellfun(@isempty, c));
end
