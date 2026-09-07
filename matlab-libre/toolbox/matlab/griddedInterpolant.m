classdef griddedInterpolant
%GRIDDEDINTERPOLANT Interpolation sur une grille.
%   F = GRIDDEDINTERPOLANT(X,V) construit un interpolant des valeurs V aux
%   abscisses X, croissantes. F = GRIDDEDINTERPOLANT(X,Y,V) fait de même
%   sur une grille du plan, V étant de taille NUMEL(X) par NUMEL(Y) —
%   l'ordre de NDGRID, non celui de MESHGRID.
%   F = GRIDDEDINTERPOLANT(...,METHODE) choisit 'linear' (par défaut),
%   'nearest', 'spline' ou 'pchip'. Une seconde chaîne donne le
%   prolongement : 'none' (NaN) ou 'linear'.
%
%   La différence avec SCATTEREDINTERPOLANT tient à la grille : les points
%   étant rangés, retrouver la maille qui contient la question est une
%   recherche dichotomique, non un parcours de triangles. C'est pour cela
%   qu'un interpolant de grille est bien plus rapide, et c'est la seule
%   raison de le distinguer.
%
%   Quel que soit le procédé, l'interpolant repasse exactement par les
%   valeurs données : c'est ce qui distingue interpoler d'ajuster.
%
%   Exemple :
%      x = linspace(0, 1, 11);
%      F = griddedInterpolant(x, 3 * x + 1);
%      abs(F(0.35) - (3 * 0.35 + 1)) < 1e-12    % exacte sur l'affine
%      max(abs(F(x) - (3 * x + 1))) < 1e-12     % et sur les noeuds
%
%   Voir aussi SCATTEREDINTERPOLANT, INTERP1, INTERP2, NDGRID.
    properties
        GridVectors = {}
        Values = []
        Method = 'linear'
        ExtrapolationMethod = 'none'
    end

    methods
        function F = griddedInterpolant(varargin)
            if isempty(varargin)
                return
            end
            textes = {};
            while ~isempty(varargin) && ...
                  (ischar(varargin{end}) || isstring(varargin{end}))
                textes = [{char(varargin{end})}, textes];   %#ok<AGROW>
                varargin(end) = [];
            end
            if ~isempty(textes), F.Method = lower(textes{1}); end
            if numel(textes) > 1, F.ExtrapolationMethod = lower(textes{2}); end
            if numel(varargin) < 2
                error('MATLAB:griddedInterpolant:Arguments', ...
                      'Il faut la grille et les valeurs.');
            end
            F.Values = double(varargin{end});
            grille = varargin(1:end-1);
            F.GridVectors = cell(1, numel(grille));
            for k = 1:numel(grille)
                vecteur = double(grille{k});
                F.GridVectors{k} = vecteur(:)';
            end
            if numel(F.GridVectors) == 1
                F.Values = F.Values(:);
                if numel(F.Values) ~= numel(F.GridVectors{1})
                    error('MATLAB:griddedInterpolant:Tailles', ...
                          'Il faut autant de valeurs que de points de grille.');
                end
            elseif numel(F.GridVectors) == 2
                attendu = [numel(F.GridVectors{1}), numel(F.GridVectors{2})];
                if ~isequal(size(F.Values), attendu)
                    error('MATLAB:griddedInterpolant:Tailles', ...
                          'V doit être de taille NUMEL(X) par NUMEL(Y).');
                end
            else
                error('MATLAB:griddedInterpolant:Dimension', ...
                      'GRIDDEDINTERPOLANT traite une et deux dimensions.');
            end
        end

        function varargout = subsref(F, s)
            switch s(1).type
                case '()'
                    r = evaluer(F, s(1).subs);
                    if numel(s) > 1, r = subsref(r, s(2:end)); end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'GridVectors',         r = F.GridVectors;
                        case 'Values',              r = F.Values;
                        case 'Method',              r = F.Method;
                        case 'ExtrapolationMethod', r = F.ExtrapolationMethod;
                        otherwise
                            if numel(s) > 1 && strcmp(s(2).type, '()')
                                a = s(2).subs;
                                r = feval(nom, F, a{:});
                                s(2) = [];
                            else
                                r = feval(nom, F);
                            end
                    end
                    if numel(s) > 1, r = subsref(r, s(2:end)); end
                    varargout{1} = r;
                otherwise
                    error('MATLAB:griddedInterpolant:badSubscript', ...
                          'Un interpolant s''évalue par parenthèses.');
            end
        end

        function v = evaluer(F, arguments)
        %EVALUER Valeur interpolée aux points demandés.
            if numel(F.GridVectors) == 1
                xq = double(arguments{1});
                dehors = 'none';
                if strcmp(F.ExtrapolationMethod, 'none'), dehors = NaN; end
                if isnumeric(dehors)
                    v = interp1(F.GridVectors{1}, F.Values, xq, F.Method, NaN);
                else
                    v = interp1(F.GridVectors{1}, F.Values, xq, F.Method, 'extrap');
                end
                return
            end
            xq = double(arguments{1});
            yq = double(arguments{2});
            % INTERP2 attend la disposition de MESHGRID ; la grille d'un
            % interpolant est celle de NDGRID. La transposee fait le pont.
            [X, Y] = meshgrid(F.GridVectors{1}, F.GridVectors{2});
            if strcmp(F.ExtrapolationMethod, 'none')
                v = interp2(X, Y, F.Values', xq, yq, F.Method);
            else
                v = interp2(X, Y, F.Values', xq, yq, F.Method, 'extrap');
            end
        end
    end
end
