function score = matlibre_score_fast(I)
%MATLIBRE_SCORE_FAST Force de coin au sens de FAST, en chaque pixel.
%   S = MATLIBRE_SCORE_FAST(I) rend, pour chaque pixel, le plus grand
%   seuil auquel il reste un coin FAST : le maximum, sur les seize arcs de
%   neuf voisins consécutifs du cercle de Bresenham, du plus petit écart
%   au centre. Un pixel qui n'est pas un coin reçoit zéro.
%
%   C'est la définition même du détecteur : un coin est un point dont un
%   arc entier du cercle est plus clair, ou plus sombre, que le centre.
%   Le score ainsi défini sert à comparer des coins entre eux et à les
%   comparer d'une échelle à l'autre.
%
%   Exemple :
%      I = zeros(11); I(1:5, 1:5) = 1;
%      S = matlibre_score_fast(I);
%      S(6, 6) > 0      % le coin du carré est détecté
%
%   Voir aussi DETECTFASTFEATURES, DETECTBRISKFEATURES, DETECTORBFEATURES.
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    cercle = [0 -3; 1 -3; 2 -2; 3 -1; 3 0; 3 1; 2 2; 1 3; 0 3; ...
              -1 3; -2 2; -3 1; -3 0; -3 -1; -2 -2; -1 -3];
    [h, l] = size(I);
    etendue = padarray(I, [3 3], 'replicate');
    ecarts = zeros(h, l, 16);
    for k = 1:16
        decale = etendue((1:h) + 3 + cercle(k, 2), (1:l) + 3 + cercle(k, 1));
        ecarts(:, :, k) = decale - I;
    end
    clair = -inf(h, l);
    sombre = -inf(h, l);
    for depart = 1:16
        indices = mod(depart - 1 + (0:8), 16) + 1;
        arc = ecarts(:, :, indices);
        clair = max(clair, min(arc, [], 3));
        sombre = max(sombre, min(-arc, [], 3));
    end
    score = max(clair, sombre);
    score(score < 0) = 0;
    % Les trois pixels du bord n'ont pas de cercle complet dans l'image ;
    % le remplissage par répétition y fabriquerait des coins.
    score([1:3, end-2:end], :) = 0;
    score(:, [1:3, end-2:end]) = 0;
end
