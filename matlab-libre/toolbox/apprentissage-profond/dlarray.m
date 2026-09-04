classdef dlarray
%DLARRAY Tableau qui retient d'où il vient, pour être dérivé.
%   X = DLARRAY(A) enveloppe le tableau A. Les opérations sur X — somme,
%   produit, exponentielle, indexation — donnent d'autres DLARRAY et
%   s'inscrivent au passage sur une bande d'enregistrement. DLGRADIENT
%   parcourt ensuite cette bande à l'envers et rend les dérivées exactes,
%   sans différence finie et sans que l'utilisateur ait à écrire la
%   moindre formule de dérivée.
%
%   X = DLARRAY(A,FORMAT) étiquette les dimensions : 'S' pour spatiale,
%   'C' pour canal, 'B' pour observation, 'T' pour temps, 'U' pour non
%   spécifiée. Les fonctions de couches lisent ces étiquettes pour savoir
%   sur quelle dimension travailler.
%
%   La dérivation ne s'enregistre qu'à l'intérieur de DLFEVAL : hors de
%   là, un DLARRAY se comporte comme un tableau ordinaire, sans coût.
%
%   Méthodes utiles :
%      extractdata  - le tableau numérique porté
%      dims         - le format
%      stripdims    - le même tableau sans format
%      finddim      - la position d'une étiquette
%
%   Exemple :
%      function [v, g] = carre(x)
%          v = sum(x .^ 2);
%          g = dlgradient(v, x);
%      end
%      [v, g] = dlfeval(@carre, dlarray([1 2 3]));
%      extractdata(g)      % 2 4 6
%
%   Voir aussi DLFEVAL, DLGRADIENT, DLNETWORK, EXTRACTDATA.
    properties
        Valeur = []
        Format = ''
        Noeud = 0
    end
    methods
        function obj = dlarray(donnees, format)
            if nargin == 0
                return
            end
            if isa(donnees, 'dlarray')
                obj = donnees;
                if nargin > 1
                    obj.Format = char(format);
                end
                return
            end
            obj.Valeur = double(donnees);
            if nargin > 1
                obj.Format = char(format);
            end
            obj.Noeud = matlibre_bande('ajouter', 'feuille', [], {});
        end

        function v = extractdata(obj)
        %EXTRACTDATA Tableau numérique porté par un DLARRAY.
            v = obj.Valeur;
        end

        function f = dims(obj)
        %DIMS Étiquettes de dimension d'un DLARRAY.
            f = obj.Format;
        end

        function y = stripdims(obj)
        %STRIPDIMS Le même tableau, sans étiquettes de dimension.
            y = matlibre_dl_construire(obj.Valeur, '', obj.Noeud);
        end

        function d = finddim(obj, etiquette)
        %FINDDIM Positions d'une étiquette dans le format.
            d = find(obj.Format == upper(char(etiquette)));
        end

        function varargout = size(obj, varargin)
            if nargout <= 1
                varargout{1} = size(obj.Valeur, varargin{:});
            else
                [varargout{1:nargout}] = size(obj.Valeur, varargin{:});
            end
        end
        function n = numel(obj), n = numel(obj.Valeur); end
        function n = ndims(obj), n = ndims(obj.Valeur); end
        function n = length(obj), n = length(obj.Valeur); end
        function v = isempty(obj), v = isempty(obj.Valeur); end
        function v = double(obj), v = obj.Valeur; end
        function v = isreal(obj), v = isreal(obj.Valeur); end
        function v = isfloat(obj), v = true; end                  %#ok<MANU>
        function v = isnumeric(obj), v = true; end                %#ok<MANU>

        % ---- opérations à deux opérandes ----
        function y = plus(a, b)
            va = matlibre_dl_valeur(a);
            vb = matlibre_dl_valeur(b);
            y = matlibre_dl_binaire('plus', a, b, va + vb, {size(va), size(vb)});
        end
        function y = minus(a, b)
            va = matlibre_dl_valeur(a);
            vb = matlibre_dl_valeur(b);
            y = matlibre_dl_binaire('minus', a, b, va - vb, {size(va), size(vb)});
        end
        function y = times(a, b)
            va = matlibre_dl_valeur(a);
            vb = matlibre_dl_valeur(b);
            y = matlibre_dl_binaire('times', a, b, va .* vb, {va, vb});
        end
        function y = mtimes(a, b)
            va = matlibre_dl_valeur(a);
            vb = matlibre_dl_valeur(b);
            if isscalar(va) || isscalar(vb)
                y = times(a, b);
                return
            end
            y = matlibre_dl_binaire('mtimes', a, b, va * vb, {va, vb});
        end
        function y = rdivide(a, b)
            va = matlibre_dl_valeur(a);
            vb = matlibre_dl_valeur(b);
            y = matlibre_dl_binaire('rdivide', a, b, va ./ vb, {va, vb});
        end
        function y = ldivide(a, b), y = rdivide(b, a); end
        function y = mrdivide(a, b)
            if isscalar(matlibre_dl_valeur(b))
                y = rdivide(a, b);
            else
                error('nnet:dlarray:Division', ...
                      'La division matricielle n''est pas dérivée ; utilisez ./');
            end
        end
        function y = power(a, b)
            va = matlibre_dl_valeur(a);
            vb = matlibre_dl_valeur(b);
            y = matlibre_dl_binaire('power', a, b, va .^ vb, {va, vb});
        end
        function y = mpower(a, b)
            if isscalar(matlibre_dl_valeur(a)) && isscalar(matlibre_dl_valeur(b))
                y = power(a, b);
            else
                error('nnet:dlarray:Puissance', ...
                      'La puissance matricielle n''est pas dérivée ; utilisez .^');
            end
        end

        % ---- opérations à un opérande ----
        function y = uminus(a)
            y = matlibre_dl_unaire('uminus', a, -matlibre_dl_valeur(a), {});
        end
        function y = uplus(a), y = a; end
        function y = exp(a)
            v = exp(matlibre_dl_valeur(a));
            y = matlibre_dl_unaire('exp', a, v, {v});
        end
        function y = log(a)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('log', a, log(va), {va});
        end
        function y = sqrt(a)
            v = sqrt(matlibre_dl_valeur(a));
            y = matlibre_dl_unaire('sqrt', a, v, {v});
        end
        function y = tanh(a)
            v = tanh(matlibre_dl_valeur(a));
            y = matlibre_dl_unaire('tanh', a, v, {v});
        end
        function y = abs(a)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('abs', a, abs(va), {va});
        end
        function y = sin(a)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('sin', a, sin(va), {va});
        end
        function y = cos(a)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('cos', a, cos(va), {va});
        end
        function y = erf(a)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('erf', a, erf(va), {va});
        end
        function y = sum(a, varargin)
            va = matlibre_dl_valeur(a);
            dimension = matlibre_dl_dimension(va, varargin);
            if isequal(dimension, 0)
                y = matlibre_dl_unaire('sommeTotale', a, sum(va(:)), {size(va)});
            else
                y = matlibre_dl_unaire('somme', a, sum(va, dimension), ...
                                       {size(va), dimension});
            end
        end
        function y = mean(a, varargin)
            va = matlibre_dl_valeur(a);
            dimension = matlibre_dl_dimension(va, varargin);
            if isequal(dimension, 0)
                y = matlibre_dl_unaire('moyenneTotale', a, mean(va(:)), {size(va)});
            else
                y = matlibre_dl_unaire('moyenne', a, mean(va, dimension), ...
                                       {size(va), dimension});
            end
        end
        function y = reshape(a, varargin)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('remise', a, reshape(va, varargin{:}), {size(va)}, '');
        end
        function y = squeeze(a)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('remise', a, squeeze(va), {size(va)}, '');
        end
        function y = permute(a, ordre)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('permutation', a, permute(va, ordre), {ordre}, '');
        end
        function y = transpose(a)
            va = matlibre_dl_valeur(a);
            y = matlibre_dl_unaire('transposition', a, va.', {}, '');
        end
        function y = ctranspose(a), y = transpose(a); end
        function y = repmat(a, varargin)
            va = matlibre_dl_valeur(a);
            repetitions = matlibre_dl_repetitions(varargin);
            y = matlibre_dl_unaire('repetition', a, repmat(va, repetitions), ...
                                   {size(va), repetitions});
        end

        % ---- extremums ----
        function [y, indices] = max(a, b, varargin)
            if nargin >= 2 && ~isempty(b)
                [y, indices] = matlibre_dl_extremum('max', a, b, {});
            else
                [y, indices] = matlibre_dl_extremum('max', a, [], varargin);
            end
        end
        function [y, indices] = min(a, b, varargin)
            if nargin >= 2 && ~isempty(b)
                [y, indices] = matlibre_dl_extremum('min', a, b, {});
            else
                [y, indices] = matlibre_dl_extremum('min', a, [], varargin);
            end
        end

        % ---- concaténation ----
        function y = cat(dimension, varargin)
            y = matlibre_dl_concatener(dimension, varargin);
        end
        function y = horzcat(varargin)
            y = matlibre_dl_concatener(2, varargin);
        end
        function y = vertcat(varargin)
            y = matlibre_dl_concatener(1, varargin);
        end

        % ---- indexation ----
        function varargout = subsref(obj, s)
            if strcmp(s(1).type, '()')
                va = obj.Valeur;
                sortie = matlibre_dl_unaire('indexation', obj, va(s(1).subs{:}), ...
                                            {size(va), s(1).subs}, obj.Format);
                if numel(s) > 1
                    [varargout{1:nargout}] = subsref(sortie, s(2:end));
                else
                    varargout{1} = sortie;
                end
            else
                [varargout{1:nargout}] = builtin('subsref', obj, s);
            end
        end
        function obj = subsasgn(obj, s, valeur)
            if strcmp(s(1).type, '()') && numel(s) == 1
                ancienne = obj.Valeur;
                nouvelle = ancienne;
                nouvelle(s(1).subs{:}) = matlibre_dl_valeur(valeur);
                noeud = matlibre_bande('ajouter', 'affectation', ...
                                       [obj.Noeud, matlibre_dl_noeud(valeur)], ...
                                       {size(ancienne), s(1).subs, ...
                                        size(matlibre_dl_valeur(valeur))});
                obj = matlibre_dl_construire(nouvelle, obj.Format, noeud);
            else
                obj = builtin('subsasgn', obj, s, valeur);
            end
        end

        % ---- comparaisons : elles ne portent pas de dérivée ----
        function v = eq(a, b), v = matlibre_dl_valeur(a) == matlibre_dl_valeur(b); end
        function v = ne(a, b), v = matlibre_dl_valeur(a) ~= matlibre_dl_valeur(b); end
        function v = lt(a, b), v = matlibre_dl_valeur(a) < matlibre_dl_valeur(b); end
        function v = le(a, b), v = matlibre_dl_valeur(a) <= matlibre_dl_valeur(b); end
        function v = gt(a, b), v = matlibre_dl_valeur(a) > matlibre_dl_valeur(b); end
        function v = ge(a, b), v = matlibre_dl_valeur(a) >= matlibre_dl_valeur(b); end
        function v = sign(a), v = sign(matlibre_dl_valeur(a)); end
        function v = isnan(a), v = isnan(matlibre_dl_valeur(a)); end
        function v = isinf(a), v = isinf(matlibre_dl_valeur(a)); end

        function disp(obj)
            if isempty(obj.Format)
                fprintf('  dlarray %s\n', mat2str(size(obj.Valeur)));
            else
                fprintf('  dlarray %s, format %s\n', mat2str(size(obj.Valeur)), obj.Format);
            end
            disp(obj.Valeur);
        end
    end
end
