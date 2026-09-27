classdef fi
%FI Un tableau de nombres à virgule fixe : ce que construit la fonction FI.
%   L'objet garde les entiers stockés, son type (embedded.numerictype) et
%   ses règles de calcul (embedded.fimath). Voir FI pour le construire et
%   s'en servir.
%
%   Voir aussi FI, NUMERICTYPE, FIMATH.
    properties
        Entiers = zeros(0, 0)
        Type
        Maths
        MathsLocale = false
    end
    methods
        function a = fi(Q, T, F, locale)
            if nargin >= 1
                a.Entiers = Q;
                a.Type = T;
                a.Maths = F;
                a.MathsLocale = locale;
            else
                a.Type = embedded.numerictype();
                a.Maths = embedded.fimath();
            end
        end

        % Ce que garde l'objet, pour les fonctions de la boîte à outils qui
        % calculent : hors des méthodes, A.Entiers passerait par SUBSREF.
        function s = internes(a)
            s = struct('Entiers', a.Entiers, 'Type', a.Type, 'Maths', a.Maths, ...
                       'MathsLocale', a.MathsLocale, 'EstFi', true);
        end

        % --- conversions -----------------------------------------------
        function v = double(a)
            v = a.Entiers * a.Type.Slope + a.Type.Bias;
        end
        function v = single(a)
            v = single(double(a));
        end
        function v = int8(a),   v = int8(double(a));   end
        function v = uint8(a),  v = uint8(double(a));  end
        function v = int16(a),  v = int16(double(a));  end
        function v = uint16(a), v = uint16(double(a)); end
        function v = int32(a),  v = int32(double(a));  end
        function v = uint32(a), v = uint32(double(a)); end
        function v = int64(a),  v = int64(double(a));  end
        function v = uint64(a), v = uint64(double(a)); end
        function v = logical(a)
            v = double(a) ~= 0;
        end
        function q = storedInteger(a)
            q = matlibre_fixe_stocke(a.Entiers, a.Type);
        end
        function q = storedIntegerToDouble(a)
            q = a.Entiers;
        end
        function t = bin(a)
            t = matlibre_fixe_chiffres(a.Entiers, a.Type, 2);
        end
        function t = oct(a)
            t = matlibre_fixe_chiffres(a.Entiers, a.Type, 8);
        end
        function t = hex(a)
            t = matlibre_fixe_chiffres(a.Entiers, a.Type, 16);
        end
        function t = dec(a)
            t = matlibre_fixe_chiffres(a.Entiers, a.Type, 10);
        end
        function t = num2str(a, varargin)
            t = num2str(double(a), varargin{:});
        end
        function T = numerictype(a)
            T = a.Type;
        end
        function F = fimath(a)
            F = a.Maths;
        end
        function oui = isfimathlocal(a)
            oui = a.MathsLocale;
        end
        function a = removefimath(a)
            a.Maths = embedded.fimath();
            a.MathsLocale = false;
        end
        function a = setfimath(a, F)
            a.Maths = F;
            a.MathsLocale = true;
        end

        % --- ce qu'il est ------------------------------------------------
        function oui = isnumeric(~),  oui = true;  end
        function oui = isreal(~),     oui = true;  end
        function oui = isfixed(a),    oui = strcmp(a.Type.Mode, 'fixe'); end
        function oui = isfloat(~),    oui = false; end
        function oui = isinteger(~),  oui = false; end
        function oui = issigned(a),   oui = a.Type.Signed; end
        function varargout = size(a, varargin)
            [varargout{1:max(nargout, 1)}] = size(a.Entiers, varargin{:});
        end
        function n = numel(a, varargin)
            n = numel(a.Entiers);
        end
        function n = length(a),   n = length(a.Entiers);  end
        function n = ndims(a),    n = ndims(a.Entiers);   end
        function oui = isempty(a),   oui = isempty(a.Entiers);   end
        function oui = isscalar(a),  oui = isscalar(a.Entiers);  end
        function oui = isvector(a),  oui = isvector(a.Entiers);  end
        function oui = isrow(a),     oui = isrow(a.Entiers);     end
        function oui = iscolumn(a),  oui = iscolumn(a.Entiers);  end
        function e = end(a, k, n)
            d = size(a.Entiers);
            if n == 1
                e = prod(d);
            elseif k < n
                e = d(k);
            else
                e = prod(d(k:end));
            end
        end

        % --- formes -------------------------------------------------------
        function a = reshape(a, varargin)
            a.Entiers = reshape(a.Entiers, varargin{:});
        end
        function a = transpose(a)
            a.Entiers = a.Entiers.';
        end
        function a = ctranspose(a)
            a.Entiers = a.Entiers.';
        end
        function a = repmat(a, varargin)
            a.Entiers = repmat(a.Entiers, varargin{:});
        end
        function r = horzcat(varargin)
            r = matlibre_fixe_calcul('concatener', 2, varargin{:});
        end
        function r = vertcat(varargin)
            r = matlibre_fixe_calcul('concatener', 1, varargin{:});
        end

        % --- calcul -------------------------------------------------------
        function r = plus(a, b),    r = matlibre_fixe_calcul('plus', a, b);   end
        function r = minus(a, b),   r = matlibre_fixe_calcul('minus', a, b);  end
        function r = times(a, b),   r = matlibre_fixe_calcul('times', a, b);  end
        function r = mtimes(a, b),  r = matlibre_fixe_calcul('mtimes', a, b); end
        function r = uminus(a),     r = matlibre_fixe_calcul('uminus', a);    end
        function a = uplus(a)
        end
        function r = power(a, n),   r = matlibre_fixe_calcul('power', a, n);  end
        function r = mpower(a, n)
            if ~isscalar(a.Entiers)
                error('fixed:fi:mpowerNotScalar', ...
                      'A^N ne se calcule que pour un scalaire ; employez A.^N.');
            end
            r = matlibre_fixe_calcul('power', a, n);
        end
        function r = rdivide(~, ~)
            error('fixed:fi:divisionNotSupported', ...
                  ['Diviser deux nombres a virgule fixe demande de dire le type du ' ...
                   'quotient : employez divide(T, a, b).']);
        end
        function r = mrdivide(a, b),  r = rdivide(a, b);  end
        function r = abs(a),        r = matlibre_fixe_calcul('abs', a);       end
        function r = sum(a, varargin), r = matlibre_fixe_calcul('sum', a, varargin{:}); end
        function varargout = max(a, varargin)
            [varargout{1:max(nargout, 1)}] = matlibre_fixe_calcul('max', a, varargin{:});
        end
        function varargout = min(a, varargin)
            [varargout{1:max(nargout, 1)}] = matlibre_fixe_calcul('min', a, varargin{:});
        end
        function r = eq(a, b),  r = double(a) == double(b);  end
        function r = ne(a, b),  r = double(a) ~= double(b);  end
        function r = lt(a, b),  r = double(a) < double(b);   end
        function r = le(a, b),  r = double(a) <= double(b);  end
        function r = gt(a, b),  r = double(a) > double(b);   end
        function r = ge(a, b),  r = double(a) >= double(b);  end
        function r = not(a),    r = ~double(a);              end
        function r = sign(a),   r = sign(double(a));         end

        % --- bornes -------------------------------------------------------
        function r = upperbound(a)
            [~, haut] = matlibre_fixe_bornes(a.Type);
            r = embedded.fi(haut, a.Type, a.Maths, a.MathsLocale);
        end
        function r = lowerbound(a)
            bas = matlibre_fixe_bornes(a.Type);
            r = embedded.fi(bas, a.Type, a.Maths, a.MathsLocale);
        end
        function r = range(a)
            [bas, haut] = matlibre_fixe_bornes(a.Type);
            r = embedded.fi([bas haut], a.Type, a.Maths, a.MathsLocale);
        end
        function r = eps(a)
            r = embedded.fi(1, a.Type, a.Maths, a.MathsLocale);
        end
        function r = realmax(a),  r = upperbound(a);  end
        function r = realmin(a),  r = eps(a);         end

        % --- indexation et propriétés --------------------------------------
        function varargout = subsref(a, s)
            varargout = cell(1, max(nargout, 1));
            [varargout{:}] = matlibre_fixe_calcul('lire', a, s);
        end
        function a = subsasgn(a, s, valeur)
            a = matlibre_fixe_calcul('ecrire', a, s, valeur);
        end
        function disp(a)
            matlibre_fixe_calcul('afficher', a);
        end
    end
end
