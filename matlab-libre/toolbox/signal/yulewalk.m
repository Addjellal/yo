function [b, a] = yulewalk(n, f, m)
%YULEWALK Filtre récursif ajusté sur un gabarit de module.
%   [B,A] = YULEWALK(N,F,M) conçoit un filtre d'ordre N dont le module
%   suit la courbe donnée par les points (F,M). F va de 0 à 1, 1 valant
%   la moitié de la fréquence d'échantillonnage, et doit croître ; M
%   donne le module visé. Contrairement à FIRPM, la phase n'est pas
%   imposée : seul le module compte.
%
%   La méthode est celle de Friedlander et Porat : le dénominateur sort
%   des équations de Yule-Walker modifiées, écrites sur l'autocorrélation
%   déduite du gabarit ; le numérateur vient ensuite d'une factorisation
%   spectrale à phase minimale du spectre résiduel.
%
%   Exemple :
%      [b, a] = yulewalk(8, [0 0.6 0.6 1], [1 1 0 0]);
%
%   Voir aussi FIRPM, FIR2, BUTTER.
    f = double(f(:))';
    m = double(m(:))';
    if numel(f) ~= numel(m)
        error('signal:yulewalk:BadSpec', 'F et M doivent avoir la même longueur.');
    end
    if f(1) ~= 0 || abs(f(end) - 1) > 1e-12
        error('signal:yulewalk:BadEdges', 'F doit aller de 0 à 1.');
    end
    npt = 512;
    grille = (0:npt)' / npt;
    % Interpolation linéaire par morceaux, les points doubles marquant
    % les sauts du gabarit. Les sauts sont adoucis sur quelques points :
    % un mur parfait n'est le module d'aucun filtre rationnel, et
    % l'ajustement partirait de travers. MATLAB adoucit de même, sur
    % npt/25 points de recouvrement.
    module = interpolerGabarit(f, m, grille);
    module = adoucirSauts(module, f, m, grille, max(1, round(npt / 25)));
    % Seul le module est imposé : on lui associe la phase minimale, la
    % seule qui rende le filtre causal et stable sans retard inutile.
    phase = phaseMinimale(module);
    cible = module .* exp(1i * phase);
    omega = pi * grille;
    [b, a] = invfreqz(cible, omega, n, n, [], 40);
    % Repli des pôles instables : le module est inchangé, la phase non.
    poles = roots(a);
    dehors = abs(poles) > 1;
    if any(dehors)
        poles(dehors) = 1 ./ conj(poles(dehors));
        gain = a(1);
        a = real(poly(poles)) * gain;
        a = a / a(1);
        [b, a] = ajusterNumerateur(cible, omega, a, n);
    end
end

function [b, a] = ajusterNumerateur(cible, omega, a, n)
%AJUSTERNUMERATEUR Recalcule le numérateur, le dénominateur étant fixé.
    z = exp(-1i * omega);
    reponseA = polyval(fliplr(a), z);
    M = zeros(numel(omega), n + 1);
    for i = 0:n
        M(:, i + 1) = z .^ i;
    end
    v = cible .* reponseA;
    b = ([real(M); imag(M)] \ [real(v); imag(v)])';
end

function phase = phaseMinimale(module)
%PHASEMINIMALE Phase associée à un module, par le cepstre.
%   Le logarithme du module et la phase minimale forment une paire de
%   Hilbert : replier le cepstre sur les temps positifs revient à
%   prendre cette transformée.
    module = module(:);
    npt = numel(module) - 1;
    complet = [module; flipud(module(2:end-1))];
    complet(complet < 1e-10) = 1e-10;
    cepstre = real(ifft(log(complet)));
    longueur = numel(cepstre);
    poids = zeros(longueur, 1);
    poids(1) = 1;
    poids(2:longueur/2) = 2;
    poids(longueur/2 + 1) = 1;
    logarithme = fft(poids .* cepstre);
    phase = imag(logarithme(1:npt + 1));
end

function module = adoucirSauts(module, f, m, grille, recouvrement)
%ADOUCIRSAUTS Remplace chaque discontinuité par une transition en cosinus.
    npt = numel(grille) - 1;
    for k = 1:numel(f) - 1
        if f(k + 1) ~= f(k) || m(k + 1) == m(k)
            continue
        end
        centre = round(f(k) * npt) + 1;
        debut = max(1, centre - recouvrement);
        fin = min(npt + 1, centre + recouvrement);
        if fin <= debut
            continue
        end
        t = (0:fin - debut)' / (fin - debut);
        fondu = (1 - cos(pi * t)) / 2;
        module(debut:fin) = m(k) + (m(k + 1) - m(k)) * fondu;
    end
end

function module = interpolerGabarit(f, m, grille)
%INTERPOLERGABARIT Gabarit continu par morceaux, sauts compris.
    module = zeros(size(grille));
    for k = 1:numel(grille)
        x = grille(k);
        indice = find(f <= x, 1, 'last');
        if isempty(indice), indice = 1; end
        if indice >= numel(f)
            module(k) = m(end);
        elseif f(indice + 1) == f(indice)
            module(k) = m(indice + 1);
        else
            t = (x - f(indice)) / (f(indice + 1) - f(indice));
            module(k) = m(indice) + t * (m(indice + 1) - m(indice));
        end
    end
end
