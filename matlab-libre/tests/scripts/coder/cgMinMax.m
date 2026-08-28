function [y, z] = cgMinMax(a, b)
%CGMINMAX min et max terme a terme sur des vecteurs entiers : la saturation
%   s'applique au resultat, et le C produit doit compiler.
    y = max(a, b);
    z = min(a, b) + int8(1);
end
