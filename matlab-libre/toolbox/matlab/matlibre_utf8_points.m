function points = matlibre_utf8_points(octets)
%MATLIBRE_UTF8_POINTS Points de code d'une suite d'octets UTF-8.
%   POINTS = MATLIBRE_UTF8_POINTS(OCTETS) rend les points de code que la
%   suite représente. Un octet de tête dit combien d'octets suivent :
%   moins de 128 pour un caractère seul, 110xxxxx pour deux, 1110xxxx
%   pour trois, 11110xxx pour quatre.
%
%   Une suite mal formée est refusée plutôt que devinée : un octet de
%   continuation orphelin ne désigne aucun caractère, et lui en prêter un
%   ferait passer une donnée corrompue pour du texte.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_utf8_points(uint8([195 169]))   % 233, la lettre e accentuee
%
%   Voir aussi UNICODE2NATIVE, NATIVE2UNICODE, MATLIBRE_POINTS_UTF8.
    octets = double(octets(:))';
    points = [];
    k = 1;
    n = numel(octets);
    while k <= n
        tete = octets(k);
        if tete < 128
            suite = 0;
            valeur = tete;
        elseif tete >= 192 && tete < 224
            suite = 1;
            valeur = tete - 192;
        elseif tete >= 224 && tete < 240
            suite = 2;
            valeur = tete - 224;
        elseif tete >= 240 && tete < 248
            suite = 3;
            valeur = tete - 240;
        else
            error('MATLAB:unicode:OctetInvalide', ...
                  'Octet %d invalide en tête d''un caractère UTF-8.', tete);
        end
        if k + suite > n
            error('MATLAB:unicode:SuiteTronquee', ...
                  'La suite UTF-8 s''interrompt avant la fin du caractère.');
        end
        for j = 1:suite
            continuation = octets(k + j);
            if continuation < 128 || continuation >= 192
                error('MATLAB:unicode:OctetInvalide', ...
                      'Octet %d invalide dans la suite d''un caractère UTF-8.', continuation);
            end
            valeur = valeur * 64 + (continuation - 128);
        end
        points(end + 1) = valeur;   %#ok<AGROW>
        k = k + suite + 1;
    end
end
