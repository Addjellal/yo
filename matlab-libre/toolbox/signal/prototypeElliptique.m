function [z, p, k] = prototypeElliptique(n, rp, rs)
%PROTOTYPEELLIPTIQUE Pôles et zéros du prototype passe-bas de Cauer.
%   Le bord de bande passante est en oméga = 1, le bord de bande
%   atténuée en 1/k où k est la sélectivité tirée de l'équation du degré
%
%      N K'(k)/K(k) = K'(k1)/K(k1),    k1 = eps_p / eps_s.
%
%   Les zéros et les pôles s'écrivent alors avec les fonctions
%   elliptiques de Jacobi :
%
%      zeta_i = cd(u_i K, k),   z_i = j/(k zeta_i)
%      p_i    = j cd((u_i - j v0) K, k),   u_i = (2i-1)/N
%
%   et, pour un ordre impair, un pôle réel supplémentaire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Référence : les formules classiques de la conception elliptique,
%   telles qu'on les trouve dans la littérature ouverte sur les filtres
%   de Cauer.
    epsilonP = sqrt(10 ^ (rp / 10) - 1);
    epsilonS = sqrt(10 ^ (rs / 10) - 1);
    k1 = epsilonP / epsilonS;
    % Le rapport K'/K décroît de l'infini à zéro quand k va de 0 à 1 :
    % la dichotomie converge sans hypothèse supplémentaire.
    cible = rapportComplementaire(k1) / n;
    bas = 1e-12;
    haut = 1 - 1e-12;
    for iteration = 1:300
        milieu = (bas + haut) / 2;
        if rapportComplementaire(milieu) > cible
            bas = milieu;
        else
            haut = milieu;
        end
        if haut - bas < 1e-15, break, end
    end
    kMod = (bas + haut) / 2;
    m = kMod ^ 2;
    mComplement = 1 - m;
    K = ellipke(m);
    L = floor(n / 2);
    ui = (2 * (1:L) - 1) / n;
    zetaI = zeros(1, L);
    for i = 1:L
        [~, c, d] = ellipj(ui(i) * K, m);
        zetaI(i) = c / d;
    end
    zHaut = 1i ./ (kMod * zetaI);
    z = [zHaut(:); conj(zHaut(:))];
    % v0 : l'inverse de sn en argument imaginaire se ramène à celui de
    % sc pour le module complémentaire.
    k1Complement = 1 - k1 ^ 2;
    K1 = ellipke(k1 ^ 2);
    w = inverseSc(1 / epsilonP, k1Complement);
    v0 = w / (n * K1);
    p = zeros(0, 1);
    for i = 1:L
        cd = cdComplexe(ui(i) * K, -v0 * K, m, mComplement);
        pole = 1i * cd;
        p(end + 1, 1) = pole;         %#ok<AGROW>
        p(end + 1, 1) = conj(pole);   %#ok<AGROW>
    end
    if mod(n, 2) == 1
        [s1, c1, ~] = ellipj(v0 * K, mComplement);
        p(end + 1, 1) = -s1 / c1;     % pôle réel, négatif
    end
    k = 1;
end

function r = rapportComplementaire(kMod)
%RAPPORTCOMPLEMENTAIRE K'(k)/K(k), avec K' = K du module complémentaire.
    m = kMod ^ 2;
    r = ellipke(1 - m) / ellipke(m);
end

function w = inverseSc(cible, mComplement)
%INVERSESC Résout sn(w,m')/cn(w,m') = CIBLE sur ]0, K(m')[.
%   Le quotient croît de zéro à l'infini sur cet intervalle.
    Kp = ellipke(mComplement);
    bas = 0;
    haut = Kp * (1 - 1e-14);
    for iteration = 1:300
        milieu = (bas + haut) / 2;
        [s, c, ~] = ellipj(milieu, mComplement);
        if c == 0 || s / c < cible
            bas = milieu;
        else
            haut = milieu;
        end
        if haut - bas < 1e-15 * max(1, Kp), break, end
    end
    w = (bas + haut) / 2;
end

function valeur = cdComplexe(x, y, m, mComplement)
%CDCOMPLEXE cd(x + i y, k) par les formules d'addition à argument imaginaire.
%   cn et dn d'un argument complexe s'écrivent avec les fonctions réelles
%   de module k pour la partie réelle et de module complémentaire pour la
%   partie imaginaire ; leur dénominateur commun se simplifie dans le
%   quotient cd = cn/dn.
    [s, c, d] = ellipj(x, m);
    [s1, c1, d1] = ellipj(y, mComplement);
    numerateur = c * c1 - 1i * s * d * s1 * d1;
    denominateur = d * c1 * d1 - 1i * m * s * c * s1;
    valeur = numerateur / denominateur;
end
