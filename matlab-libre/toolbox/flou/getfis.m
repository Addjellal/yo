function valeur = getfis(fis, varargin)
%GETFIS Lecture d'un champ d'un système d'inférence floue.
%   GETFIS(FIS) affiche le résumé du système.
%   GETFIS(FIS,'name'|'type'|'numinputs'|'numoutputs'|'numrules') rend le
%   champ demandé, ainsi que les cinq opérateurs par leurs noms MATLAB :
%   'andmethod', 'ormethod', 'impmethod', 'aggmethod', 'defuzzmethod'.
%   GETFIS(FIS,'input',I,CHAMP) lit un champ d'une variable : 'name',
%   'range', 'nummfs'.
%   GETFIS(FIS,'input',I,'mf',J,CHAMP) lit 'name', 'type' ou 'params'.
%
%   Exemple :
%      getfis(fis, 'numinputs')
%      getfis(fis, 'input', 1, 'mf', 2, 'params')
%
%   Voir aussi SETFIS, SHOWRULE, NEWFIS.
    if isempty(varargin)
        afficherResume(fis);
        if nargout > 0, valeur = fis; end
        return
    end
    champ = lower(char(varargin{1}));
    if any(strcmp(champ, {'input', 'in', 'output', 'out'}))
        entree = estEntree(champ);
        variables = variablesDe(fis, entree);
        indice = varargin{2};
        if indice < 1 || indice > numel(variables)
            error('fuzzy:getfis:BadVariable', 'Variable %d inexistante.', indice);
        end
        v = variables{indice};
        if numel(varargin) < 3
            valeur = v;
            return
        end
        sousChamp = lower(char(varargin{3}));
        if strcmp(sousChamp, 'mf')
            indiceMf = varargin{4};
            if indiceMf < 1 || indiceMf > numel(v.mf)
                error('fuzzy:getfis:BadMf', 'Fonction %d inexistante.', indiceMf);
            end
            mf = v.mf{indiceMf};
            if numel(varargin) < 5
                valeur = mf;
                return
            end
            valeur = lireMf(mf, varargin{5});
            return
        end
        valeur = lireVariable(v, sousChamp);
        return
    end
    valeur = lireSysteme(fis, champ);
end

function valeur = lireSysteme(fis, champ)
    switch champ
        case 'name',         valeur = fis.nom;
        case 'type',         valeur = fis.type;
        case 'numinputs',    valeur = numel(fis.entrees);
        case 'numoutputs',   valeur = numel(fis.sorties);
        case 'numrules',     valeur = size(fis.regles, 1);
        case 'rulelist',     valeur = fis.regles;
        case 'andmethod',    valeur = fis.et;
        case 'ormethod',     valeur = fis.ou;
        case 'impmethod',    valeur = fis.implication;
        case 'aggmethod',    valeur = fis.agregation;
        case 'defuzzmethod', valeur = fis.defuzzification;
        otherwise
            error('fuzzy:getfis:BadField', 'Champ inconnu : %s.', champ);
    end
end

function valeur = lireVariable(v, champ)
    switch champ
        case 'name',   valeur = v.nom;
        case 'range',  valeur = v.intervalle;
        case 'nummfs', valeur = numel(v.mf);
        otherwise
            error('fuzzy:getfis:BadField', 'Champ inconnu : %s.', champ);
    end
end

function valeur = lireMf(mf, champ)
    switch lower(char(champ))
        case 'name',   valeur = mf.nom;
        case 'type',   valeur = mf.type;
        case 'params', valeur = mf.parametres;
        otherwise
            error('fuzzy:getfis:BadField', 'Champ inconnu : %s.', char(champ));
    end
end

function afficherResume(fis)
    fprintf('Nom                 : %s\n', fis.nom);
    fprintf('Type                : %s\n', fis.type);
    fprintf('Entrées             : %d\n', numel(fis.entrees));
    fprintf('Sorties             : %d\n', numel(fis.sorties));
    fprintf('Règles              : %d\n', size(fis.regles, 1));
    fprintf('Et / Ou             : %s / %s\n', fis.et, fis.ou);
    fprintf('Implication         : %s\n', fis.implication);
    fprintf('Agrégation          : %s\n', fis.agregation);
    fprintf('Défuzzification     : %s\n', fis.defuzzification);
end
