function Pd = matlibre_mettre_a_echelle(P, D, nmes, ncom)
%MATLIBRE_METTRE_A_ECHELLE Le modèle augmenté, mis à l'échelle par D.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   DKSYN s'en sert à l'étape K : on multiplie les sorties régulées par D
%   et les entrées exogènes par son inverse, ce qui laisse la boucle
%   inchangée et change le critère que HINFSYN minimise.
    P = ss(P);
    [A, B1, B2, C1, C2, D11, D12, D21, D22] = ...
        matlibre_decouper_augmente(P, nmes, ncom);
    nz = size(C1, 1);
    nw = size(B1, 2);
    if isscalar(D)
        Dz = D * eye(nz);
        Dw = (1 / D) * eye(nw);
    else
        Dz = D;
        Dw = inv(D);
    end
    Pd = ss(A, [B1 * Dw, B2], [Dz * C1; C2], ...
            [Dz * D11 * Dw, Dz * D12; D21 * Dw, D22], P.Ts);
end
