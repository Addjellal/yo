function J = integralImage(I)
%INTEGRALIMAGE Image intégrale, ou table de sommes cumulées.
%   J = INTEGRALIMAGE(I) rend une matrice d'une ligne et d'une colonne de
%   plus que I : J(i+1,j+1) est la somme des pixels du rectangle allant du
%   coin supérieur gauche à (i,j). La première ligne et la première
%   colonne sont nulles, ce qui évite tout cas particulier.
%
%   La somme sur un rectangle quelconque se lit alors en quatre accès, quel
%   que soit sa taille : c'est ce qui rend les filtres à boîte et les
%   détecteurs en cascade indépendants de l'échelle.
%
%   Exemple :
%      J = integralImage(ones(3));
%      J(end, end)   % 9
%
%   Voir aussi INTEGRALFILTER, DETECTFASTFEATURES.
    I = double(I);
    if ndims(I) == 3
        J = zeros(size(I, 1) + 1, size(I, 2) + 1, size(I, 3));
        for c = 1:size(I, 3)
            J(:, :, c) = integralImage(I(:, :, c));
        end
        return
    end
    J = zeros(size(I, 1) + 1, size(I, 2) + 1);
    J(2:end, 2:end) = cumsum(cumsum(I, 1), 2);
end
