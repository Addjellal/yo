function [s, y] = cgComplexeVecteur(v)
%CGCOMPLEXEVECTEUR Somme d'un vecteur complexe, et son conjugue transpose.
    s = sum(v);
    y = v';
end
