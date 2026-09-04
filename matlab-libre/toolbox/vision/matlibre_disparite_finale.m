function carte = matlibre_disparite_finale(agrege, disparites, unicite)
%MATLIBRE_DISPARITE_FINALE Choisit la disparité et l'affine au sous-pixel.
%   D = MATLIBRE_DISPARITE_FINALE(S,DISPARITES,UNICITE) prend en chaque
%   pixel la disparité de coût minimal, ajuste une parabole sur les trois
%   coûts qui l'entourent pour gagner une fraction de pixel, et met à NaN
%   les pixels dont le second minimum — hors du voisinage immédiat du
%   premier — n'est pas plus grand d'au moins UNICITE pour cent.
%
%   Exemple :
%      s = cat(3, ones(2), zeros(2), ones(2));
%      matlibre_disparite_finale(s, 0:2, 0)    % 1 partout
%
%   Voir aussi DISPARITYSGM.
    [h, l, n] = size(agrege);
    [meilleurCout, indice] = min(agrege, [], 3);
    carte = disparites(indice);
    carte = reshape(double(carte), h, l);
    if n >= 3
        % Parabole passant par les trois coûts autour du minimum : son
        % sommet donne la fraction de pixel.
        gauche = coutVoisin(agrege, indice, -1, meilleurCout);
        droite = coutVoisin(agrege, indice, 1, meilleurCout);
        denominateur = gauche - 2 * meilleurCout + droite;
        correction = zeros(h, l);
        utile = abs(denominateur) > eps & indice > 1 & indice < n;
        correction(utile) = (gauche(utile) - droite(utile)) ./ ...
                            (2 * denominateur(utile));
        correction(abs(correction) > 1) = 0;
        carte = carte + correction;
    end
    if unicite > 0 && n >= 3
        % Second minimum, en écartant les disparités voisines du premier :
        % un minimum large n'est pas une ambiguïté.
        masque = agrege;
        for decalage = -1:1
            position = indice + decalage;
            position = min(max(position, 1), n);
            masque = poserInfini(masque, position);
        end
        second = min(masque, [], 3);
        ambigu = second < meilleurCout * (1 + unicite / 100);
        carte(ambigu) = NaN;
    end
    carte = single(carte);
end

function valeurs = coutVoisin(agrege, indice, decalage, defaut)
    n = size(agrege, 3);
    position = indice + decalage;
    dedans = position >= 1 & position <= n;
    position = min(max(position, 1), n);
    valeurs = extraire(agrege, position);
    valeurs(~dedans) = defaut(~dedans);
end

function valeurs = extraire(agrege, position)
    [h, l, ~] = size(agrege);
    lineaire = (1:(h * l)).' + (position(:) - 1) * (h * l);
    valeurs = reshape(agrege(lineaire), h, l);
end

function agrege = poserInfini(agrege, position)
    [h, l, ~] = size(agrege);
    lineaire = (1:(h * l)).' + (position(:) - 1) * (h * l);
    agrege(lineaire) = Inf;
end
