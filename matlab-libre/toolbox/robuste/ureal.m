classdef ureal
%UREAL Paramètre réel incertain.
%   P = UREAL('nom',NOMINAL) crée un paramètre réel dont la valeur
%   nominale est NOMINAL et qui peut s'en écarter de 10 pour cent.
%
%   P = UREAL('nom',NOMINAL,'Range',[BAS HAUT]) donne les bornes en
%   clair.
%   P = UREAL('nom',NOMINAL,'Percentage',[-A B]) les donne en pour cent
%   de la valeur nominale ; un seul nombre vaut pour les deux côtés.
%   P = UREAL('nom',NOMINAL,'PlusMinus',[-A B]) les donne en écart
%   absolu.
%
%   Un paramètre incertain s'emploie comme un nombre : il s'ajoute, se
%   multiplie, se divise. Le résultat est un UMAT — une matrice
%   incertaine — qui garde la trace de ce dont il dépend.
%
%      m = ureal('m', 1200, 'Percentage', 10);
%      k = ureal('k', 5e4, 'Range', [4e4 6e4]);
%      pulsation = sqrt(k / m);          % un umat, fonction de m et de k
%      pulsation.NominalValue            % 6.455
%
%   Les propriétés :
%      Name           le nom, par lequel USUBS le retrouve ;
%      NominalValue   la valeur nominale ;
%      Range          les deux bornes ;
%      Mode           'Range', 'Percentage' ou 'PlusMinus'.
%
%   MATLAB représente une incertitude par une transformation
%   fractionnaire linéaire, ce qui permet une analyse mu exacte. MatLibre
%   la représente par la dépendance elle-même — la fonction des
%   paramètres —, ce qui vaut pour n'importe quelle dépendance, y
%   compris une division, et ce que les fonctions d'analyse exploitent
%   en balayant le domaine des paramètres. Ce qui manque est l'analyse mu
%   exacte ; ce qu'on gagne est de pouvoir écrire le modèle tel qu'il
%   vient.
%
%   Exemples :
%      p = ureal('p', 2)
%      p.Range                            % [1.8 2.2]
%      usample(p, 5)                      % cinq tirages dans l'intervalle
%      usubs(p, 'p', 2.1)                 % 2.1
%
%   Voir aussi UMAT, USS, USAMPLE, USUBS, UCOMPLEX, ULTIDYN, WCGAIN.
    properties
        Name = ''
        NominalValue = 0
        Range = [0 0]
        Mode = 'Percentage'
        AutoSimplify = 'basic'
    end

    methods
        function p = ureal(nom, nominal, varargin)
            if nargin == 0
                return
            end
            p.Name = char(nom);
            p.NominalValue = double(nominal);
            p.Range = p.NominalValue + [-0.1, 0.1] * abs(p.NominalValue);
            if p.NominalValue == 0
                p.Range = [-0.1, 0.1];
            end
            k = 1;
            while k + 1 <= numel(varargin)
                option = lower(char(varargin{k}));
                valeur = varargin{k + 1};
                switch option
                    case 'range'
                        p.Range = sort(double(valeur(:))');
                        p.Mode = 'Range';
                    case 'percentage'
                        v = double(valeur(:))';
                        if isscalar(v)
                            v = [-abs(v), abs(v)];
                        end
                        p.Range = p.NominalValue + sort(v) / 100 * abs(p.NominalValue);
                        p.Mode = 'Percentage';
                    case 'plusminus'
                        v = double(valeur(:))';
                        if isscalar(v)
                            v = [-abs(v), abs(v)];
                        end
                        p.Range = p.NominalValue + sort(v);
                        p.Mode = 'PlusMinus';
                    case 'autosimplify'
                        p.AutoSimplify = char(valeur);
                    otherwise
                        error('Robust:ureal:BadOption', ...
                              'Unknown option ''%s''.', option);
                end
                k = k + 2;
            end
            if p.Range(1) > p.NominalValue || p.Range(2) < p.NominalValue
                error('Robust:ureal:NominalOutside', ...
                      'The nominal value must lie inside the range.');
            end
        end

        % --- l'arithmetique : tout passe par umat ------------------------
        function r = plus(a, b), r = umat(a) + umat(b); end
        function r = minus(a, b), r = umat(a) - umat(b); end
        function r = uminus(a), r = -umat(a); end
        function r = uplus(a), r = umat(a); end
        function r = mtimes(a, b), r = umat(a) * umat(b); end
        function r = times(a, b), r = umat(a) .* umat(b); end
        function r = mrdivide(a, b), r = umat(a) / umat(b); end
        function r = rdivide(a, b), r = umat(a) ./ umat(b); end
        function r = mldivide(a, b), r = umat(b) / umat(a); end
        function r = mpower(a, n), r = umat(a) ^ n; end
        function r = power(a, n), r = umat(a) .^ n; end
        function r = sqrt(a), r = sqrt(umat(a)); end
        function r = abs(a), r = abs(umat(a)); end
        function r = transpose(a), r = umat(a); end
        function r = ctranspose(a), r = umat(a); end
        function r = horzcat(varargin)
            morceaux = cell(1, numel(varargin));
            for k = 1:numel(varargin)
                morceaux{k} = umat(varargin{k});
            end
            r = horzcat(morceaux{:});
        end
        function r = vertcat(varargin)
            morceaux = cell(1, numel(varargin));
            for k = 1:numel(varargin)
                morceaux{k} = umat(varargin{k});
            end
            r = vertcat(morceaux{:});
        end
        function d = double(p), d = p.NominalValue; end
        function n = numel(p), n = 1; end                    %#ok<MANU>
        function varargout = size(p, dimension)               %#ok<INUSL>
            if nargin >= 2
                varargout{1} = 1;
                return
            end
            if nargout <= 1
                varargout{1} = [1 1];
            else
                varargout{1} = 1;
                varargout{2} = 1;
            end
        end
        function disp(p)
            fprintf('  parametre reel incertain « %s » : nominal %g, plage [%g %g]\n', ...
                    p.Name, p.NominalValue, p.Range(1), p.Range(2));
        end
    end
end
