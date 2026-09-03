function w = normaliserSomme(w, sumf)
%NORMALISERSOMME Met un filtre d'échelle à la somme demandée.
%   W = NORMALISERSOMME(W,SOMME) met la somme de W à SOMME. Une somme
%   nulle veut dire « norme deux unitaire », ce qui pour un filtre
%   d'échelle revient à une somme de racine de deux : c'est la convention
%   de DBAUX et SYMAUX.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    w = double(w(:))';
    total = sum(w);
    if total == 0
        error('wavelet:normaliserSomme:SommeNulle', ...
              'Le filtre est de somme nulle : il n''est pas normalisable.');
    end
    if isempty(sumf) || sumf == 0
        w = w / total * sqrt(2);
    else
        w = w / total * double(sumf);
    end
end
