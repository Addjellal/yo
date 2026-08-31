function [garde, rejet] = matlibre_scinder_modes(G, poles, aGarder)
%MATLIBRE_SCINDER_MODES Découpe un modèle en deux selon ses modes.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   SLOWFAST et STABPROJ s'en servent. Le découpage passe par une base
%   propre réelle : les modes retenus donnent le premier modèle, les
%   autres le second, et la somme des deux redonne le modèle de départ
%   parce qu'un modèle diagonalisable est la somme de ses modes.
    n = size(G.A, 1);
    if n == 0
        garde = G;
        rejet = ss(zeros(size(G.D)));
        rejet.Ts = G.Ts;
        return;
    end
    [V, D] = eig(G.A);
    valeurs = diag(D);
    % On apparie chaque pole a sa colonne propre, dans l'ordre des poles
    % fournis.
    ordreGarde = [];
    ordreRejet = [];
    pris = false(n, 1);
    for k = 1:n
        [~, rang] = min(abs(valeurs - poles(k)) + pris * 1e12);
        pris(rang) = true;
        if aGarder(k)
            ordreGarde(end + 1) = rang;    %#ok<AGROW>
        else
            ordreRejet(end + 1) = rang;    %#ok<AGROW>
        end
    end
    ordre = [ordreGarde, ordreRejet];
    Vr = matlibre_base_reelle(V(:, ordre), valeurs(ordre));
    if rcond(Vr) < eps
        % Modes defectifs : on ne peut pas separer proprement.
        garde = G;
        rejet = ss(zeros(size(G.D)));
        rejet.Ts = G.Ts;
        return;
    end
    T = inv(Vr);
    A = T * G.A * Vr;
    B = T * G.B;
    C = G.C * Vr;
    m = numel(ordreGarde);
    % La base propre rend A bloc-diagonale : les deux blocs ne se parlent
    % pas, et la somme des deux modeles redonne le modele de depart.
    garde = ss(A(1:m, 1:m), B(1:m, :), C(:, 1:m), G.D, G.Ts);
    rejet = ss(A(m + 1:end, m + 1:end), B(m + 1:end, :), C(:, m + 1:end), ...
               zeros(size(G.D)), G.Ts);
end
