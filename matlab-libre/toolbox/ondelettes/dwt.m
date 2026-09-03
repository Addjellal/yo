function [approximation, detail] = dwt(x, nom)
%DWT Transformée en ondelettes discrète, un niveau.
%   [A,D] = DWT(X,NOM) rend l'approximation et le détail, sous-échantillonnés
%   d'un facteur deux. Les bords sont prolongés périodiquement, ce qui
%   correspond au mode 'per' de MATLAB : A et D comptent chacun
%   NUMEL(X)/2 échantillons.
%
%   L'analyse convolue le signal par les filtres de décomposition, ce qui
%   revient à le corréler avec ces mêmes filtres renversés :
%
%      A(k) = somme_j Lo_D(N+1-j) X(2k-2+j)
%      D(k) = somme_j Hi_D(N+1-j) X(2k-2+j)
%
%   Pour une ondelette orthogonale, Lo_D renversé est Lo_R : c'est la
%   forme habituelle. Pour une biorthogonale les deux diffèrent, et c'est
%   bien le filtre d'analyse qu'il faut employer ici.
%
%   Exemple :
%      [a, d] = dwt([1 2 3 4], 'haar')   % a = [2.1213 4.9497]
%                                        % d = [-0.7071 -0.7071]
%
%   Voir aussi IDWT, WAVEDEC, WFILTERS, SWT, MODWT.
    if nargin < 2
        nom = 'haar';
    end
    [Lo_D, Hi_D] = wfilters(nom, 'd');
    Lo_R = Lo_D(end:-1:1);
    Hi_R = Hi_D(end:-1:1);
    x = x(:).';
    n = numel(x);
    if mod(n, 2) == 1
        x = [x x(end)];
        n = n + 1;
    end
    f = numel(Lo_R);
    approximation = zeros(1, n / 2);
    detail = zeros(1, n / 2);
    for k = 1:n/2
        sa = 0;
        sd = 0;
        for j = 1:f
            indice = mod(2 * k - 2 + j - 1, n) + 1;
            sa = sa + Lo_R(j) * x(indice);
            sd = sd + Hi_R(j) * x(indice);
        end
        approximation(k) = sa;
        detail(k) = sd;
    end
end
