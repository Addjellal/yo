function [oip3, fondamentaux, intermodulations] = toi(x, fs)
%TOI Point d'interception d'ordre trois.
%   OIP3 = TOI(X,FS) mesure, sur un signal à deux tons, le niveau
%   extrapolé où les produits d'intermodulation d'ordre trois
%   rejoindraient les fondamentaux. Le résultat est en décibels par
%   rapport à la puissance unité.
%
%   [OIP3,F,FIM] = TOI(...) rend aussi les fréquences des deux tons et
%   celles des produits 2f1-f2 et 2f2-f1.
%
%   Exemple :
%      t = (0:4095)'/1e4;
%      x = cos(2*pi*1000*t) + cos(2*pi*1100*t) + 0.001*cos(2*pi*900*t) ...
%          + 0.001*cos(2*pi*1200*t);
%      toi(x, 1e4)
    if nargin < 2 || isempty(fs), fs = 1; end
    [S, f] = signalSpectrePuissance(x, fs);
    [~, plageContinue] = signalLobe(S, 1);
    S(plageContinue) = 0;
    travail = S;
    [~, k1] = max(travail);
    [p1, plage1] = signalLobe(travail, k1);
    travail(plage1) = 0;
    [~, k2] = max(travail);
    [p2, plage2] = signalLobe(travail, k2);
    travail(plage2) = 0;
    if k1 > k2
        [k1, k2] = deal(k2, k1);
        [p1, p2] = deal(p2, p1);
    end
    fondamentaux = [f(k1); f(k2)];
    % Les produits d'ordre trois se placent symétriquement autour des
    % deux tons, à un écart égal à leur séparation.
    ecart = k2 - k1;
    kBas = k1 - ecart;
    kHaut = k2 + ecart;
    puissances = [];
    intermodulations = [];
    for k = [kBas kHaut]
        if k >= 1 && k <= numel(S)
            ks = signalSommet(S, k, 3);
            puissances(end + 1, 1) = signalLobe(S, ks);     %#ok<AGROW>
            intermodulations(end + 1, 1) = f(ks);           %#ok<AGROW>
        end
    end
    if isempty(puissances) || all(puissances <= 0)
        oip3 = Inf;
        return
    end
    puissanceFondamental = 10 * log10((p1 + p2) / 2);
    puissanceIM = 10 * log10(mean(puissances));
    % Les produits d'ordre trois croissent trois fois plus vite que les
    % fondamentaux : l'interception est à la moitié de l'écart au-dessus.
    oip3 = puissanceFondamental + (puissanceFondamental - puissanceIM) / 2;
end
