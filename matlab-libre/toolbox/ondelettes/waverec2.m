function x = waverec2(C, S, nom)
%WAVEREC2 Reconstruction d'une image à partir de sa décomposition.
%   Réciproque de WAVEDEC2.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    niveaux = size(S, 1) - 2;
    courant = reshape(C(1:prod(S(1, :))), S(1, :));
    position = prod(S(1, :));
    for k = 1:niveaux
        taille = S(k + 1, :);
        n = prod(taille);
        ch = reshape(C(position + (1:n)), taille);
        cv = reshape(C(position + n + (1:n)), taille);
        cd = reshape(C(position + 2 * n + (1:n)), taille);
        position = position + 3 * n;
        courant = idwt2(courant, ch, cv, cd, nom);
    end
    x = courant;
end
