function C = cgMatrice(A, B)
%CGMATRICE Produit matriciel puis somme terme a terme.
    C = A * B;
    C = C + A;
    C = C';
end
