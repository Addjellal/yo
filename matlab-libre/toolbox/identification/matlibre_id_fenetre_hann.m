function fenetre = matlibre_id_fenetre_hann(M)
%MATLIBRE_ID_FENETRE_HANN Fenêtre de Hann sur les décalages.
%   W = MATLIBRE_ID_FENETRE_HANN(M) rend les poids des décalages de moins
%   M à plus M : un au décalage nul, zéro aux extrémités, en cosinus
%   surélevé.
%
%   Pondérer ainsi les covariances avant de les transformer, plutôt que de
%   les tronquer net, évite les oscillations qu'une troncature brutale
%   introduit dans le spectre.
%
%   Exemple :
%      w = matlibre_id_fenetre_hann(2);
%      w(3)      % 1, au decalage nul
%
%   Voir aussi SPA.
    decalages = (-M:M).';
    fenetre = 0.5 * (1 + cos(pi * decalages / M));
end
