function [evenement, condition, actionCondition, actionTransition, garde] = ...
    matlibre_sf_etiquette(texte)
%MATLIBRE_SF_ETIQUETTE Découpe l'étiquette d'une transition de Stateflow.
%   [E,C,AC,AT,G] = MATLIBRE_SF_ETIQUETTE(TEXTE) lit la syntaxe de Stateflow
%   « evenement[condition]{action de condition}/action de transition »,
%   chaque partie étant facultative : 'go', '[n > 3]', 'go{k = 1;}',
%   '[n > 0]{k = [k n];}/fini = 1;'. Les crochets, accolades et
%   parenthèses s'apparient en comptant leur profondeur, chaînes de
%   caractères comprises : un crochet dans une action ne ferme pas la
%   condition. G est l'étiquette sans son action de transition.
%
%   Un texte qui n'a pas cette forme — 'n > 3', 'after(2, tick)' — est une
%   condition nue, l'extension de MatLibre. Une barre « / » ne sépare
%   l'action de transition que si ce qui la suit affecte une variable :
%   'x/2 > 1' reste une condition.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi SFTRANSITION, SFSTEP.
    evenement = '';
    condition = '';
    actionCondition = '';
    actionTransition = '';
    texte = strtrim(char(texte));
    garde = texte;
    if isempty(texte)
        return
    end
    n = numel(texte);
    k = 1;
    nom = regexp(texte, '^[A-Za-z_]\w*', 'match', 'once');
    if ~isempty(nom)
        suite = strtrim(texte(numel(nom) + 1:end));
        if ~(isempty(suite) || any(suite(1) == '[{') || (suite(1) == '/' && affecte(suite(2:end))))
            condition = texte;   % une condition nue : « n > 3 », « after(2, tick) »
            return
        end
        evenement = nom;
        k = numel(nom) + 1;
    end
    k = sauterBlancs(texte, k);
    if k <= n && texte(k) == '['
        fin = fermante(texte, k);
        condition = strtrim(texte(k + 1:fin - 1));
        k = sauterBlancs(texte, fin + 1);
    end
    if k <= n && texte(k) == '{'
        fin = fermante(texte, k);
        actionCondition = strtrim(texte(k + 1:fin - 1));
        k = sauterBlancs(texte, fin + 1);
    end
    if k <= n && texte(k) == '/'
        actionTransition = strtrim(texte(k + 1:end));
        garde = strtrim(texte(1:k - 1));
        k = n + 1;
    end
    if k <= n
        if isempty(evenement) && texte(1) ~= '[' && texte(1) ~= '{'
            % ni événement ni crochet en tête : une condition nue
            evenement = '';
            condition = texte;
            actionCondition = '';
            actionTransition = '';
            return
        end
        error('Stateflow:Etiquette', ...
              'Étiquette de transition illisible : « %s » (reste « %s »).', texte, texte(k:end));
    end
end

function k = sauterBlancs(texte, k)
    while k <= numel(texte) && isspace(texte(k))
        k = k + 1;
    end
end

% La position du délimiteur qui ferme celui ouvert en K, en sautant les
% chaînes et en comptant les paires imbriquées.
function fin = fermante(texte, k)
    ouvrantes = '[{(';
    fermantes = ']})';
    pile = texte(k);
    i = k + 1;
    while i <= numel(texte)
        c = texte(i);
        if c == '''' && debutChaine(texte, i)
            i = i + 1;
            while i <= numel(texte)
                if texte(i) == ''''
                    if i < numel(texte) && texte(i + 1) == ''''
                        i = i + 1;
                    else
                        break
                    end
                end
                i = i + 1;
            end
        elseif c == '"'
            i = i + 1;
            while i <= numel(texte) && texte(i) ~= '"'
                i = i + 1;
            end
        elseif any(c == ouvrantes)
            pile(end + 1) = c; %#ok<AGROW>
        elseif any(c == fermantes)
            attendu = fermantes(ouvrantes == pile(end));
            if c ~= attendu
                error('Stateflow:Etiquette', 'Délimiteurs mal appariés dans « %s ».', texte);
            end
            pile(end) = [];
            if isempty(pile)
                fin = i;
                return
            end
        end
        i = i + 1;
    end
    error('Stateflow:Etiquette', 'Délimiteur « %s » non fermé dans « %s ».', texte(k), texte);
end

% Une apostrophe ouvre une chaîne sauf après un nom, un nombre ou une
% fermante, où elle transpose.
function oui = debutChaine(texte, i)
    j = i - 1;
    while j >= 1 && texte(j) == ' '
        j = j - 1;
    end
    oui = j < 1 || ~(isstrprop(texte(j), 'alphanum') || any(texte(j) == ')]}._'''));
end

% Vrai si le texte affecte une variable : un « = » qui n'est pas « == »,
% « <= », « >= » ou « ~= ».
function oui = affecte(texte)
    oui = ~isempty(regexp(texte, '(^|[^=<>~])=($|[^=])', 'once'));
end
