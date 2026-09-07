classdef dictionary
%DICTIONARY Association de clés à des valeurs.
%   D = DICTIONARY(CLES,VALEURS) construit un dictionnaire à partir de
%   deux tableaux de même longueur. D = DICTIONARY() en construit un vide.
%   D(CLE) lit la valeur associée ; D(CLE) = VALEUR l'écrit, en créant
%   l'entrée si elle n'existe pas.
%
%   Les clés peuvent être numériques ou textuelles, mais pas les deux à la
%   fois : le type est fixé à la première insertion, et une clé d'un autre
%   type est refusée. C'est ce qui distingue un dictionnaire d'une
%   structure, dont les champs sont forcément des noms valides.
%
%   Ce qu'on lui fait : KEYS, VALUES, LOOKUP, INSERT, REMOVE, ISKEY,
%   NUMENTRIES, ENTRIES, ISCONFIGURED.
%
%   Le dictionnaire a remplacé CONTAINERS.MAP en R2022b. Les différences
%   qui comptent : il se copie par valeur — modifier une copie ne touche
%   pas l'original, là où CONTAINERS.MAP est une poignée —, et il accepte
%   l'indexation par un tableau de clés, qui rend autant de valeurs.
%
%   Exemple :
%      d = dictionary(["a", "b"], [1 2]);
%      d("a")                          % 1
%      d("c") = 3;
%      numEntries(d)                   % 3
%      isKey(d, "b")                   % 1
%      keys(d)'                        % "a"  "b"  "c"
%
%   Voir aussi CONTAINERS.MAP, KEYS, VALUES, ISKEY, STRUCT.
    properties
        Cles = {}
        Valeurs = {}
        ClesTextuelles = []      % vide tant que rien n'est insere
    end
    methods
        function d = dictionary(cles, valeurs)
            if nargin == 0
                return
            end
            if nargin ~= 2
                error('MATLAB:dictionary:Arguments', ...
                      'DICTIONARY attend les clés et les valeurs, ou rien.');
            end
            [listeCles, textuelles] = matlibre_dict_cles(cles);
            listeValeurs = matlibre_dict_valeurs(valeurs);
            if numel(listeCles) ~= numel(listeValeurs)
                error('MATLAB:dictionary:SizeMismatch', ...
                      'Il faut autant de valeurs que de clés.');
            end
            d.ClesTextuelles = textuelles;
            for k = 1:numel(listeCles)
                d = poser(d, listeCles{k}, listeValeurs{k});
            end
        end

        function n = numEntries(d), n = numel(d.Cles); end
        function n = length(d), n = numel(d.Cles); end
        function tf = isConfigured(d), tf = ~isempty(d.ClesTextuelles); end

        function k = keys(d)
        %KEYS Les clés du dictionnaire, dans l'ordre d'insertion.
            if isempty(d.Cles)
                k = {};
            elseif d.ClesTextuelles
                k = string(d.Cles(:));
            else
                k = cell2mat(d.Cles(:));
            end
        end

        function v = values(d)
        %VALUES Les valeurs du dictionnaire, dans l'ordre des clés.
            if isempty(d.Valeurs)
                v = {};
                return
            end
            homogenes = all(cellfun(@(x) isnumeric(x) && isscalar(x), d.Valeurs));
            if homogenes
                v = cell2mat(d.Valeurs(:));
            else
                v = d.Valeurs(:);
            end
        end

        function tf = isKey(d, cle)
        %ISKEY Le dictionnaire connaît-il cette clé.
            liste = matlibre_dict_cles(cle);
            tf = false(numel(liste), 1);
            for k = 1:numel(liste)
                tf(k) = ~isempty(matlibre_dict_trouver(d, liste{k}));
            end
            if isscalar(tf), tf = tf(1); end
        end

        function v = lookup(d, cle, varargin)
        %LOOKUP Lit une valeur, avec un repli quand la clé manque.
        %   LOOKUP(D,CLE,'FallbackValue',V) rend V au lieu de lever.
            repli = [];
            aRepli = false;
            for k = 1:2:numel(varargin) - 1
                if strcmpi(char(varargin{k}), 'fallbackvalue')
                    repli = varargin{k + 1};
                    aRepli = true;
                end
            end
            liste = matlibre_dict_cles(cle);
            sorties = cell(numel(liste), 1);
            for k = 1:numel(liste)
                j = matlibre_dict_trouver(d, liste{k});
                if isempty(j)
                    if ~aRepli
                        error('MATLAB:dictionary:KeyNotFound', ...
                              'Clé absente du dictionnaire.');
                    end
                    sorties{k} = repli;
                else
                    sorties{k} = d.Valeurs{j};
                end
            end
            if all(cellfun(@(x) isnumeric(x) && isscalar(x), sorties))
                v = cell2mat(sorties);
                if isscalar(v), v = v(1); end
            elseif isscalar(sorties)
                v = sorties{1};
            else
                v = sorties;
            end
        end

        function d = insert(d, cle, valeur)
        %INSERT Ajoute ou remplace une entrée.
            liste = matlibre_dict_cles(cle);
            listeValeurs = matlibre_dict_valeurs(valeur);
            for k = 1:numel(liste)
                d = poser(d, liste{k}, listeValeurs{min(k, numel(listeValeurs))});
            end
        end

        function d = remove(d, cle)
        %REMOVE Retire une entrée.
            liste = matlibre_dict_cles(cle);
            for k = 1:numel(liste)
                j = matlibre_dict_trouver(d, liste{k});
                if isempty(j)
                    error('MATLAB:dictionary:KeyNotFound', ...
                          'Clé absente du dictionnaire.');
                end
                d.Cles(j) = [];
                d.Valeurs(j) = [];
            end
        end

        function t = entries(d)
        %ENTRIES Les couples clé-valeur, en structure.
            t = struct('Key', d.Cles(:), 'Value', d.Valeurs(:));
        end

        function varargout = subsref(d, s)
            switch s(1).type
                case '()'
                    r = lookup(d, s(1).subs{1});
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'Cles',           r = d.Cles;
                        case 'Valeurs',        r = d.Valeurs;
                        case 'ClesTextuelles', r = d.ClesTextuelles;
                        otherwise
                            if numel(s) > 1 && strcmp(s(2).type, '()')
                                a = s(2).subs;
                                r = feval(nom, d, a{:});
                                s(2) = [];
                            else
                                r = feval(nom, d);
                            end
                    end
                    if numel(s) > 1, r = appliquerReste(r, s(2:end)); end
                    varargout{1} = r;
                otherwise
                    error('MATLAB:dictionary:badSubscript', ...
                          'Un dictionnaire s''indexe par parenthèses.');
            end
        end

        function d = subsasgn(d, s, valeur)
            if strcmp(s(1).type, '()')
                d = insert(d, s(1).subs{1}, valeur);
            else
                error('MATLAB:dictionary:badSubscript', ...
                      'Un dictionnaire s''indexe par parenthèses.');
            end
        end

        function disp(d)
            fprintf('  dictionary : %d entrees\n', numEntries(d));
        end
    end
    methods (Access = private)
        function d = poser(d, cle, valeur)
            textuelle = ~isnumeric(cle);
            if isempty(d.ClesTextuelles)
                d.ClesTextuelles = textuelle;
            elseif d.ClesTextuelles ~= textuelle
                error('MATLAB:dictionary:KeyTypeMismatch', ...
                      ['Les clés d''un dictionnaire sont toutes du même ' ...
                       'type : le premier insertion le fixe.']);
            end
            j = matlibre_dict_trouver(d, cle);
            if isempty(j)
                d.Cles{end + 1} = cle;
                d.Valeurs{end + 1} = valeur;
            else
                d.Valeurs{j} = valeur;
            end
        end
    end
end
