function fis = setfis(fis, varargin)
%SETFIS Écriture d'un champ d'un système d'inférence floue.
%   FIS = SETFIS(FIS,CHAMP,VALEUR) écrit un champ du système : 'name',
%   'type', 'andmethod', 'ormethod', 'impmethod', 'aggmethod',
%   'defuzzmethod'.
%   FIS = SETFIS(FIS,'input',I,CHAMP,VALEUR) écrit 'name' ou 'range'.
%   FIS = SETFIS(FIS,'input',I,'mf',J,CHAMP,VALEUR) écrit 'name', 'type'
%   ou 'params'.
%
%   Exemple :
%      fis = setfis(fis, 'defuzzmethod', 'bisector');
%      fis = setfis(fis, 'input', 1, 'mf', 2, 'params', [1 4 7]);
%
%   Voir aussi GETFIS, NEWFIS.
    champ = lower(char(varargin{1}));
    if any(strcmp(champ, {'input', 'in', 'output', 'out'}))
        entree = estEntree(champ);
        variables = variablesDe(fis, entree);
        indice = varargin{2};
        if indice < 1 || indice > numel(variables)
            error('fuzzy:setfis:BadVariable', 'Variable %d inexistante.', indice);
        end
        v = variables{indice};
        sousChamp = lower(char(varargin{3}));
        if strcmp(sousChamp, 'mf')
            indiceMf = varargin{4};
            if indiceMf < 1 || indiceMf > numel(v.mf)
                error('fuzzy:setfis:BadMf', 'Fonction %d inexistante.', indiceMf);
            end
            v.mf{indiceMf} = ecrireMf(v.mf{indiceMf}, varargin{5}, varargin{6});
        else
            v = ecrireVariable(v, sousChamp, varargin{4});
        end
        variables{indice} = v;
        fis = poserVariables(fis, entree, variables);
        return
    end
    fis = ecrireSysteme(fis, champ, varargin{2});
end

function fis = ecrireSysteme(fis, champ, valeur)
    switch champ
        case 'name',         fis.nom = char(valeur);
        case 'type',         fis.type = lower(char(valeur));
        case 'andmethod',    fis.et = lower(char(valeur));
        case 'ormethod',     fis.ou = lower(char(valeur));
        case 'impmethod',    fis.implication = lower(char(valeur));
        case 'aggmethod',    fis.agregation = lower(char(valeur));
        case 'defuzzmethod', fis.defuzzification = lower(char(valeur));
        case 'rulelist',     fis.regles = valeur;
        otherwise
            error('fuzzy:setfis:BadField', 'Champ inconnu : %s.', champ);
    end
end

function v = ecrireVariable(v, champ, valeur)
    switch champ
        case 'name',  v.nom = char(valeur);
        case 'range', v.intervalle = double(valeur);
        otherwise
            error('fuzzy:setfis:BadField', 'Champ inconnu : %s.', champ);
    end
end

function mf = ecrireMf(mf, champ, valeur)
    switch lower(char(champ))
        case 'name',   mf.nom = char(valeur);
        case 'type',   mf.type = lower(char(valeur));
        case 'params', mf.parametres = double(valeur);
        otherwise
            error('fuzzy:setfis:BadField', 'Champ inconnu : %s.', char(champ));
    end
end
