classdef inputParser < handle
%INPUTPARSER Contrôle des arguments d'une fonction.
%   P = INPUTPARSER fabrique un analyseur. On lui déclare les arguments
%   attendus, puis on lui donne ceux reçus ; il les range dans P.Results
%   et refuse ce qui ne convient pas.
%
%   Déclarations :
%      addRequired(P,NOM,VALIDATEUR)        argument obligatoire
%      addOptional(P,NOM,DEFAUT,VALIDATEUR) argument facultatif, par rang
%      addParameter(P,NOM,DEFAUT,VALIDATEUR) paire nom-valeur
%      addSwitch(P,NOM)                     drapeau, vrai s'il est là
%
%   Analyse :
%      parse(P,ARGS{:})
%      P.Results        structure des valeurs retenues
%      P.UsingDefaults  noms restés à leur valeur par défaut
%      P.Unmatched      paires non déclarées, si KeepUnmatched est vrai
%
%   Un validateur est une fonction qui rend faux ou lève une erreur quand
%   la valeur ne convient pas — @isnumeric, @(x) x > 0.
%
%   Exemple :
%      p = inputParser;
%      addRequired(p, 'x', @isnumeric);
%      addParameter(p, 'Ordre', 2, @(v) v > 0);
%      parse(p, 3, 'Ordre', 5);
%      p.Results.Ordre        % 5
%
%   Voir aussi VALIDATEATTRIBUTES, NARGINCHK, VARARGIN, PARSE.
    properties
        CaseSensitive = false;
        KeepUnmatched = false;
        PartialMatching = true;
        StructExpand = true;
        FunctionName = '';
    end
    properties (SetAccess = private)
        Results = struct();
        Unmatched = struct();
        UsingDefaults = {};
        Parameters = {};
    end
    properties (Access = private)
        Obligatoires = {};
        Facultatifs = {};
        Paires = {};
        Drapeaux = {};
    end
    methods
        function p = inputParser()
        end

        function addRequired(p, nom, validateur)
            if nargin < 3, validateur = []; end
            p.Obligatoires{end+1} = {char(nom), validateur};
            p.Parameters{end+1} = char(nom);
        end

        function addOptional(p, nom, defaut, validateur)
            if nargin < 4, validateur = []; end
            p.Facultatifs{end+1} = {char(nom), defaut, validateur};
            p.Parameters{end+1} = char(nom);
        end

        function addParameter(p, nom, defaut, validateur)
            if nargin < 4, validateur = []; end
            p.Paires{end+1} = {char(nom), defaut, validateur};
            p.Parameters{end+1} = char(nom);
        end

        function addParamValue(p, nom, defaut, validateur)
            % Nom d'avant R2013b, gardé parce que du code s'en sert encore.
            if nargin < 4, validateur = []; end
            addParameter(p, nom, defaut, validateur);
        end

        function addSwitch(p, nom)
            p.Drapeaux{end+1} = char(nom);
            p.Parameters{end+1} = char(nom);
        end

        function parse(p, varargin)
            entrees = varargin;
            resultats = struct();
            defauts = {};
            k = 1;
            for j = 1:numel(p.Obligatoires)
                nom = p.Obligatoires{j}{1};
                if k > numel(entrees)
                    error('MATLAB:InputParser:notEnoughInputs', ...
                          '%sIl manque l''argument « %s ».', p.prefixe(), nom);
                end
                p.valider(nom, entrees{k}, p.Obligatoires{j}{2});
                resultats.(nom) = entrees{k};
                k = k + 1;
            end
            for j = 1:numel(p.Facultatifs)
                nom = p.Facultatifs{j}{1};
                if k <= numel(entrees) && ~p.estNomDeclare(entrees{k})
                    p.valider(nom, entrees{k}, p.Facultatifs{j}{3});
                    resultats.(nom) = entrees{k};
                    k = k + 1;
                else
                    resultats.(nom) = p.Facultatifs{j}{2};
                    defauts{end+1} = nom;   %#ok<AGROW>
                end
            end
            for j = 1:numel(p.Paires)
                resultats.(p.Paires{j}{1}) = p.Paires{j}{2};
            end
            for j = 1:numel(p.Drapeaux)
                resultats.(p.Drapeaux{j}) = false;
            end
            donnes = {};
            nonReconnus = struct();
            while k <= numel(entrees)
                courant = entrees{k};
                if isstruct(courant) && p.StructExpand
                    champs = fieldnames(courant);
                    for c = 1:numel(champs)
                        nom = p.reconnaitre(champs{c});
                        if isempty(nom)
                            nonReconnus.(champs{c}) = courant.(champs{c});
                        else
                            resultats.(nom) = courant.(champs{c});
                            donnes{end+1} = nom;   %#ok<AGROW>
                        end
                    end
                    k = k + 1;
                    continue;
                end
                if ~(ischar(courant) || isstring(courant))
                    error('MATLAB:InputParser:paramMustBeChar', ...
                          '%sUn nom de paramètre était attendu.', p.prefixe());
                end
                nom = p.reconnaitre(char(courant));
                if isempty(nom)
                    if ~p.KeepUnmatched
                        error('MATLAB:InputParser:UnmatchedParameter', ...
                              '%sParamètre inconnu : « %s ».', p.prefixe(), char(courant));
                    end
                    if k + 1 <= numel(entrees)
                        nonReconnus.(genvarname(char(courant))) = entrees{k+1};
                        k = k + 2;
                    else
                        nonReconnus.(genvarname(char(courant))) = [];
                        k = k + 1;
                    end
                    continue;
                end
                if any(strcmp(nom, p.Drapeaux))
                    resultats.(nom) = true;
                    donnes{end+1} = nom;   %#ok<AGROW>
                    k = k + 1;
                    continue;
                end
                if k + 1 > numel(entrees)
                    error('MATLAB:InputParser:missingValue', ...
                          '%sLe paramètre « %s » attend une valeur.', p.prefixe(), nom);
                end
                p.valider(nom, entrees{k+1}, p.validateurDe(nom));
                resultats.(nom) = entrees{k+1};
                donnes{end+1} = nom;   %#ok<AGROW>
                k = k + 2;
            end
            restants = {};
            noms = fieldnames(resultats);
            for j = 1:numel(noms)
                if ~any(strcmp(noms{j}, donnes)) && ...
                        (any(strcmp(noms{j}, defauts)) || p.estParDefaut(noms{j}))
                    restants{end+1} = noms{j};   %#ok<AGROW>
                end
            end
            p.Results = resultats;
            p.Unmatched = nonReconnus;
            p.UsingDefaults = restants;
        end
    end

    methods (Access = private)
        function t = prefixe(p)
            if isempty(p.FunctionName)
                t = '';
            else
                t = [p.FunctionName ' : '];
            end
        end

        function tf = estParDefaut(p, nom)
            tf = false;
            for j = 1:numel(p.Paires)
                if strcmp(p.Paires{j}{1}, nom)
                    tf = true;
                    return;
                end
            end
            for j = 1:numel(p.Drapeaux)
                if strcmp(p.Drapeaux{j}, nom)
                    tf = true;
                    return;
                end
            end
        end

        function v = validateurDe(p, nom)
            v = [];
            for j = 1:numel(p.Paires)
                if strcmp(p.Paires{j}{1}, nom)
                    v = p.Paires{j}{3};
                    return;
                end
            end
        end

        function tf = estNomDeclare(p, valeur)
            tf = (ischar(valeur) || isstring(valeur)) && ...
                 ~isempty(p.reconnaitre(char(valeur)));
        end

        function nom = reconnaitre(p, candidat)
            % Le nom déclaré qui correspond. MATLAB accepte un préfixe non
            % ambigu quand PartialMatching est vrai, ce qui est son
            % réglage par défaut.
            nom = '';
            declares = [cellfun(@(c) c{1}, p.Paires, 'UniformOutput', false), p.Drapeaux];
            for j = 1:numel(declares)
                if p.CaseSensitive
                    egal = strcmp(declares{j}, candidat);
                else
                    egal = strcmpi(declares{j}, candidat);
                end
                if egal
                    nom = declares{j};
                    return;
                end
            end
            if ~p.PartialMatching
                return;
            end
            trouves = {};
            for j = 1:numel(declares)
                n = numel(candidat);
                if numel(declares{j}) >= n
                    if p.CaseSensitive
                        egal = strcmp(declares{j}(1:n), candidat);
                    else
                        egal = strcmpi(declares{j}(1:n), candidat);
                    end
                    if egal
                        trouves{end+1} = declares{j};   %#ok<AGROW>
                    end
                end
            end
            if numel(trouves) == 1
                nom = trouves{1};
            end
        end

        function valider(p, nom, valeur, validateur)
            if isempty(validateur)
                return;
            end
            try
                r = validateur(valeur);
            catch e
                error('MATLAB:InputParser:ArgumentFailedValidation', ...
                      '%s« %s » n''est pas accepté : %s', p.prefixe(), nom, e.message);
            end
            if islogical(r) && ~all(r(:))
                error('MATLAB:InputParser:ArgumentFailedValidation', ...
                      '%s« %s » n''est pas accepté.', p.prefixe(), nom);
            end
        end
    end
end
