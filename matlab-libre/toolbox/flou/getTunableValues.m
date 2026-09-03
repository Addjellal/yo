function valeurs = getTunableValues(fis, reglages)
%GETTUNABLEVALUES Valeurs courantes des paramètres réglables.
%   V = GETTUNABLEVALUES(FIS,S) rend, dans un vecteur, les paramètres que
%   décrivent les réglages S — ceux que rend GETTUNABLESETTINGS —, mis
%   bout à bout dans leur ordre.
%
%   C'est ce vecteur qu'un algorithme d'optimisation manipule, et que
%   SETTUNABLEVALUES repose dans le système.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
%      s = getTunableSettings(fis);
%      numel(getTunableValues(fis, s))   % 6 : deux triangles
%
%   Voir aussi GETTUNABLESETTINGS, SETTUNABLEVALUES, TUNEFIS.
    valeurs = [];
    for k = 1:numel(reglages)
        p = parametresCourants(fis, reglages(k));
        valeurs = [valeurs, p(:)'];   %#ok<AGROW>
    end
end

function p = parametresCourants(fis, reglage)
    [entree, indice] = trouverVariable(fis, reglage.Variable);
    variables = variablesDe(fis, entree);
    liste = variables{indice}.mf;
    for m = 1:numel(liste)
        if strcmp(liste{m}.nom, reglage.MembershipFunction)
            p = liste{m}.parametres;
            return
        end
    end
    error('fuzzy:getTunableValues:Absente', ...
          'La modalité ''%s'' n''est plus dans le système.', ...
          reglage.MembershipFunction);
end
