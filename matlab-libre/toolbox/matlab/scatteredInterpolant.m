classdef scatteredInterpolant
%SCATTEREDINTERPOLANT Interpolation de données dispersées.
%   F = SCATTEREDINTERPOLANT(X,Y,V) construit un interpolant des valeurs V
%   aux points (X,Y), qui n'ont pas à former une grille. F(XQ,YQ) évalue
%   ensuite où l'on veut.
%   F = SCATTEREDINTERPOLANT(P,V) où P a deux colonnes fait la même chose.
%   F = SCATTEREDINTERPOLANT(...,METHODE) choisit 'linear' (par défaut) ou
%   'nearest'. F = SCATTEREDINTERPOLANT(...,METHODE,PROLONGEMENT) choisit
%   ce qui se passe hors de l'enveloppe convexe : 'none' (NaN, par défaut)
%   ou 'nearest'.
%
%   L'interpolation linéaire s'appuie sur la triangulation de Delaunay :
%   le point interrogé tombe dans un triangle, et sa valeur est la moyenne
%   des trois sommets pondérée par les coordonnées barycentriques. Deux
%   conséquences qui font tout l'intérêt du procédé : l'interpolant repasse
%   exactement par les données, et il est exact sur toute fonction affine —
%   trois points définissent un plan, et le barycentre y reste.
%
%   Hors de l'enveloppe convexe il n'y a pas de triangle, donc pas
%   d'interpolation : c'est de l'extrapolation, et elle est refusée par
%   défaut plutôt que devinée.
%
%   Exemple :
%      x = [0; 1; 0; 1; 0.5];  y = [0; 0; 1; 1; 0.5];
%      v = 2 * x + 3 * y + 1;             % un plan
%      F = scatteredInterpolant(x, y, v);
%      abs(F(0.25, 0.75) - (2*0.25 + 3*0.75 + 1)) < 1e-12
%      isnan(F(5, 5))                     % dehors : pas d'extrapolation
%
%   Voir aussi GRIDDEDINTERPOLANT, GRIDDATA, DELAUNAYTRIANGULATION, INTERP2.
    properties
        Points = zeros(0, 2)
        Values = zeros(0, 1)
        Method = 'linear'
        ExtrapolationMethod = 'none'
        Triangulation = []
    end

    methods
        function F = scatteredInterpolant(varargin)
            if isempty(varargin)
                return
            end
            [P, v, methode, prolongement] = matlibre_interp_arguments(varargin);
            F.Points = P;
            F.Values = v;
            F.Method = methode;
            F.ExtrapolationMethod = prolongement;
            if size(P, 1) >= 3
                F.Triangulation = delaunay(P(:, 1), P(:, 2));
            else
                F.Triangulation = zeros(0, 3);
            end
        end

        function varargout = subsref(F, s)
            switch s(1).type
                case '()'
                    r = evaluer(F, s(1).subs);
                    if numel(s) > 1
                        r = subsref(r, s(2:end));
                    end
                    varargout{1} = r;
                case '.'
                    nom = s(1).subs;
                    switch nom
                        case 'Points',              r = F.Points;
                        case 'Values',              r = F.Values;
                        case 'Method',              r = F.Method;
                        case 'ExtrapolationMethod', r = F.ExtrapolationMethod;
                        case 'Triangulation',       r = F.Triangulation;
                        otherwise
                            if numel(s) > 1 && strcmp(s(2).type, '()')
                                a = s(2).subs;
                                r = feval(nom, F, a{:});
                                s(2) = [];
                            else
                                r = feval(nom, F);
                            end
                    end
                    if numel(s) > 1
                        r = subsref(r, s(2:end));
                    end
                    varargout{1} = r;
                otherwise
                    error('MATLAB:scatteredInterpolant:badSubscript', ...
                          'Un interpolant s''évalue par parenthèses.');
            end
        end

        function v = evaluer(F, arguments)
        %EVALUER Valeur interpolée aux points demandés.
            if numel(arguments) == 1
                Q = double(arguments{1});
                forme = [size(Q, 1) 1];
            else
                xq = double(arguments{1});
                yq = double(arguments{2});
                forme = size(xq);
                Q = [xq(:), yq(:)];
            end
            v = nan(size(Q, 1), 1);
            for k = 1:size(Q, 1)
                v(k) = matlibre_interp_disperse(F, Q(k, :));
            end
            if numel(forme) == 2 && prod(forme) == numel(v)
                v = reshape(v, forme);
            end
        end
    end
end
