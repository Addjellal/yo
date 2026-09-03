classdef MemoizedFunction < handle
%MEMOIZEDFUNCTION Fonction qui retient ses résultats.
%   C'est l'objet que rend MEMOIZE. Il s'appelle comme la fonction
%   d'origine ; les arguments déjà vus ne sont pas recalculés.
%
%   Voir aussi MEMOIZE, CLEARCACHE, STATS.
    properties
        Enabled = true;
        CacheSize = 10;
    end
    properties (SetAccess = private)
        Function
    end
    properties (Access = private)
        Cles = {};
        Valeurs = {};
        NombreSorties = [];
        Appels = 0;
        Trouvailles = 0;
    end
    methods
        function mf = MemoizedFunction(f)
            mf.Function = f;
        end

        function varargout = subsref(mf, s)
            if ~strcmp(s(1).type, '()')
                % Les propriétés et les méthodes se lisent comme
                % d'habitude ; seul l'appel passe par le cache.
                [varargout{1:nargout}] = builtin('subsref', mf, s);
                return;
            end
            arguments = s(1).subs;
            n = max(nargout, 1);
            mf.Appels = mf.Appels + 1;
            if ~mf.Enabled
                [varargout{1:n}] = feval(mf.Function, arguments{:});
                return;
            end
            cle = MemoizedFunction.clef(arguments, n);
            position = find(strcmp(cle, mf.Cles), 1);
            if ~isempty(position)
                mf.Trouvailles = mf.Trouvailles + 1;
                garde = mf.Valeurs{position};
                for k = 1:n
                    varargout{k} = garde{k};
                end
                return;
            end
            sorties = cell(1, n);
            [sorties{1:n}] = feval(mf.Function, arguments{:});
            mf.Cles{end+1} = cle;
            mf.Valeurs{end+1} = sorties;
            if numel(mf.Cles) > mf.CacheSize
                % Le plus ancien s'en va : c'est la règle de MATLAB, et
                % elle suffit pour une fonction appelée en boucle.
                mf.Cles(1) = [];
                mf.Valeurs(1) = [];
            end
            for k = 1:n
                varargout{k} = sorties{k};
            end
        end

        function clearCache(mf)
            mf.Cles = {};
            mf.Valeurs = {};
        end

        function s = stats(mf)
            s = struct('Cache', struct('Inputs', {mf.Cles}, ...
                                       'Nargout', numel(mf.Cles)), ...
                       'MostHitCachedInput', [], ...
                       'CacheHitRatePercent', 100 * mf.Trouvailles / max(mf.Appels, 1), ...
                       'CacheOccupancyPercent', ...
                       100 * numel(mf.Cles) / max(mf.CacheSize, 1), ...
                       'TotalCalls', mf.Appels, ...
                       'CacheHits', mf.Trouvailles);
        end
    end
    methods (Static, Access = private)
        function c = clef(arguments, n)
            % Une clef textuelle : deux jeux d'arguments égaux la
            % partagent, deux jeux différents ne peuvent la partager,
            % puisque la classe et la forme y figurent.
            morceaux = cell(1, numel(arguments));
            for k = 1:numel(arguments)
                a = arguments{k};
                if ischar(a)
                    morceaux{k} = ['c:' a];
                elseif isnumeric(a) || islogical(a)
                    morceaux{k} = sprintf('%s%s:%s', class(a), ...
                                          mat2str(size(a)), mat2str(a(:)', 17));
                else
                    morceaux{k} = [class(a) ':' char(strjoin(cellstr(string(a(:))), ','))];
                end
            end
            c = sprintf('%d|%s', n, strjoin(morceaux, '|'));
        end
    end
end
