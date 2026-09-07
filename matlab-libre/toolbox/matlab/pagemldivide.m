function x = pagemldivide(a, b)
%PAGEMLDIVIDE Résout un système par page.
%   X = PAGEMLDIVIDE(A,B) résout A(:,:,k)*X(:,:,k) = B(:,:,k) pour chaque
%   page. Si l'un des deux n'a qu'une page, elle sert pour toutes : c'est
%   la même règle de diffusion que PAGEMTIMES.
%
%   Résoudre page par page n'est pas la même chose que résoudre le grand
%   système bloc-diagonal qu'elles forment ensemble : ici les pages ne
%   communiquent pas, et c'est justement ce qu'on veut quand elles
%   décrivent des instants, des essais ou des capteurs distincts.
%
%   Exemple :
%      A = cat(3, [2 0; 0 4], [1 1; 0 1]);
%      B = cat(3, [2; 4], [3; 1]);
%      X = pagemldivide(A, B);
%      X(:, :, 1)                          % [1; 1]
%      max(max(abs(pagemtimes(A, X) - B))) < 1e-12
%
%   Voir aussi PAGEMTIMES, PAGEINV, MLDIVIDE, PAGETRANSPOSE.
    a = double(a);
    b = double(b);
    formesA = size(a);
    formesB = size(b);
    pagesA = prod(formesA(3:end));
    pagesB = prod(formesB(3:end));
    if pagesA ~= pagesB && pagesA ~= 1 && pagesB ~= 1
        error('MATLAB:pagemldivide:PageMismatch', ...
              'Les nombres de pages doivent coïncider, ou l''un valoir un.');
    end
    pages = max(pagesA, pagesB);
    premier = a(:, :, 1) \ b(:, :, 1);
    x = zeros([size(premier), pages]);
    x(:, :, 1) = premier;
    for k = 2:pages
        ka = min(k, pagesA);
        kb = min(k, pagesB);
        x(:, :, k) = a(:, :, ka) \ b(:, :, kb);
    end
    if pages == 1
        x = premier;
    end
end
