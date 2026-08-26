function [b, a] = prototypeVersNumerique(poles, zeros_, gain, Wn, genre, gainReference)
%PROTOTYPEVERSNUMERIQUE Prototype analogique -> filtre numérique.
%   Applique la transformation passe-bas ou passe-haut puis la
%   transformation bilinéaire, avec pré-distorsion de la fréquence :
%   omega = 2*tan(pi*Wn/2), comme le veut la conception de MATLAB.
%   GAINREFERENCE est le module attendu en continu (passe-bas) ou à
%   Nyquist (passe-haut) ; il vaut 1 par défaut, mais un Chebyshev de
%   type I d'ordre pair descend à 10^(-RP/20).
    if nargin < 6, gainReference = 1; end
    omega = 2 * tan(pi * Wn / 2);
    n = numel(poles);
    if strncmpi(genre, 'high', 4)
        polesAnalogiques = omega ./ poles;
        if isempty(zeros_)
            zerosAnalogiques = zeros(n, 1);
        else
            zerosAnalogiques = [omega ./ zeros_(:); zeros(n - numel(zeros_), 1)];
        end
        gainAnalogique = gain;
    else
        polesAnalogiques = omega * poles;
        if isempty(zeros_)
            zerosAnalogiques = zeros(0, 1);
        else
            zerosAnalogiques = omega * zeros_(:);
        end
        gainAnalogique = gain * omega^(n - numel(zerosAnalogiques));
    end
    % Bilinéaire : s = 2*(z-1)/(z+1).
    polesNumeriques = (2 + polesAnalogiques(:)) ./ (2 - polesAnalogiques(:));
    if isempty(zerosAnalogiques)
        zerosNumeriques = -ones(n, 1);
    else
        zerosNumeriques = (2 + zerosAnalogiques(:)) ./ (2 - zerosAnalogiques(:));
        manquants = n - numel(zerosNumeriques);
        if manquants > 0
            zerosNumeriques = [zerosNumeriques; -ones(manquants, 1)];
        end
    end
    b = real(poly(zerosNumeriques));
    a = real(poly(polesNumeriques));
    % Normalisation du gain : unité en continu pour un passe-bas, en
    % Nyquist pour un passe-haut.
    if strncmpi(genre, 'high', 4)
        reference = -1;
    else
        reference = 1;
    end
    numerateur = polyval(b, reference);
    denominateur = polyval(a, reference);
    if numerateur ~= 0
        b = b * gainReference * (denominateur / numerateur);
    end
    % gainAnalogique n'entre pas dans le résultat : la normalisation en
    % fréquence de référence fixe le gain, ce qui évite l'accumulation
    % d'erreur sur le produit des pôles.
    gainAnalogique = gainAnalogique;   %#ok<ASGSL>
end
