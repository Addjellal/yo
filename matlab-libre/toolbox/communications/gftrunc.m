function b = gftrunc(a)
%GFTRUNC Retire les zéros de tête d'un polynôme de corps de Galois.
%   B = GFTRUNC(A) où A porte les coefficients par puissances
%   croissantes : A(1) est le terme constant. Les zéros qui suivent le
%   coefficient de plus haut degré non nul sont retirés, ce qui donne le
%   degré réel du polynôme.
%
%   Un polynôme entièrement nul est rendu comme le seul coefficient zéro.
%
%   Exemple :
%      gftrunc([1 0 1 0 0])           % [1 0 1]
%      gftrunc([0 0 0])               % 0
%
%   Voir aussi GFADD, GFCONV, GFDECONV, GFPRIMCK.
    a = double(a);
    if isempty(a)
        b = 0;
        return
    end
    if size(a, 1) > 1 && size(a, 2) > 1
        b = zeros(size(a, 1), 0);
        for k = 1:size(a, 1)
            ligne = gftrunc(a(k, :));
            if numel(ligne) > size(b, 2)
                b = [b, zeros(size(b, 1), numel(ligne) - size(b, 2))];   %#ok<AGROW>
            end
            b(k, 1:numel(ligne)) = ligne;   %#ok<AGROW>
        end
        return
    end
    dernier = find(a ~= 0, 1, 'last');
    if isempty(dernier)
        b = 0;
    else
        b = a(1:dernier);
    end
end
