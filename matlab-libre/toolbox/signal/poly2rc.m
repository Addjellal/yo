function [k, e] = poly2rc(a, efinal)
%POLY2RC Coefficients de réflexion d'un polynôme de prédiction.
%   K = POLY2RC(A) applique la récurrence de Levinson à l'envers : à
%   chaque étape, le dernier coefficient du polynôme d'ordre M est le
%   coefficient de réflexion K(M), et le polynôme d'ordre M-1 s'en
%   déduit.
%
%   [K,E] = POLY2RC(A,EFINAL) rend aussi les erreurs de prédiction de
%   chaque ordre, à partir de l'erreur finale.
%
%   Exemple :
%      k = poly2rc([1 0.6149 0.9899 0 0.0031 -0.0082]);
    if nargin < 2 || isempty(efinal), efinal = 0; end
    a = double(a(:)).';
    if a(1) == 0
        error('signal:poly2rc:ZeroLeading', ...
              'Le premier coefficient doit être non nul.');
    end
    a = a / a(1);
    p = numel(a) - 1;
    k = zeros(p, 1);
    e = zeros(p, 1);
    courant = a;
    for m = p:-1:1
        k(m) = courant(m + 1);
        if abs(k(m)) == 1
            error('signal:poly2rc:UnstablePolynomial', ...
                  'Le polynôme n''est pas à phase minimale.');
        end
        precedent = ones(1, m);
        for i = 1:m-1
            precedent(i + 1) = (courant(i + 1) - k(m) * conj(courant(m - i + 1))) / ...
                               (1 - abs(k(m)) ^ 2);
        end
        courant = precedent;
    end
    if nargout > 1
        % L'erreur remonte les ordres : e(m-1) = e(m)/(1-|k(m)|^2).
        e(p) = efinal;
        for m = p:-1:2
            e(m - 1) = e(m) / (1 - abs(k(m)) ^ 2);
        end
    end
end
