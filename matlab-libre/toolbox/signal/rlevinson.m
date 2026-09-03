function [r, u, kr, e] = rlevinson(a, efinal)
%RLEVINSON Levinson-Durbin à l'envers.
%   R = RLEVINSON(A,EFINAL) rend l'autocorrélation dont LEVINSON aurait
%   tiré le polynôme de prédiction A et l'erreur finale EFINAL. C'est le
%   chemin inverse de LEVINSON : il rend au modèle son autocorrélation.
%
%   [R,U,KR,E] = RLEVINSON(A,EFINAL) rend en outre la matrice U des
%   polynômes de prédiction de tous les ordres, les coefficients de
%   réflexion KR et les erreurs de prédiction E de chaque ordre.
%
%   Exemple :
%      r = [5 4 3 2]';
%      [a, e] = levinson(r, 3);
%      max(abs(rlevinson(a, e) - r))     % nul aux arrondis près
%
%   Voir aussi LEVINSON, POLY2RC, RC2POLY, POLY2AC, AC2POLY.
    a = double(a(:));
    if a(1) == 0
        error('signal:rlevinson:NullLeading', 'A(1) ne peut pas être nul.');
    end
    a = a / a(1);
    p = numel(a) - 1;
    if p < 1
        r = efinal;
        u = 1;
        kr = zeros(0, 1);
        e = efinal;
        return;
    end
    % Descente de l'ordre p à l'ordre 1 : chaque étape retire le dernier
    % coefficient de réflexion, comme la récurrence de Levinson à
    % l'envers.
    u = zeros(p + 1, p + 1);
    u(:, p + 1) = a;
    kr = zeros(p, 1);
    e = zeros(p + 1, 1);
    e(p + 1) = efinal;
    for ordre = p:-1:1
        courant = u(1:(ordre + 1), ordre + 1);
        k = courant(end);
        % Le signe est celui de POLY2RC : les deux fonctions doivent
        % rendre les mêmes coefficients de réflexion pour un même
        % polynôme.
        kr(ordre) = k;
        if abs(1 - k ^ 2) < eps
            error('signal:rlevinson:Singular', ...
                  'Un coefficient de réflexion vaut 1 : le modèle n''est pas régulier.');
        end
        precedent = (courant(1:ordre) - k * conj(courant(ordre + 1:-1:2))) / (1 - k ^ 2);
        u(1:ordre, ordre) = precedent;
        e(ordre) = e(ordre + 1) / (1 - k ^ 2);
    end
    % L'autocorrélation se reconstruit par les mêmes équations normales :
    % r(k) = -somme a_j r(k-j), l'ordre 0 valant l'erreur de l'ordre 0.
    r = zeros(p + 1, 1);
    r(1) = e(1);
    for ordre = 1:p
        coefficients = u(1:(ordre + 1), ordre + 1);
        somme = 0;
        for j = 2:(ordre + 1)
            somme = somme + coefficients(j) * r(ordre - j + 2);
        end
        r(ordre + 1) = -somme;
    end
    e = e(:);
end
