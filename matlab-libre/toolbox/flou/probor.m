function y = probor(x, varargin)
%PROBOR Ou probabiliste, ou somme algébrique.
%   Y = PROBOR(A,B) vaut A + B - A.*B. C'est la t-conorme associée au
%   produit : elle remplace le maximum quand on veut que deux
%   activations partielles se renforcent au lieu de s'ignorer.
%
%   Y = PROBOR(X) applique l'opération le long des colonnes de X, ou le
%   long d'un vecteur.
%
%   Exemple :
%      probor(0.5, 0.5)      % 0.75
%      probor([0.5 0.5])     % 0.75
%
%   Voir aussi MAX, MIN, EVALFIS.
    if isempty(varargin)
        v = double(x);
        if isvector(v)
            y = reduireProbor(v(:)');
        else
            y = zeros(1, size(v, 2));
            for k = 1:size(v, 2)
                y(k) = reduireProbor(v(:, k)');
            end
        end
        return
    end
    y = double(x);
    for k = 1:numel(varargin)
        b = double(varargin{k});
        y = y + b - y .* b;
    end
end

function y = reduireProbor(v)
    y = 0;
    for k = 1:numel(v)
        y = y + v(k) - y * v(k);
    end
end
