function [M, classes] = confusionmat(vrai, predit)
%CONFUSIONMAT Matrice de confusion.
%   M(i,j) compte les observations de la classe i classées en j.
    vrai = vrai(:);
    predit = predit(:);
    classes = unique([vrai; predit]);
    k = numel(classes);
    M = zeros(k, k);
    for i = 1:numel(vrai)
        a = find(classes == vrai(i));
        b = find(classes == predit(i));
        M(a, b) = M(a, b) + 1;
    end
end
