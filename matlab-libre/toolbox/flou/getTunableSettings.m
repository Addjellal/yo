function [entrees, sorties, regles] = getTunableSettings(fis)
%GETTUNABLESETTINGS Paramètres réglables d'un système flou.
%   [IN,OUT,RULE] = GETTUNABLESETTINGS(FIS) énumère ce qu'un réglage peut
%   toucher : les paramètres des modalités d'entrée, ceux des modalités
%   de sortie, et les indices des règles.
%
%   Chaque réglage est une structure portant le nom de la variable, celui
%   de la modalité, son type, les valeurs courantes et les bornes que le
%   réglage ne doit pas franchir : l'intervalle de la variable élargi de
%   sa propre largeur de chaque côté, et au besoin étendu pour contenir
%   les paramètres actuels. Une modalité d'extrémité a en effet un pied
%   hors de l'intervalle — c'est ainsi qu'elle sature —, et des bornes
%   plus serrées le rentreraient de force.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
%      s = getTunableSettings(fis);
%      numel(s)                       % 2 : une par modalité
%
%   Voir aussi GETTUNABLEVALUES, SETTUNABLEVALUES, TUNEFIS.
    entrees = reglagesDe(fis, true);
    sorties = reglagesDe(fis, false);
    if nargout > 2
        nombre = size(fis.regles, 1);
        regles = struct('Index', num2cell(1:nombre), 'Free', num2cell(true(1, nombre)));
        if nombre == 0
            regles = struct('Index', {}, 'Free', {});
        end
    end
end

function liste = reglagesDe(fis, entree)
    liste = struct('Variable', {}, 'MembershipFunction', {}, 'Type', {}, ...
                   'Parameters', {}, 'Minimum', {}, 'Maximum', {});
    variables = variablesDe(fis, entree);
    for k = 1:numel(variables)
        intervalle = variables{k}.intervalle;
        marge = intervalle(2) - intervalle(1);
        for m = 1:numel(variables{k}.mf)
            mf = variables{k}.mf{m};
            parametres = mf.parametres;
            liste(end + 1) = struct( ...
                'Variable', variables{k}.nom, ...
                'MembershipFunction', mf.nom, ...
                'Type', mf.type, ...
                'Parameters', parametres, ...
                'Minimum', min(intervalle(1) - marge, min(parametres)), ...
                'Maximum', max(intervalle(2) + marge, max(parametres)));   %#ok<AGROW>
        end
    end
end
