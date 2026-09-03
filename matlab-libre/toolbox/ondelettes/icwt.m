function x = icwt(coefficients, echelles, nom, delta)
%ICWT Transformée en ondelettes continue inverse.
%   X = ICWT(C,ECHELLES,NOM) reconstruit le signal à partir des
%   coefficients que rend CWT, par la formule de reconstruction à une
%   seule somme :
%
%      X(b) = (1/K) somme_a Re C(a,b) da / a^(3/2)
%
%   où da est le pas local entre échelles : la somme approche ainsi
%   l'intégrale, que les échelles soient réparties linéairement ou par
%   octaves.
%
%   K n'est pas une constante tabulée, ni même une constante : analyse
%   puis somme forment un filtre, qu'on mesure en transformant une
%   impulsion, et qu'on inverse dans la bande où il a du gain. Diviser
%   par une seule constante laisserait plusieurs dixièmes d'erreur, le
%   gain n'étant pas plat ; inverser le filtre les efface.
%
%   Ce que les échelles ne couvrent pas n'est pas reconstruit : la
%   composante continue et tout ce qui sort de la bande sont perdus, et
%   c'est fidèle à ce que la transformée a réellement gardé. Les bords
%   restent approchés, la transformée continue y étant tronquée.
%
%   X = ICWT(...,'Constante') emploie au lieu de cela le gain moyen dans
%   la bande, comme la formule de reconstruction d'usage : plus grossier,
%   mais sans repli possible.
%
%   Exemple :
%      t = (0:511) / 512;
%      x = sin(2 * pi * 8 * t);
%      echelles = 2 .^ (0:0.25:6);
%      y = icwt(cwt(x, echelles, 'morl'), echelles, 'morl');
%      norm(y - x) / norm(x)          % quelques centièmes
%
%   Voir aussi CWT, CENTFRQ, SCAL2FRQ.
    if nargin < 3 || isempty(nom), nom = 'mexh'; end
    parConstante = false;
    if nargin >= 4 && (ischar(delta) || isstring(delta))
        parConstante = strncmpi(char(delta), 'const', 5);
    end
    echelles = double(echelles(:));
    if size(coefficients, 1) ~= numel(echelles)
        error('wavelet:icwt:Tailles', ...
              'Il faut une ligne de coefficients par échelle.');
    end
    poids = pasLocal(echelles) ./ (echelles .^ 1.5);
    brut = sum(real(coefficients) .* poids, 1);
    n = size(coefficients, 2);
    [noyau, milieu] = noyauDuBanc(n, echelles, poids, nom);
    if max(abs(noyau)) == 0
        error('wavelet:icwt:Constante', ...
              ['Le filtre de reconstruction est nul : les échelles ' ...
               'demandées ne couvrent pas la bande de l''ondelette.']);
    end
    if parConstante
        x = brut / gainMoyen(noyau, echelles, nom);
        return
    end
    % Inversion du filtre, là où il a du gain. Le noyau est ramené à
    % l'origine pour que sa transformée soit à phase nulle.
    reponse = fft(circshift(noyau, [0, -(milieu - 1)]));
    module = abs(reponse);
    garde = module >= 0.2 * max(module);
    spectre = fft(brut);
    resultat = zeros(1, n);
    resultat(garde) = spectre(garde) ./ reponse(garde);
    x = real(ifft(resultat));
end

function [noyau, milieu] = noyauDuBanc(n, echelles, poids, nom)
%NOYAUDUBANC Le filtre que forment l'analyse et la somme.
%   Il se lit sur une impulsion posée loin des bords, là où la
%   transformée continue n'est pas tronquée.
    impulsion = zeros(1, n);
    milieu = floor(n / 2) + 1;
    impulsion(milieu) = 1;
    noyau = sum(real(cwt(impulsion, echelles, nom)) .* poids, 1);
end

function gain = gainMoyen(noyau, echelles, nom)
%GAINMOYEN Gain du noyau, moyenné sur la bande que les échelles couvrent.
    n = numel(noyau);
    module = abs(fft(noyau));
    frequences = (0:(n - 1)) / n;
    centre = centfrq(nom);
    basse = centre / max(echelles);
    haute = min(centre / min(echelles), 0.5);
    bande = frequences >= basse & frequences <= haute;
    if ~any(bande)
        bande = frequences > 0 & frequences <= 0.5;
    end
    gain = mean(module(bande));
end

function da = pasLocal(echelles)
%PASLOCAL Le pas que chaque échelle représente dans l'intégrale.
%   Règle du trapèze : une échelle intérieure vaut la demi-distance à ses
%   deux voisines, une échelle de bord la distance à son unique voisine.
    n = numel(echelles);
    if n == 1
        da = 1;
        return
    end
    da = zeros(n, 1);
    da(1) = echelles(2) - echelles(1);
    da(n) = echelles(n) - echelles(n - 1);
    for k = 2:(n - 1)
        da(k) = (echelles(k + 1) - echelles(k - 1)) / 2;
    end
end
