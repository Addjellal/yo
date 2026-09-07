function [b, a, z, p, k] = matlibre_prototype_analogique(poles, zeros_, gain, Wn, genre, gainReference)
%MATLIBRE_PROTOTYPE_ANALOGIQUE Prototype passe-bas vers filtre analogique.
%   [B,A,Z,P,K] = MATLIBRE_PROTOTYPE_ANALOGIQUE(POLES,ZEROS,GAIN,WN,GENRE)
%   applique au prototype de coupure unité la transformation de bande
%   voulue, et rend le filtre analogique correspondant. WN est en radians
%   par seconde ; deux valeurs décrivent une bande. GAINREFERENCE est le
%   module attendu à la fréquence de référence — le continu pour un
%   passe-bas, l'infini pour un passe-haut, le centre pour un
%   passe-bande ; il vaut 1 par défaut, mais un Chebyshev de type I ou un
%   elliptique d'ordre pair descend à 10^(-RP/20).
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   C'est le pendant analogique de PROTOTYPEVERSNUMERIQUE : même
%   prototype, mêmes transformations de bande, mais sans transformation
%   bilinéaire ni pré-distorsion — l'axe des fréquences n'étant pas
%   replié, il n'y a rien à corriger.
    if nargin < 6 || isempty(gainReference), gainReference = 1; end
    Wn = double(Wn(:)).';
    [num, den] = zp2tf(zeros_(:), poles(:), gain);
    bande = numel(Wn) >= 2;
    if bande
        centre = sqrt(Wn(1) * Wn(2));      % moyenne geometrique
        largeur = Wn(2) - Wn(1);
        if strncmpi(genre, 'stop', 4)
            [b, a] = lp2bs(num, den, centre, largeur);
        else
            [b, a] = lp2bp(num, den, centre, largeur);
        end
    elseif strncmpi(genre, 'high', 4)
        [b, a] = lp2hp(num, den, Wn(1));
    else
        [b, a] = lp2lp(num, den, Wn(1));
    end
    % Le gain se règle après la transformation : elle déplace la réponse
    % et le module au point de référence n'est plus celui du prototype.
    if bande
        reference = 1i * sqrt(Wn(1) * Wn(2));
        if strncmpi(genre, 'stop', 4)
            reference = 0;
        end
    elseif strncmpi(genre, 'high', 4)
        reference = [];        % l'infini : le rapport des termes de tête
    else
        reference = 0;
    end
    if isempty(reference)
        module = abs(b(1) / a(1));
    else
        module = abs(polyval(b, reference) / polyval(a, reference));
    end
    if module > 0
        b = b * (gainReference / module);
    end
    [z, p, k] = tf2zp(b, a);
end
