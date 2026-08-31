function [gamma, pulsation] = hinfnorm(sys, tolerance)
%HINFNORM Norme H-infini d'un modèle stable.
%   G = HINFNORM(SYS) rend le plus grand gain que le modèle puisse donner
%   à un signal : le maximum, sur toutes les pulsations, de la plus grande
%   valeur singulière de la réponse fréquentielle. Pour un modèle
%   monovariable, c'est le sommet du diagramme de gain.
%
%   [G,W] = HINFNORM(SYS) rend aussi la pulsation où ce maximum est
%   atteint.
%
%   G = HINFNORM(SYS,TOL) demande une précision relative TOL ; par défaut
%   un millionième.
%
%   Un modèle instable n'a pas de norme H-infini : la fonction rend Inf.
%
%   La valeur n'est pas cherchée en balayant les fréquences — un balayage
%   rate les pics étroits. Elle vient du critère de Boyd, Balakrishnan et
%   Kabamba : le gain dépasse GAMMA si et seulement si la matrice
%   hamiltonienne associée a des valeurs propres sur l'axe imaginaire.
%   Ces valeurs propres donnent les pulsations où le gain vaut GAMMA ;
%   entre deux d'entre elles il vaut davantage, et l'on recommence. La
%   suite converge en quelques tours.
%
%   La valeur rendue est un gain réellement atteint, à la pulsation W :
%   SIGMA(SYS,W) la redonne exactement. Elle minore donc la norme vraie,
%   d'au plus TOL en relatif.
%
%   Exemple :
%      hinfnorm(tf(1, [1 0.1 1]))   % environ 10 : la résonance
%
%   Voir aussi SIGMA, NORM, H2NORM, FREQRESP.
    if nargin < 2 || isempty(tolerance)
        tolerance = 1e-6;
    end
    modele = ss(sys);
    A = modele.A; B = modele.B; C = modele.C; D = modele.D;
    n = size(A, 1);
    pulsation = 0;
    if n > 0 && max(real(eig(A))) >= -1e-12
        gamma = Inf;
        return
    end
    % Un modèle échantillonné n'a pas la même matrice hamiltonienne : on
    % le prend au balayage, raffiné autour du sommet.
    if modele.Ts ~= 0 || n == 0
        [gamma, pulsation] = parBalayage(modele, tolerance);
        return
    end

    % Borne basse : le gain statique, le gain à l'infini, et le sommet
    % d'un balayage grossier. La norme est au moins cela.
    w = logspace(-6, 6, 400);
    [gamma, k] = plusGrandGain(modele, w);
    pulsation = w(k);
    gammaD = max(svd(D));
    if gammaD > gamma
        gamma = gammaD;
        pulsation = Inf;
    end
    if gamma < 1e-300
        gamma = 0;
        pulsation = 0;
        return
    end

    for tour = 1:50
        essai = (1 + 2 * tolerance) * gamma;
        R = essai^2 * eye(size(D, 2)) - D' * D;
        if rcond(R) < eps
            break
        end
        Ri = inv(R);
        M = A + B * Ri * D' * C;
        H = [M, B * Ri * B'; -C' * (eye(size(D, 1)) + D * Ri * D') * C, -M'];
        valeurs = eig(H);
        % Les valeurs propres imaginaires : les pulsations où le gain vaut
        % exactement l'essai.
        surLAxe = abs(real(valeurs)) < 1e-8 * max(1, max(abs(valeurs)));
        pulsations = sort(abs(imag(valeurs(surLAxe & imag(valeurs) > 0))));
        if isempty(pulsations)
            break            % le gain ne monte jamais jusqu'à l'essai
        end
        % Entre deux traversées, le gain dépasse : on l'y mesure.
        milieux = zeros(1, max(numel(pulsations) - 1, 0));
        for j = 1:numel(pulsations) - 1
            milieux(j) = (pulsations(j) + pulsations(j+1)) / 2;
        end
        if isempty(milieux)
            break
        end
        [nouveau, j] = plusGrandGain(modele, milieux);
        if nouveau <= gamma * (1 + tolerance / 10)
            break
        end
        gamma = nouveau;
        pulsation = milieux(j);
    end
    % On rend le gain mesure, non un majorant : « [g,w] = hinfnorm(sys) »
    % doit verifier que le gain en w vaut bien g. Gonfler la valeur de la
    % tolerance rendait un nombre que le modele n'atteignait nulle part,
    % et faisait dépasser d'un millionième les bornes d'erreur que la
    % réduction de modèle garantit.
end

function [g, k] = plusGrandGain(sys, w)
%PLUSGRANDGAIN Plus grande valeur singulière sur une grille de pulsations.
    H = freqresp(sys, w);
    g = 0;
    k = 1;
    for j = 1:numel(w)
        if ndims(H) == 3
            valeur = max(svd(H(:, :, j)));
        else
            valeur = abs(H(j));
        end
        if valeur > g
            g = valeur;
            k = j;
        end
    end
end

function [gamma, pulsation] = parBalayage(sys, tolerance)
%PARBALAYAGE La norme cherchée sur une grille, raffinée autour du sommet.
    if sys.Ts > 0
        w = linspace(1e-6, pi / sys.Ts, 4000);
    else
        w = logspace(-6, 6, 4000);
    end
    [gamma, k] = plusGrandGain(sys, w);
    pulsation = w(k);
    a = w(max(k - 1, 1));
    b = w(min(k + 1, numel(w)));
    for tour = 1:80
        m1 = a + (b - a) / 3;
        m2 = b - (b - a) / 3;
        if plusGrandGain(sys, m1) < plusGrandGain(sys, m2)
            a = m1;
        else
            b = m2;
        end
        if b - a < tolerance * max(1, b)
            break
        end
    end
    pulsation = (a + b) / 2;
    gamma = max(gamma, plusGrandGain(sys, pulsation));
end
