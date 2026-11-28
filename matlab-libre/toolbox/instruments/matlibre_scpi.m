function matlibre_scpi(v, commande)
%MATLIBRE_SCPI Fait exécuter une commande SCPI par l'instrument simulé.
%   MATLIBRE_SCPI(V,COMMANDE) interprète COMMANDE comme le ferait un
%   multimètre doublé d'une alimentation : une requête (terminée par « ? »)
%   range sa réponse dans la file de sortie de V, une commande de réglage
%   change l'état, et une commande inconnue range l'erreur -113 dans la
%   file d'erreurs. Les en-têtes suivent SCPI-99 : forme courte (les
%   majuscules du mot-clé) ou longue, sans égard à la casse, nœuds entre
%   crochets facultatifs. Plusieurs commandes se séparent par « ; ».
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi VISADEV, WRITELINE.
    morceaux = strsplit(char(commande), ';');
    for k = 1:numel(morceaux)
        executer(v, strtrim(morceaux{k}));
    end
end

function executer(v, commande)
    if isempty(commande)
        return
    end
    [entete, parametre] = strtok(commande);
    parametre = strtrim(parametre);
    if reconnu(entete, '*IDN?')
        repondre(v, 'MatLibre,Instrument simule,0,1.0');
    elseif reconnu(entete, '*RST')
        v.etat = struct('tension', 0, 'courant', 0.1, 'sortie', false);
    elseif reconnu(entete, '*CLS')
        v.erreurs = {};
    elseif reconnu(entete, '*OPC?')
        repondre(v, '1');
    elseif reconnu(entete, '*TST?') || reconnu(entete, '*ESR?')
        repondre(v, '0');   % autotest réussi, registre d'événements vide
    elseif reconnu(entete, 'SYSTem:ERRor[:NEXT]?')
        if isempty(v.erreurs)
            repondre(v, '+0,"No error"');
        else
            repondre(v, v.erreurs{1});
            v.erreurs(1) = [];
        end
    elseif reconnu(entete, 'MEASure:VOLTage[:DC]?')
        repondre(v, sprintf('%+.6E', 5 + 0.01 * randn()));
    elseif reconnu(entete, 'MEASure:CURRent[:DC]?')
        repondre(v, sprintf('%+.6E', 0.25 + 0.001 * randn()));
    elseif reconnu(entete, '[SOURce:]VOLTage?')
        repondre(v, sprintf('%+.6E', v.etat.tension));
    elseif reconnu(entete, '[SOURce:]CURRent?')
        repondre(v, sprintf('%+.6E', v.etat.courant));
    elseif reconnu(entete, '[SOURce:]VOLTage') || reconnu(entete, '[SOURce:]CURRent')
        valeur = str2double(parametre);
        if isnan(valeur)
            erreur(v, '-109,"Missing parameter"');
        elseif reconnu(entete, '[SOURce:]VOLTage')
            v.etat.tension = valeur;
        else
            v.etat.courant = valeur;
        end
    elseif reconnu(entete, 'OUTPut[:STATe]')
        v.etat.sortie = any(strcmpi(parametre, {'ON', '1'}));
    elseif reconnu(entete, 'CONFigure:VOLTage[:DC]') || reconnu(entete, 'CONFigure:CURRent[:DC]') ...
            || reconnu(entete, 'TRIGger:SOURce')
        % réglages acceptés, sans effet sur la simulation
    else
        erreur(v, '-113,"Undefined header"');
    end
end

function repondre(v, texte)
    v.reponses{end + 1} = texte;
end

function erreur(v, texte)
    v.erreurs{end + 1} = texte;
end

% Vrai si l'en-tête répond au motif SCPI : « MEASure » vaut MEAS ou
% MEASURE, « [:DC] » est facultatif.
function oui = reconnu(entete, motif)
    persistent cache
    if isempty(cache)
        cache = containers.Map();
    end
    if ~isKey(cache, motif)
        expression = '^';
        k = 1;
        while k <= numel(motif)
            c = motif(k);
            if c == '['
                expression = [expression '(']; %#ok<AGROW>
            elseif c == ']'
                expression = [expression ')?']; %#ok<AGROW>
            elseif isletter(c)
                fin = k;
                while fin < numel(motif) && isletter(motif(fin + 1))
                    fin = fin + 1;
                end
                mot = motif(k:fin);
                court = mot(isstrprop(mot, 'upper'));
                if strcmp(court, mot)
                    expression = [expression mot]; %#ok<AGROW>
                else
                    expression = [expression '(' court '|' upper(mot) ')']; %#ok<AGROW>
                end
                k = fin;
            else
                expression = [expression regexptranslate('escape', c)]; %#ok<AGROW>
            end
            k = k + 1;
        end
        cache(motif) = [expression '$'];
    end
    oui = ~isempty(regexp(upper(entete), cache(motif), 'once'));
end
