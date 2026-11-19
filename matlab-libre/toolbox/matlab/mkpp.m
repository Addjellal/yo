function pp = mkpp(breaks, coefs, d)
%MKPP Construit un polynôme par morceaux.
%   PP = MKPP(BREAKS,COEFS) assemble les L morceaux d'ordre K définis sur
%   les L+1 points de rupture croissants BREAKS : la ligne i de COEFS
%   (L x K) porte les coefficients du morceau i, puissances décroissantes,
%   en la variable x - BREAKS(i).
%   PP = MKPP(BREAKS,COEFS,D) assemble un polynôme à valeurs dans R^D :
%   COEFS a D*L lignes, la ligne D*(i-1)+c portant la composante c du
%   morceau i ; un tableau D x L x K est aussi accepté. PP est la structure
%   de MATLAB, de champs form, breaks, coefs, pieces, order et dim, que
%   PPVAL évalue et UNMKPP défait.
%
%   Exemple :
%      pp = mkpp([0 1 3], [1 0 0; -1 2 1]);   % x^2 sur [0,1], puis -(x-1)^2 + 2(x-1) + 1
%      ppval(pp, [0.5 2])                     % 0.25 et 2
%
%   Voir aussi UNMKPP, PPVAL, SPLINE, PCHIP.
    if nargin < 3
        d = 1;
    end
    breaks = double(breaks(:)).';
    L = numel(breaks) - 1;
    if L < 1 || any(diff(breaks) < 0)
        error('MATLAB:mkpp:BreaksAreNotMonotonic', ...
              'Il faut au moins deux points de rupture, croissants.');
    end
    dimension = prod(d);
    if ndims(coefs) == 3
        if size(coefs, 1) ~= dimension || size(coefs, 2) ~= L
            error('MATLAB:mkpp:PPNumberMismatchCoeffs', ...
                  'Un tableau de coefficients D x L x K : ici %d x %d x K.', dimension, L);
        end
        coefs = reshape(coefs, dimension * L, size(coefs, 3));
    end
    if mod(numel(coefs), dimension * L) ~= 0
        error('MATLAB:mkpp:PPNumberMismatchCoeffs', ...
              'Le nombre de coefficients n''est pas un multiple de D x L = %d.', dimension * L);
    end
    k = numel(coefs) / (dimension * L);
    coefs = reshape(coefs, dimension * L, k);
    pp = struct('form', 'pp', 'breaks', breaks, 'coefs', coefs, 'pieces', L, ...
                'order', k, 'dim', d);
end
