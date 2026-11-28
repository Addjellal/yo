function w = matlibre_porter(w)
%MATLIBRE_PORTER Racine d'un mot anglais par l'algorithme de Porter (1980).
%   R = MATLIBRE_PORTER(MOT) suit l'implémentation de référence de Martin
%   Porter (porter.c), avec ses deux écarts au papier : « bli » devient
%   « ble » à l'étape 2 (au lieu de « abli » en « able »), et « logi »
%   devient « log ». Elle reproduit les 23 531 racines du jeu d'essai de
%   l'auteur (voc.txt, output.txt). Les mots de deux lettres ou moins ne
%   changent pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_porter('generalizations')      % 'gener'
%
%   Voir aussi NORMALIZEWORDS.
    w = lower(char(w));
    if numel(w) <= 2
        return
    end
    w = etape1ab(w);
    if numel(w) > 1
        w = etape1c(w);
        w = etape2(w);
        w = etape3(w);
        w = etape4(w);
        w = etape5(w);
    end
end

function c = consonne(w, i)
    switch w(i)
        case {'a', 'e', 'i', 'o', 'u'}
            c = false;
        case 'y'
            c = (i == 1) || ~consonne(w, i - 1);
        otherwise
            c = true;
    end
end

function n = mesure(w, j)
%MESURE Nombre de séquences voyelles-consonnes de w(1:j) : [C](VC)^m[V].
    n = 0;
    i = 1;
    while true
        if i > j, return; end
        if ~consonne(w, i), break; end
        i = i + 1;
    end
    i = i + 1;
    while true
        while true
            if i > j, return; end
            if consonne(w, i), break; end
            i = i + 1;
        end
        i = i + 1;
        n = n + 1;
        while true
            if i > j, return; end
            if ~consonne(w, i), break; end
            i = i + 1;
        end
        i = i + 1;
    end
end

function v = voyelle(w, j)
    v = false;
    for i = 1:j
        if ~consonne(w, i)
            v = true;
            return
        end
    end
end

function d = doubleConsonne(w, j)
    d = j >= 2 && w(j) == w(j - 1) && consonne(w, j);
end

function c = cvc(w, i)
    c = i >= 3 && consonne(w, i) && ~consonne(w, i - 1) && consonne(w, i - 2) ...
        && ~any(w(i) == 'wxy');
end

function [oui, j] = finit(w, s)
    oui = numel(w) >= numel(s) && strcmp(w(end - numel(s) + 1:end), s);
    j = numel(w) - numel(s);
end

function w = remplacer(w, j, s)
%REMPLACER Remplace le suffixe qui suit w(1:j) par S si la mesure de w(1:j) est positive.
    if mesure(w, j) > 0
        w = [w(1:j), s];
    end
end

function w = etape1ab(w)
    if w(end) == 's'
        if finit(w, 'sses')
            w = w(1:end - 2);
        elseif finit(w, 'ies')
            w = [w(1:end - 3), 'i'];
        elseif numel(w) >= 2 && w(end - 1) ~= 's'
            w = w(1:end - 1);
        end
    end
    [oui, j] = finit(w, 'eed');
    if oui
        if mesure(w, j) > 0
            w = w(1:end - 1);
        end
        return
    end
    [oui, j] = finit(w, 'ed');
    if ~oui
        [oui, j] = finit(w, 'ing');
    end
    if oui && voyelle(w, j)
        w = w(1:j);
        if finit(w, 'at') || finit(w, 'bl') || finit(w, 'iz')
            w = [w, 'e'];
        elseif doubleConsonne(w, numel(w))
            if ~any(w(end) == 'lsz')
                w = w(1:end - 1);
            end
        elseif mesure(w, numel(w)) == 1 && cvc(w, numel(w))
            w = [w, 'e'];
        end
    end
end

function w = etape1c(w)
    [oui, j] = finit(w, 'y');
    if oui && voyelle(w, j)
        w(end) = 'i';
    end
end

function w = etape2(w)
    if numel(w) < 2, return; end
    switch w(end - 1)
        case 'a', regles = {'ational', 'ate'; 'tional', 'tion'};
        case 'c', regles = {'enci', 'ence'; 'anci', 'ance'};
        case 'e', regles = {'izer', 'ize'};
        case 'l', regles = {'bli', 'ble'; 'alli', 'al'; 'entli', 'ent'; 'eli', 'e'; 'ousli', 'ous'};
        case 'o', regles = {'ization', 'ize'; 'ation', 'ate'; 'ator', 'ate'};
        case 's', regles = {'alism', 'al'; 'iveness', 'ive'; 'fulness', 'ful'; 'ousness', 'ous'};
        case 't', regles = {'aliti', 'al'; 'iviti', 'ive'; 'biliti', 'ble'};
        case 'g', regles = {'logi', 'log'};
        otherwise, return
    end
    w = appliquer(w, regles);
end

function w = etape3(w)
    switch w(end)
        case 'e', regles = {'icate', 'ic'; 'ative', ''; 'alize', 'al'};
        case 'i', regles = {'iciti', 'ic'};
        case 'l', regles = {'ical', 'ic'; 'ful', ''};
        case 's', regles = {'ness', ''};
        otherwise, return
    end
    w = appliquer(w, regles);
end

function w = appliquer(w, regles)
%APPLIQUER La première règle dont le suffixe convient s'applique, si la mesure le permet.
    for r = 1:size(regles, 1)
        [oui, j] = finit(w, regles{r, 1});
        if oui
            w = remplacer(w, j, regles{r, 2});
            return
        end
    end
end

function w = etape4(w)
    if numel(w) < 2, return; end
    switch w(end - 1)
        case 'a', suffixes = {'al'};
        case 'c', suffixes = {'ance', 'ence'};
        case 'e', suffixes = {'er'};
        case 'i', suffixes = {'ic'};
        case 'l', suffixes = {'able', 'ible'};
        case 'n', suffixes = {'ant', 'ement', 'ment', 'ent'};
        case 'o'
            [oui, j] = finit(w, 'ion');
            if ~(oui && j >= 1 && any(w(j) == 'st'))
                [oui, j] = finit(w, 'ou');
            end
            if oui && mesure(w, j) > 1
                w = w(1:j);
            end
            return
        case 's', suffixes = {'ism'};
        case 't', suffixes = {'ate', 'iti'};
        case 'u', suffixes = {'ous'};
        case 'v', suffixes = {'ive'};
        case 'z', suffixes = {'ize'};
        otherwise, return
    end
    for s = 1:numel(suffixes)
        [oui, j] = finit(w, suffixes{s});
        if oui
            if mesure(w, j) > 1
                w = w(1:j);
            end
            return
        end
    end
end

function w = etape5(w)
    n = numel(w);
    if w(n) == 'e'
        a = mesure(w, n);
        if a > 1 || (a == 1 && ~cvc(w, n - 1))
            w = w(1:n - 1);
        end
    end
    n = numel(w);
    if w(n) == 'l' && doubleConsonne(w, n) && mesure(w, n) > 1
        w = w(1:n - 1);
    end
end
