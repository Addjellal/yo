function fis = setTunableValues(fis, reglages, valeurs)
%SETTUNABLEVALUES Repose des paramètres réglés dans un système flou.
%   FIS = SETTUNABLEVALUES(FIS,S,V) écrit dans le système les valeurs V,
%   rangées comme les rend GETTUNABLEVALUES pour les réglages S.
%
%   Chaque valeur est ramenée entre les bornes du réglage, et les
%   paramètres d'une modalité sont remis en ordre croissant quand sa
%   forme l'exige — un triangle dont le sommet passerait derrière son
%   pied ne serait plus une fonction d'appartenance.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
%      s = getTunableSettings(fis);
%      v = getTunableValues(fis, s);
%      fis = setTunableValues(fis, s, v);   % rien n'a bougé
%
%   Voir aussi GETTUNABLESETTINGS, GETTUNABLEVALUES, TUNEFIS.
    valeurs = double(valeurs(:))';
    position = 1;
    for k = 1:numel(reglages)
        reglage = reglages(k);
        nombre = numel(reglage.Parameters);
        if position + nombre - 1 > numel(valeurs)
            error('fuzzy:setTunableValues:Nombre', ...
                  'Il manque des valeurs : %d attendues.', ...
                  position + nombre - 1);
        end
        p = valeurs(position:(position + nombre - 1));
        position = position + nombre;
        p = min(max(p, reglage.Minimum), reglage.Maximum);
        p = remettreEnOrdre(p, reglage.Type);
        fis = poserModalite(fis, reglage, p);
    end
end

function p = remettreEnOrdre(p, type)
%REMETTREENORDRE Trie les paramètres des formes qui l'exigent.
    switch lower(char(type))
        case {'trimf', 'trapmf', 'zmf', 'smf', 'pimf', 'linsmf', 'linzmf'}
            p = sort(p);
        otherwise
            % Une gaussienne porte [sigma centre] : l'ordre n'a pas de
            % sens, mais l'écart type doit rester positif.
            if any(strcmpi(type, {'gaussmf', 'gauss2mf', 'gbellmf'}))
                p(1) = max(abs(p(1)), eps);
            end
    end
end

function fis = poserModalite(fis, reglage, p)
    [entree, indice] = trouverVariable(fis, reglage.Variable);
    variables = variablesDe(fis, entree);
    liste = variables{indice}.mf;
    for m = 1:numel(liste)
        if strcmp(liste{m}.nom, reglage.MembershipFunction)
            liste{m}.parametres = p;
            variables{indice}.mf = liste;
            fis = poserVariables(fis, entree, variables);
            return
        end
    end
    error('fuzzy:setTunableValues:Absente', ...
          'La modalité ''%s'' n''est plus dans le système.', ...
          reglage.MembershipFunction);
end
