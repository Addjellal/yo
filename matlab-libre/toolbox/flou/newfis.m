function fis = newfis(nom, type, varargin)
%NEWFIS Crée un système d'inférence floue.
%   FIS = NEWFIS(NOM) crée un système de Mamdani vide.
%   FIS = NEWFIS(NOM,TYPE) où TYPE vaut 'mamdani' ou 'sugeno'.
%   FIS = NEWFIS(NOM,TYPE,ET,OU,IMPLICATION,AGREGATION,DEFUZZ) fixe les
%   cinq opérateurs. Leurs valeurs par défaut sont celles de MATLAB :
%   'min', 'max', 'min', 'max' et 'centroid' pour Mamdani, 'prod', 'probor',
%   'prod', 'sum' et 'wtaver' pour Sugeno.
%
%   La structure porte les champs nom, type, entrees, sorties, regles et
%   les cinq opérateurs. Les variables sont des tableaux de cellules ;
%   GETFIS et SETFIS donnent les accès nommés.
%
%   Exemple :
%      fis = newfis('exemple', 'sugeno');
%      fis.defuzzification   % 'wtaver'
%
%   Voir aussi MAMFIS, SUGFIS, ADDVAR, ADDMF, ADDRULE, EVALFIS.
    if nargin < 1 || isempty(nom), nom = 'fis'; end
    if nargin < 2 || isempty(type), type = 'mamdani'; end
    type = lower(char(type));
    if ~any(strcmp(type, {'mamdani', 'sugeno'}))
        error('fuzzy:newfis:BadType', 'Le type doit être ''mamdani'' ou ''sugeno''.');
    end
    if strcmp(type, 'sugeno')
        defauts = {'prod', 'probor', 'prod', 'sum', 'wtaver'};
    else
        defauts = {'min', 'max', 'min', 'max', 'centroid'};
    end
    for k = 1:numel(varargin)
        if ~isempty(varargin{k})
            defauts{k} = lower(char(varargin{k}));
        end
    end
    fis = struct();
    fis.nom = char(nom);
    fis.type = type;
    fis.entrees = {};
    fis.sorties = {};
    fis.regles = [];
    fis.et = defauts{1};
    fis.ou = defauts{2};
    fis.implication = defauts{3};
    fis.agregation = defauts{4};
    fis.defuzzification = defauts{5};
end
