function ber = bersync(EbNodB, erreur, type)
%BERSYNC Taux d'erreur avec un défaut de synchronisation.
%   BER = BERSYNC(EBNO,TAU,'timing') donne le taux d'erreur binaire d'une
%   modulation à deux états sur canal gaussien lorsque l'instant
%   d'échantillonnage est décalé de TAU, fraction de la durée d'un
%   symbole entre zéro et un demi.
%
%   BER = BERSYNC(EBNO,PHI,'carrier') traite un défaut de phase de la
%   porteuse, PHI en radians.
%
%   Le décalage d'échantillonnage réduit l'amplitude utile d'un facteur
%   1-2|TAU| — ce que le filtre adapté laisse passer du symbole voulu —,
%   et le défaut de phase d'un facteur COS(PHI). Le taux d'erreur suit :
%
%      BER = Q( facteur * sqrt(2 Eb/No) ).
%
%   Exemple :
%      sansDefaut = bersync(0:8, 0, 'timing');
%      avecDefaut = bersync(0:8, 0.2, 'timing');
%      all(avecDefaut > sansDefaut)   % vrai : le défaut coûte
%
%   Voir aussi BERAWGN, BERFADING, BERCODING, BERCONFINT.
    if nargin < 3 || isempty(type), type = 'timing'; end
    EbNo = 10 .^ (double(EbNodB) / 10);
    switch lower(char(type))
        case {'timing', 'time'}
            if any(abs(erreur) > 0.5)
                error('comm:bersync:Retard', ...
                      'Le décalage doit rester entre moins un demi et un demi.');
            end
            facteur = 1 - 2 * abs(erreur);
        case {'carrier', 'phase'}
            facteur = cos(erreur);
        otherwise
            error('comm:bersync:Type', ...
                  'Le type doit être ''timing'' ou ''carrier''.');
    end
    facteur = max(facteur, 0);
    ber = 0.5 * erfc(facteur .* sqrt(EbNo));
end
