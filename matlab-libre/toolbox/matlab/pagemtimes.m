function c = pagemtimes(a, ta, b, tb)
%PAGEMTIMES Produit matriciel page par page.
%   C = PAGEMTIMES(A,B) multiplie chaque page A(:,:,k) par la page
%   B(:,:,k) correspondante. Une entrée n'ayant qu'une page sert à
%   toutes les pages de l'autre.
%
%   C = PAGEMTIMES(A,TA,B,TB) transpose au passage : TA et TB valent
%   'none', 'transpose' ou 'ctranspose'.
%
%   Exemple :
%      a = reshape(1:8, 2, 2, 2);
%      c = pagemtimes(a, a);
%
%   Voir aussi MTIMES, PAGETRANSPOSE, PAGEMLDIVIDE.
    if nargin == 2
        b = ta;
        ta = 'none';
        tb = 'none';
    elseif nargin ~= 4
        error('pagemtimes:Arguments', ...
              'pagemtimes attend deux ou quatre arguments.');
    end
    a = transposerPages(a, ta);
    b = transposerPages(b, tb);
    ta = size(a);
    tb = size(b);
    pagesA = prod(ta(3:end));
    pagesB = prod(tb(3:end));
    if pagesA ~= pagesB && pagesA ~= 1 && pagesB ~= 1
        error('pagemtimes:Pages', ...
              'Les nombres de pages (%d et %d) ne s''accordent pas.', ...
              pagesA, pagesB);
    end
    npages = max(pagesA, pagesB);
    c = zeros(ta(1), tb(2), npages);
    for k = 1:npages
        pa = a(:, :, min(k, pagesA));
        pb = b(:, :, min(k, pagesB));
        c(:, :, k) = pa * pb;
    end
    if pagesA >= pagesB
        forme = ta;
    else
        forme = tb;
    end
    c = reshape(c, [ta(1), tb(2), forme(3:end)]);
end

function x = transposerPages(x, mode)
    switch lower(char(mode))
        case 'none'
            % Rien à faire.
        case 'transpose'
            x = pagetranspose(x);
        case 'ctranspose'
            x = pagectranspose(x);
        otherwise
            error('pagemtimes:Mode', 'Mode de transposition inconnu : %s.', mode);
    end
end
