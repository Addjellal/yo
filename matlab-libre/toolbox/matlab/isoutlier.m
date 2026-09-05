function [marque, seuilBas, seuilHaut, centre] = isoutlier(a, methode, varargin)
%ISOUTLIER Repère les valeurs aberrantes.
%   M = ISOUTLIER(A) marque les éléments qui s'écartent de plus de trois
%   écarts absolus médians de la médiane.
%   M = ISOUTLIER(A,METHODE) choisit le critère :
%      'median'    trois écarts absolus médians (défaut)
%      'mean'      trois écarts types autour de la moyenne
%      'quartiles' hors de [Q1 - 1.5 IQR, Q3 + 1.5 IQR]
%      'grubbs'    test de Grubbs, une valeur à la fois
%      'percentiles' hors des centiles donnés en troisième argument
%   M = ISOUTLIER(A,METHODE,'ThresholdFactor',F) règle le facteur.
%
%   [M,BAS,HAUT,CENTRE] = ISOUTLIER(...) rend en outre les deux seuils et
%   le centre employés.
%
%   Le critère par défaut n'emploie ni la moyenne ni l'écart type : une
%   seule valeur très éloignée les déplace tous les deux, si bien qu'elle
%   se cache elle-même. La médiane et l'écart absolu médian, eux, ne
%   bougent pas — c'est ce qu'on appelle un estimateur robuste, et c'est
%   la seule raison de les préférer ici.
%
%   Le facteur 1.4826 qui apparaît dans l'écart absolu médian n'est pas
%   arbitraire : c'est celui qui le rend égal à l'écart type quand les
%   données sont gaussiennes.
%
%   Exemple :
%      isoutlier([1 2 3 4 100])        % [0 0 0 0 1]
%      isoutlier([1 2 3 4 100], 'mean')
%
%   Voir aussi FILLOUTLIERS, RMOUTLIERS, ISMISSING, MEDIAN.
    if nargin < 2 || isempty(methode)
        methode = 'median';
    end
    methode = lower(char(methode));
    centiles = [];
    if strcmp(methode, 'percentiles')
        if isempty(varargin)
            error('MATLAB:isoutlier:Centiles', ...
                  'La méthode ''percentiles'' demande les deux centiles.');
        end
        centiles = double(varargin{1});
        varargin(1) = [];
    end
    facteur = [];
    for k = 1:2:numel(varargin)
        if strcmpi(char(varargin{k}), 'thresholdfactor')
            facteur = double(varargin{k + 1});
        else
            error('MATLAB:isoutlier:Option', 'Option inconnue : %s.', ...
                  char(varargin{k}));
        end
    end
    a = double(a);
    forme = size(a);
    if isvector(a)
        [marque, seuilBas, seuilHaut, centre] = ...
            matlibre_aberrantes(a(:), methode, facteur, centiles);
        marque = reshape(marque, forme);
        return
    end
    % Une matrice est traitée colonne par colonne, comme toutes les
    % réductions de MATLAB.
    marque = false(forme);
    seuilBas = zeros(1, forme(2));
    seuilHaut = zeros(1, forme(2));
    centre = zeros(1, forme(2));
    for c = 1:forme(2)
        [marque(:, c), seuilBas(c), seuilHaut(c), centre(c)] = ...
            matlibre_aberrantes(a(:, c), methode, facteur, centiles);
    end
end
