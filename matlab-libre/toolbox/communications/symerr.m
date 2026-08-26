function [nombre, taux] = symerr(a, b)
%SYMERR Nombre et taux d'erreurs symbole.
    nombre = sum(a(:) ~= b(:));
    taux = nombre / numel(a);
end
