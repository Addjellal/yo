function xcov = sensorcov(pos, ang, ncov, scov)
%SENSORCOV Covariance spatiale théorique des signaux reçus par un réseau.
%   XCOV = SENSORCOV(POS,ANG) rend la matrice N x N de covariance des
%   capteurs pour des ondes planes de bande étroite arrivant des
%   directions ANG, non corrélées et de puissance un, sans bruit :
%      XCOV = A * SCOV * A' + NCOV,   A = STEERVEC(POS,ANG).
%   POS et ANG ont les formes de STEERVEC.
%
%   XCOV = SENSORCOV(POS,ANG,NCOV) ajoute le bruit : un scalaire (même
%   puissance sur chaque capteur, bruits indépendants), un vecteur 1 x N
%   (une puissance par capteur) ou une matrice N x N.
%   XCOV = SENSORCOV(POS,ANG,NCOV,SCOV) donne la covariance des signaux :
%   un scalaire (même puissance, non corrélés), un vecteur 1 x M ou une
%   matrice M x M (signaux corrélés).
%
%   Exemple :
%      % Documentation de MATLAB.
%      xcov = sensorcov((0:2) * 0.5, [30 60])
%      % xcov(1,2) = -0.9127 - 1.4086i
%
%   Voir aussi STEERVEC, ROOTMUSICDOA, ESPRITDOA, MUSICDOA.
    if nargin < 3, ncov = 0; end
    if nargin < 4, scov = 1; end
    A = steervec(pos, ang);
    [n, m] = size(A);
    S = matlibre_covariance_forme(scov, m, 'SCOV');
    B = matlibre_covariance_forme(ncov, n, 'NCOV');
    xcov = A * S * A' + B;
end

function C = matlibre_covariance_forme(c, n, nom)
    if isscalar(c)
        C = c * eye(n);
    elseif isvector(c) && numel(c) == n
        C = diag(c);
    elseif isequal(size(c), [n n])
        C = c;
    else
        error('phased:sensorcov:Taille', ...
              '%s must be a scalar, a vector of %d values, or a %d-by-%d matrix.', nom, n, n, n);
    end
end
