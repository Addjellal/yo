function [ber, moyenne] = semianalytic(emis, recu, modulation, M, surechantillonnage, ...
                                       numerateur, denominateur, EbNodB)
%SEMIANALYTIC Taux d'erreur par la méthode semi-analytique.
%   BER = SEMIANALYTIC(TX,RX,'psk'|'qam'|'pam',M,N,NUM,DEN,EBNO) estime
%   le taux d'erreur binaire d'une liaison dont on connaît le signal
%   émis TX et le signal reçu sans bruit RX. N est le facteur de
%   surechantillonnage, NUM et DEN les coefficients du filtre de
%   réception, EBNO les rapports signal sur bruit voulus en décibels.
%
%   La méthode ne simule pas le bruit : elle le prend en compte
%   exactement. Le signal reçu sans bruit est déterministe, et la
%   probabilité d'erreur de chaque symbole se calcule alors par la queue
%   d'une gaussienne. Cent symboles suffisent là où une simulation en
%   demanderait des millions pour mesurer un taux de 1e-8 — c'est tout
%   l'intérêt.
%
%   En contrepartie, elle demande que le bruit soit gaussien et additif,
%   ajouté après toute non-linéarité : un amplificateur saturé la met en
%   défaut.
%
%   Le signal reçu est ramené à une énergie moyenne d'un avant le calcul,
%   le rapport signal sur bruit étant défini à la réception : une
%   atténuation uniforme ne change donc rien au résultat, alors qu'une
%   distorsion — de l'interférence entre symboles, par exemple — le
%   dégrade.
%
%   [BER,MOYENNE] = SEMIANALYTIC(...) rend aussi l'énergie moyenne des
%   symboles reçus, qui sert de référence.
%
%   Exemple :
%      tx = pskmod(randi([0 1], 200, 1), 2);
%      rx = tx;                       % canal parfait
%      ber = semianalytic(tx, rx, 'psk', 2, 1, 1, 1, 0:6);
%      max(abs(ber - berawgn(0:6, 'psk', 2)))   % négligeable
%
%   Voir aussi BERAWGN, BERCODING, BITERR, BERCONFINT.
    if nargin < 5 || isempty(surechantillonnage), surechantillonnage = 1; end
    if nargin < 6 || isempty(numerateur), numerateur = 1; end
    if nargin < 7 || isempty(denominateur), denominateur = 1; end
    if nargin < 8 || isempty(EbNodB), EbNodB = 0:10; end
    emis = double(emis(:));
    recu = double(recu(:));
    modulation = lower(char(modulation));
    if ~any(strcmp(modulation, {'psk', 'qam', 'pam'}))
        error('comm:semianalytic:Modulation', ...
              'La modulation doit être ''psk'', ''qam'' ou ''pam''.');
    end
    % Le filtre de réception, puis l'échantillonnage au rythme symbole.
    if ~isequal(numerateur, 1) || ~isequal(denominateur, 1)
        recu = filter(numerateur, denominateur, recu);
    end
    if surechantillonnage > 1
        recu = recu(1:surechantillonnage:end);
    end
    n = min(numel(emis), numel(recu));
    emis = emis(1:n);
    recu = recu(1:n);
    if n < 1
        error('comm:semianalytic:Vide', 'Il faut au moins un symbole.');
    end
    moyenne = mean(abs(recu) .^ 2);
    if moyenne <= 0
        error('comm:semianalytic:Nul', 'Le signal reçu est nul.');
    end
    k = log2(M);
    EbNo = 10 .^ (double(EbNodB(:)).' / 10);
    % L'écart type du bruit par dimension, une fois le signal ramené à
    % une énergie moyenne d'un.
    recuNormalise = recu / sqrt(moyenne);
    emisNormalise = emis / sqrt(mean(abs(emis) .^ 2));
    ber = zeros(size(EbNo));
    for j = 1:numel(EbNo)
        sigma = sqrt(1 / (2 * k * EbNo(j)));
        total = 0;
        for s = 1:n
            total = total + matlibre_erreur_symbole(recuNormalise(s), ...
                emisNormalise(s), modulation, M, sigma);
        end
        % Codage de Gray : une erreur de symbole entre voisins ne fausse
        % qu'un bit.
        ber(j) = total / (n * k);
    end
    ber = reshape(ber, size(EbNodB));
end

function p = matlibre_erreur_symbole(recu, emis, modulation, M, sigma)
%MATLIBRE_ERREUR_SYMBOLE Probabilité que le bruit fasse sortir un symbole
%   de sa région de décision.
%   La distance à la frontière la plus proche commande tout : la
%   probabilité est la queue gaussienne au-delà de cette distance,
%   comptée une fois par frontière voisine.
    switch modulation
        case 'psk'
            if M == 2
                distance = real(recu * conj(emis)) / max(abs(emis), eps);
                p = 0.5 * erfc(distance / (sigma * sqrt(2)));
                return
            end
            % La frontière est à un demi-secteur de part et d'autre.
            phase = angle(recu) - angle(emis);
            phase = mod(phase + pi, 2 * pi) - pi;
            rayon = abs(recu);
            demiSecteur = pi / M;
            gauche = rayon * sin(demiSecteur - phase);
            droite = rayon * sin(demiSecteur + phase);
            p = 0.5 * erfc(gauche / (sigma * sqrt(2))) + ...
                0.5 * erfc(droite / (sigma * sqrt(2)));
        case {'qam', 'pam'}
            if strcmp(modulation, 'pam')
                niveaux = M;
                pas = 2 / (niveaux - 1) * sqrt(3 / (M ^ 2 - 1)) * (niveaux - 1) / 2;
                pas = matlibre_pas_pam(M);
                distance = abs(real(recu) - real(emis));
                marge = pas / 2 - distance;
                p = 0.5 * erfc(max(marge, -pas) / (sigma * sqrt(2)));
                return
            end
            pas = matlibre_pas_qam(M);
            margeI = pas / 2 - abs(real(recu) - real(emis));
            margeQ = pas / 2 - abs(imag(recu) - imag(emis));
            p = 0.5 * erfc(margeI / (sigma * sqrt(2))) + ...
                0.5 * erfc(margeQ / (sigma * sqrt(2)));
    end
    p = min(p, 1);
end

function pas = matlibre_pas_pam(M)
%MATLIBRE_PAS_PAM Écart entre deux points voisins, énergie moyenne un.
    niveaux = (-(M - 1)):2:(M - 1);
    energie = mean(niveaux .^ 2);
    pas = 2 / sqrt(energie);
end

function pas = matlibre_pas_qam(M)
%MATLIBRE_PAS_QAM Écart entre deux points voisins, énergie moyenne un.
    cote = round(sqrt(M));
    niveaux = (-(cote - 1)):2:(cote - 1);
    [X, Y] = meshgrid(niveaux, niveaux);
    energie = mean(X(:) .^ 2 + Y(:) .^ 2);
    pas = 2 / sqrt(energie);
end
