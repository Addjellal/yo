function a = appcoef2(C, S, nom, niveau)
%APPCOEF2 Coefficients d'approximation d'une image décomposée.
%   A = APPCOEF2(C,S,NOM,N) reconstruit l'approximation du niveau N.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    niveauMax = size(S, 1) - 2;
    if nargin < 4 || isempty(niveau), niveau = niveauMax; end
    if niveau > niveauMax || niveau < 0
        error('wavelet:appcoef2:BadLevel', 'Niveau hors de la décomposition.');
    end
    a = reshape(C(1:prod(S(1, :))), S(1, :));
    position = prod(S(1, :));
    for k = 1:niveauMax - niveau
        taille = S(k + 1, :);
        n = prod(taille);
        ch = reshape(C(position + (1:n)), taille);
        cv = reshape(C(position + n + (1:n)), taille);
        cd = reshape(C(position + 2 * n + (1:n)), taille);
        position = position + 3 * n;
        a = idwt2(a, ch, cv, cd, nom);
    end
end
