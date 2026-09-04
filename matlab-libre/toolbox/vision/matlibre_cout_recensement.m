function cout = matlibre_cout_recensement(G, D, disparites)
%MATLIBRE_COUT_RECENSEMENT Coût d'appariement, par disparité.
%   C = MATLIBRE_COUT_RECENSEMENT(G,D,DISPARITES) rend un tableau
%   hauteur-largeur-disparités : la distance de Hamming entre les
%   recensements du pixel gauche et du pixel droit décalé d'autant. Une
%   colonne dont le correspondant sort du cadre reçoit le coût maximal.
%
%   Exemple :
%      c = matlibre_cout_recensement(magic(8), magic(8), 0:2);
%      c(4, 4, 1)    % 0, l'image appariée à elle-même sans décalage
%
%   Voir aussi DISPARITYSGM, MATLIBRE_CENSUS.
    Cg = matlibre_census(G, 5);
    Cd = matlibre_census(D, 5);
    [h, l, bits] = size(Cg);
    cout = zeros(h, l, numel(disparites));
    for k = 1:numel(disparites)
        d = disparites(k);
        somme = zeros(h, l);
        colonnes = (1 + max(d, 0)):(l + min(d, 0));
        source = colonnes - d;
        for b = 1:bits
            planGauche = Cg(:, colonnes, b);
            planDroit = Cd(:, source, b);
            somme(:, colonnes) = somme(:, colonnes) + double(xor(planGauche, planDroit));
        end
        % Hors du recouvrement, aucun appariement n'est possible : le coût
        % y est celui d'un désaccord sur tous les bits.
        if d > 0
            somme(:, 1:d) = bits;
        elseif d < 0
            somme(:, (l + d + 1):l) = bits;
        end
        cout(:, :, k) = somme;
    end
end
