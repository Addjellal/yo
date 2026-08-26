function x = waverec(C, L, nom)
%WAVEREC Reconstruction d'une décomposition multiniveaux.
    if nargin < 3
        nom = 'haar';
    end
    niveaux = numel(L) - 2;
    debut = 1;
    a = C(debut:L(1));
    debut = L(1) + 1;
    for k = 1:niveaux
        longueur = L(k + 1);
        d = C(debut:debut + longueur - 1);
        debut = debut + longueur;
        a = idwt(a, d, nom);
        if numel(a) > L(end) && k == niveaux
            a = a(1:L(end));
        end
    end
    x = a;
end
