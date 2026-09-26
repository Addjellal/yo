function [matlibre__c, matlibre__v] = matlibre_sf_evaluer(matlibre__texte, matlibre__c, u, ...
                                                          matlibre__garde)
%MATLIBRE_SF_EVALUER Évalue une garde ou une action écrite en texte.
%   [C,V] = MATLIBRE_SF_EVALUER(TEXTE,C,U,GARDE) évalue le texte d'une
%   garde (GARDE vrai : V est sa valeur) ou d'une action (V vide), comme
%   le langage d'action de Stateflow : les champs du contexte C y sont des
%   variables, u est l'entrée, et une variable que l'action pose ou change
%   devient un champ du contexte. La logique temporelle s'y écrit comme
%   dans Stateflow — after(3, tick), before(0.5, sec), at(2, tick),
%   every(4, tick) — et se lit sur le contexte que SFSTEP prépare.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      c = matlibre_sf_evaluer('x = x + u;', struct('x', 1), 2, false);
%      c.x                                          % 3
%
%   Voir aussi SFSTATE, SFTRANSITION, SFSTEP.
    matlibre__source = char(matlibre__texte);
    matlibre__texte = regexprep(matlibre__source, ...
        '(^|[^A-Za-z0-9_])(after|before|at|every)\s*\(\s*([^,()]+)\s*,\s*(tick|sec)\s*\)', ...
        '$1matlibre_sf_temporel(matlibre__c, ''$2'', $3, ''$4'')');
    matlibre__noms = {};
    if isstruct(matlibre__c)
        matlibre__noms = fieldnames(matlibre__c);
        for matlibre__k = 1:numel(matlibre__noms)
            eval([matlibre__noms{matlibre__k} ' = matlibre__c.(matlibre__noms{matlibre__k});']);
        end
    end
    matlibre__v = [];
    matlibre__avant = who;
    try
        if matlibre__garde
            matlibre__v = eval(matlibre__texte);
        else
            eval([matlibre__texte ';']);
        end
    catch matlibre__err
        if strncmp(matlibre__err.identifier, 'Stateflow:', 10)
            rethrow(matlibre__err);
        end
        error('Stateflow:TexteInvalide', ...
              'Le texte « %s » ne s''evalue pas : %s', matlibre__source, matlibre__err.message);
    end
    if matlibre__garde
        return
    end
    % les variables posées ou changées reviennent au contexte
    matlibre__apres = who;
    for matlibre__nom = matlibre__apres.'
        matlibre__n = matlibre__nom{1};
        if strncmp(matlibre__n, 'matlibre__', 10) || any(strcmp(matlibre__n, {'u', 'ans'}))
            continue
        end
        if any(strcmp(matlibre__noms, matlibre__n)) || ~any(strcmp(matlibre__avant, matlibre__n))
            matlibre__c.(matlibre__n) = eval(matlibre__n);
        end
    end
end
