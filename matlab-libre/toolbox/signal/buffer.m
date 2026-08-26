function [y, reste] = buffer(x, n, p, opt)
%BUFFER Découpe un signal en colonnes de longueur fixe.
%   Y = BUFFER(X,N) range X en colonnes de N points, la dernière complétée
%   par des zéros. BUFFER(X,N,P) fait se recouvrir les colonnes de P
%   points (P négatif saute P points entre deux colonnes).
%
%   Exemple :
%      buffer(1:6, 3)   % [1 4; 2 5; 3 6]
    if nargin < 3 || isempty(p), p = 0; end
    x = x(:);
    nx = numel(x);
    if p >= n
        error('signal:buffer:BadOverlap', 'The overlap must be smaller than the length.');
    end
    pas = n - p;
    if p < 0
        pas = n - p;   % saut : on jette -p echantillons entre deux colonnes
    end
    debuts = 1:pas:nx;
    colonnes = numel(debuts);
    y = zeros(n, colonnes);
    for k = 1:colonnes
        indices = debuts(k):min(debuts(k) + n - 1, nx);
        y(1:numel(indices), k) = x(indices);
    end
    % La dernière colonne incomplète part dans « reste » quand on la demande.
    if nargout > 1 && colonnes > 0
        dernier = debuts(end);
        if dernier + n - 1 > nx
            reste = x(dernier:nx);
            y(:, end) = [];
        else
            reste = zeros(0, 1);
        end
    else
        reste = zeros(0, 1);
    end
    if nargin >= 4 && ischar(opt) && strcmpi(opt, 'nodelay') && p > 0
        % rien de plus : la première colonne commence déjà à x(1)
    end
end
