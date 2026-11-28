function ang = espritdoa(R, nsig, varargin)
%ESPRITDOA Directions d'arrivée par la méthode ESPRIT.
%   ANG = ESPRITDOA(R,NSIG) estime, en degrés depuis la normale, les
%   directions d'arrivée de NSIG ondes planes reçues par un réseau
%   linéaire uniforme d'éléments espacés d'une demi-longueur d'onde, dont
%   R est la covariance spatiale N x N. ANG est une ligne 1 x NSIG.
%   ANG = ESPRITDOA(R,NSIG,'ElementSpacing',D) donne l'espacement en
%   longueurs d'onde.
%
%   Le réseau se voit comme deux sous-réseaux identiques décalés d'un
%   élément : leurs sous-espaces signal E1 et E2 se déduisent l'un de
%   l'autre par une rotation dont les valeurs propres valent exp(i 2 pi d
%   sin(theta)). MatLibre la résout par moindres carrés totaux (Roy et
%   Kailath, 1989), sans balayage ni recherche de racines.
%
%   L'option 'RowWeighting' de MATLAB n'est acceptée qu'à sa valeur par
%   défaut, un : une autre pondération est refusée en le disant.
%
%   Exemple :
%      % Documentation de MATLAB.
%      R = sensorcov((0:9) * 0.5, [0 -25 30], db2pow(-5));
%      doa = espritdoa(R, 3)               % 30, 0, -25 (dans un ordre ou un autre)
%
%   Voir aussi ROOTMUSICDOA, MUSICDOA, SENSORCOV.
    [R, d, o] = matlibre_doa_options(R, nsig, varargin, 'espritdoa', ...
                                     {'ElementSpacing', 'RowWeighting'});
    if ~isequal(o.RowWeighting, 1)
        error('phased:espritdoa:RowWeighting', ...
              'MatLibre does not weight subarray rows: RowWeighting must be 1.');
    end
    n = size(R, 1);
    [V, D] = eig(R);
    [~, ordre] = sort(real(diag(D)), 'descend');
    Es = V(:, ordre(1:nsig));
    E12 = [Es(1:n - 1, :), Es(2:n, :)];
    [W, L] = eig(E12' * E12);
    [~, ordre] = sort(real(diag(L)), 'descend');
    W = W(:, ordre);
    W12 = W(1:nsig, nsig + 1:end);
    W22 = W(nsig + 1:end, nsig + 1:end);
    phi = eig(-W12 / W22);
    s = angle(phi) / (2 * pi * d);
    ang = asind(max(-1, min(1, s))).';
end
