function [a, b, m, prim] = matlibre_gf_paire(a, b)
%MATLIBRE_GF_PAIRE Ramène deux opérandes au même corps et à la même taille.
%   Un nombre ordinaire est admis comme élément du corps de l'autre ;
%   deux tableaux de corps différents sont refusés.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isa(a, 'gf') && isa(b, 'gf')
        if a.m ~= b.m || a.prim_poly ~= b.prim_poly
            error('comm:gf:Corps', ...
                  'Les deux tableaux ne sont pas du même corps de Galois.');
        end
        m = a.m;
        prim = a.prim_poly;
        va = a.x;
        vb = b.x;
    elseif isa(a, 'gf')
        m = a.m;
        prim = a.prim_poly;
        va = a.x;
        vb = round(double(b));
    else
        m = b.m;
        prim = b.prim_poly;
        va = round(double(a));
        vb = b.x;
    end
    [a, b] = matlibre_gf_etendre(va, vb);
end
