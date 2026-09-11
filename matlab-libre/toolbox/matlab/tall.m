classdef tall
%TALL Tableau dont le calcul est différé.
%   T = TALL(A) fait d'un tableau un tableau différé. T = TALL(MAGASIN)
%   part d'un magasin de données. Les opérations ordinaires — arithmétique,
%   comparaison, fonctions élémentaires, réductions, indexation — ne
%   calculent rien : elles décrivent ce qu'il faudra faire. GATHER
%   l'exécute et rend le résultat ordinaire.
%
%   C'est ce report qui fait l'intérêt du procédé : on écrit la chaîne
%   entière — filtrer, transformer, résumer — puis on la parcourt une
%   seule fois. Décrire ne coûte rien, et une chaîne qui ne finit pas par
%   GATHER ne coûte rien non plus.
%
%   Dans MATLAB, un tableau différé permet en outre de travailler sur des
%   données plus grandes que la mémoire. Ici le calcul est bien différé,
%   mais il s'effectue en mémoire au moment du GATHER : la forme du
%   programme est celle de MATLAB, l'économie de mémoire ne l'est pas.
%   TALL(MAGASIN) lit donc tout le magasin lorsqu'on rassemble.
%
%   SIZE, NUMEL, LENGTH et ISEMPTY répondent directement au lieu de
%   rendre un tableau différé comme le fait MATLAB : la taille est ici
%   connue sans détour, et imposer un GATHER pour l'obtenir n'apprendrait
%   rien à personne.
%
%   Exemple :
%      t = tall([1 2 3 4 5]);
%      grands = t(t > 2);
%      gather(sum(grands))             % 12
%      istall(grands)                  % 1 : rien n'a encore ete calcule
%
%   Voir aussi GATHER, ISTALL, DATASTORE, ARRAYDATASTORE, HEAD, TAIL.
    properties
        Calcul = @() []
    end

    methods
        function obj = tall(source, interne)
            if nargin == 0
                return
            end
            if nargin >= 2
                if ~isa(source, 'function_handle') || ~strcmp(char(interne), 'differe')
                    error('MATLAB:tall:InvalidInput', ...
                          'La forme à deux arguments est réservée aux calculs différés.');
                end
                obj.Calcul = source;
                return
            end
            if isa(source, 'tall')
                obj.Calcul = source.Calcul;
                return
            end
            if isa(source, 'function_handle')
                error('MATLAB:tall:InvalidInput', ...
                      'TALL prend un tableau ou un magasin de données, non une fonction.');
            end
            if isobject(source) && ismethod(source, 'readall')
                magasin = source;
                obj.Calcul = @() readall(magasin);
                return
            end
            valeur = source;
            obj.Calcul = @() valeur;
        end

        function r = plus(a, b),     r = matlibre_tall_differer(@plus, {a, b});     end
        function r = minus(a, b),    r = matlibre_tall_differer(@minus, {a, b});    end
        function r = uminus(a),      r = matlibre_tall_differer(@uminus, {a});      end
        function r = uplus(a),       r = matlibre_tall_differer(@uplus, {a});       end
        function r = times(a, b),    r = matlibre_tall_differer(@times, {a, b});    end
        function r = mtimes(a, b),   r = matlibre_tall_differer(@mtimes, {a, b});   end
        function r = rdivide(a, b),  r = matlibre_tall_differer(@rdivide, {a, b});  end
        function r = ldivide(a, b),  r = matlibre_tall_differer(@ldivide, {a, b});  end
        function r = mrdivide(a, b), r = matlibre_tall_differer(@mrdivide, {a, b}); end
        function r = power(a, b),    r = matlibre_tall_differer(@power, {a, b});    end
        function r = mpower(a, b),   r = matlibre_tall_differer(@mpower, {a, b});   end

        function r = eq(a, b), r = matlibre_tall_differer(@eq, {a, b}); end
        function r = ne(a, b), r = matlibre_tall_differer(@ne, {a, b}); end
        function r = lt(a, b), r = matlibre_tall_differer(@lt, {a, b}); end
        function r = le(a, b), r = matlibre_tall_differer(@le, {a, b}); end
        function r = gt(a, b), r = matlibre_tall_differer(@gt, {a, b}); end
        function r = ge(a, b), r = matlibre_tall_differer(@ge, {a, b}); end
        function r = and(a, b), r = matlibre_tall_differer(@and, {a, b}); end
        function r = or(a, b),  r = matlibre_tall_differer(@or, {a, b});  end
        function r = not(a),    r = matlibre_tall_differer(@not, {a});    end

        function r = abs(a),   r = matlibre_tall_differer(@abs, {a});   end
        function r = sqrt(a),  r = matlibre_tall_differer(@sqrt, {a});  end
        function r = exp(a),   r = matlibre_tall_differer(@exp, {a});   end
        function r = log(a),   r = matlibre_tall_differer(@log, {a});   end
        function r = log2(a),  r = matlibre_tall_differer(@log2, {a});  end
        function r = log10(a), r = matlibre_tall_differer(@log10, {a}); end
        function r = sin(a),   r = matlibre_tall_differer(@sin, {a});   end
        function r = cos(a),   r = matlibre_tall_differer(@cos, {a});   end
        function r = tan(a),   r = matlibre_tall_differer(@tan, {a});   end
        function r = round(a, varargin), r = matlibre_tall_differer(@round, [{a}, varargin]); end
        function r = floor(a), r = matlibre_tall_differer(@floor, {a}); end
        function r = ceil(a),  r = matlibre_tall_differer(@ceil, {a});  end
        function r = fix(a),   r = matlibre_tall_differer(@fix, {a});   end
        function r = sign(a),  r = matlibre_tall_differer(@sign, {a});  end

        function r = sum(t, varargin),     r = matlibre_tall_differer(@sum, [{t}, varargin]);     end
        function r = prod(t, varargin),    r = matlibre_tall_differer(@prod, [{t}, varargin]);    end
        function r = mean(t, varargin),    r = matlibre_tall_differer(@mean, [{t}, varargin]);    end
        function r = median(t, varargin),  r = matlibre_tall_differer(@median, [{t}, varargin]);  end
        function r = std(t, varargin),     r = matlibre_tall_differer(@std, [{t}, varargin]);     end
        function r = var(t, varargin),     r = matlibre_tall_differer(@var, [{t}, varargin]);     end
        function r = max(t, varargin),     r = matlibre_tall_differer(@max, [{t}, varargin]);     end
        function r = min(t, varargin),     r = matlibre_tall_differer(@min, [{t}, varargin]);     end
        function r = any(t, varargin),     r = matlibre_tall_differer(@any, [{t}, varargin]);     end
        function r = all(t, varargin),     r = matlibre_tall_differer(@all, [{t}, varargin]);     end
        function r = cumsum(t, varargin),  r = matlibre_tall_differer(@cumsum, [{t}, varargin]);  end
        function r = cumprod(t, varargin), r = matlibre_tall_differer(@cumprod, [{t}, varargin]); end
        function r = sort(t, varargin),    r = matlibre_tall_differer(@sort, [{t}, varargin]);    end
        function r = unique(t, varargin),  r = matlibre_tall_differer(@unique, [{t}, varargin]);  end
        function r = find(t, varargin),    r = matlibre_tall_differer(@find, [{t}, varargin]);    end
        function r = histcounts(t, varargin)
            r = matlibre_tall_differer(@histcounts, [{t}, varargin]);
        end
        function r = transpose(t),  r = matlibre_tall_differer(@transpose, {t});  end
        function r = ctranspose(t), r = matlibre_tall_differer(@ctranspose, {t}); end
        function r = reshape(t, varargin)
            r = matlibre_tall_differer(@reshape, [{t}, varargin]);
        end
        function r = head(t, varargin), r = matlibre_tall_differer(@head, [{t}, varargin]); end
        function r = tail(t, varargin), r = matlibre_tall_differer(@tail, [{t}, varargin]); end
        function r = cellfun(fonction, t, varargin)
            r = matlibre_tall_differer(@cellfun, [{fonction, t}, varargin]);
        end
        function r = arrayfun(fonction, t, varargin)
            r = matlibre_tall_differer(@arrayfun, [{fonction, t}, varargin]);
        end

        function d = size(t, varargin)
            d = size(matlibre_tall_valeur(t), varargin{:});
        end
        function n = numel(t),   n = numel(matlibre_tall_valeur(t));   end
        function n = length(t),  n = length(matlibre_tall_valeur(t));  end
        function r = isempty(t), r = isempty(matlibre_tall_valeur(t)); end
        function c = classUnderlying(t), c = class(matlibre_tall_valeur(t)); end

        function r = double(t)   %#ok<STOUT,MANU>
            error('MATLAB:tall:UseGather', ...
                  ['Un tableau différé ne se convertit pas directement : ' ...
                   'GATHER l''exécute et rend un tableau ordinaire.']);
        end

        function disp(t)   %#ok<MANU>
            fprintf('  tall : calcul différé ; GATHER l''exécute.\n');
        end

        function varargout = subsref(t, s)
            switch s(1).type
                case '()'
                    r = matlibre_tall_differer(@matlibre_tall_indexer, ...
                                               [{t}, s(1).subs]);
                    if numel(s) > 1
                        r = appliquerReste(r, s(2:end));
                    end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    if strcmp(nom, 'Calcul')
                        r = t.Calcul;
                    elseif numel(s) > 1 && strcmp(s(2).type, '()')
                        arguments = s(2).subs;
                        r = feval(nom, t, arguments{:});
                        s(2) = [];
                    else
                        r = feval(nom, t);
                    end
                    if numel(s) > 1
                        r = appliquerReste(r, s(2:end));
                    end
                    varargout{1} = r;
                otherwise
                    error('MATLAB:tall:badSubscript', ...
                          'Un tableau différé ne s''indexe pas avec des accolades.');
            end
        end
    end
end
