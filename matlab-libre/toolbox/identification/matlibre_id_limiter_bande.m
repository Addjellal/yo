function u = matlibre_id_limiter_bande(u, bande)
%MATLIBRE_ID_LIMITER_BANDE Restreint le contenu fréquentiel d'un signal.
%   U = MATLIBRE_ID_LIMITER_BANDE(U,BANDE) annule, dans la transformée de
%   Fourier, ce qui sort de la bande donnée en fraction de la fréquence de
%   Nyquist, puis revient au temps.
%
%   Exemple :
%      u = matlibre_id_limiter_bande(randn(100, 1), [0 0.5]);
%
%   Voir aussi IDINPUT.
    if isequal(bande, [0 1])
        return
    end
    n = numel(u);
    U = fft(u);
    moitie = floor(n / 2) + 1;
    fractions = (0:(moitie - 1)).' / max(moitie - 1, 1);
    garde = fractions >= bande(1) & fractions <= bande(2);
    masque = zeros(n, 1);
    masque(1:moitie) = garde;
    masque((moitie + 1):n) = garde(min((moitie - 1):-1:2, moitie));
    u = real(ifft(U .* masque));
end
