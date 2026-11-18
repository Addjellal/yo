function [R, d, o] = matlibre_doa_options(R, nsig, arguments, fonction, permis)
%MATLIBRE_DOA_OPTIONS Vérifie la covariance et lit les options d'estimation de direction.
%   [R,D,O] = MATLIBRE_DOA_OPTIONS(R,NSIG,ARGUMENTS,FONCTION,PERMIS) rend
%   la covariance rendue hermitienne, (R + R')/2 comme MATLAB, l'espacement
%   D des éléments (0.5 longueur d'onde par défaut) et les autres options
%   permises dans la structure O.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [R, d] = matlibre_doa_options(eye(4), 1, {}, 'rootmusicdoa', {'ElementSpacing'})
%
%   Voir aussi ROOTMUSICDOA, ESPRITDOA, MUSICDOA.
    if ~ismatrix(R) || size(R, 1) ~= size(R, 2) || size(R, 1) < 2
        error(['phased:' fonction ':Covariance'], 'La covariance est une matrice N x N.');
    end
    n = size(R, 1);
    if ~isscalar(nsig) || nsig < 1 || nsig ~= fix(nsig) || nsig >= n
        error(['phased:' fonction ':NombreSignaux'], ...
              'NSIG est un entier positif, plus petit que le nombre d''éléments (%d).', n);
    end
    R = (R + R') / 2;
    o = struct('ElementSpacing', 0.5, 'ScanAngles', -90:90, 'RowWeighting', 1);
    if mod(numel(arguments), 2) ~= 0
        error(['phased:' fonction ':Options'], 'Les options vont par paires nom, valeur.');
    end
    for k = 1:2:numel(arguments)
        nom = arguments{k};
        trouve = find(strcmpi(nom, permis), 1);
        if ~ischar(nom) || isempty(trouve)
            error(['phased:' fonction ':Option'], '%s ne connaît pas l''option ''%s''.', ...
                  fonction, char(string(nom)));
        end
        o.(permis{trouve}) = arguments{k + 1};
    end
    d = o.ElementSpacing;
    if ~isscalar(d) || ~isreal(d) || d <= 0
        error(['phased:' fonction ':Espacement'], ...
              'ElementSpacing est un réel positif, en longueurs d''onde.');
    end
end
