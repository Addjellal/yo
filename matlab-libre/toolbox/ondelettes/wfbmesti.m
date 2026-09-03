function estimations = wfbmesti(x)
%WFBMESTI Estimation du paramètre de Hurst d'un mouvement fractionnaire.
%   H = WFBMESTI(X) rend trois estimations, dans un vecteur :
%     H(1)  par la variance des différences secondes discrètes
%     H(2)  par la pente du logarithme de la variance des détails
%           d'ondelettes en fonction du niveau
%     H(3)  par la même pente, pondérée par le nombre de coefficients
%           de chaque niveau
%
%   Les trois reposent sur la même propriété : le mouvement
%   fractionnaire est auto-similaire, si bien que ce qu'on mesure à
%   l'échelle 2^j croît comme 2^(j(2H+1)). Elles ne se trompent pas de la
%   même façon, ce qui rend leur écart instructif.
%
%   Sur quatre mille points, comptez quelques centièmes d'erreur au
%   dessus de H = 0,5, davantage en dessous : les estimations par
%   ondelettes sous-estiment alors d'environ cinq centièmes, la relation
%   d'échelle ne s'établissant qu'aux niveaux assez grossiers.
%
%   Exemple :
%      x = wfbm(0.7, 4096);
%      h = wfbmesti(x);
%      abs(h - 0.7) < 0.1             % vrai, aux trois
%
%   Voir aussi WFBM, MODWTVAR, WAVEDEC.
    x = double(x(:)).';
    n = numel(x);
    if n < 16
        error('wavelet:wfbmesti:Longueur', 'Le signal est trop court.');
    end
    estimations = zeros(1, 3);
    % 1. Différences secondes : pour un mouvement fractionnaire, la
    % variance des différences d'ordre deux à pas k vaut c k^(2H).
    pas = 1:min(8, floor(n / 8));
    logPas = log(pas);
    logVariance = zeros(size(pas));
    for j = 1:numel(pas)
        k = pas(j);
        difference = x(1 + 2 * k:end) - 2 * x(1 + k:end - k) + x(1:end - 2 * k);
        logVariance(j) = log(max(var(difference), realmin));
    end
    pente = polyfit(logPas, logVariance, 1);
    estimations(1) = min(max(pente(1) / 2, 0), 1);
    % 2 et 3. Variance des détails d'ondelettes : elle croît comme
    % 2^(j(2H+1)) d'un niveau au suivant.
    niveauMax = min(floor(log2(n)) - 3, 8);
    if niveauMax < 2
        estimations(2:3) = estimations(1);
        return
    end
    % L'analyse prolonge le signal par périodicité ; un mouvement
    % fractionnaire, lui, ne revient pas à son point de départ, et la
    % marche entre les deux bouts polluerait tous les niveaux — la pente
    % s'en trouvait écrasée, et H sous-estimé de moitié aux grandes
    % valeurs. On retire donc d'abord la droite qui joint les deux
    % extrémités : elle ne change pas l'auto-similarité, et referme le
    % signal sur lui-même.
    droite = x(1) + (x(end) - x(1)) * (0:(n - 1)) / max(n - 1, 1);
    [C, L] = wavedec(x - droite, niveauMax, 'db4');
    % Le premier niveau porte la discrétisation plutôt que l'échelle, et
    % les deux derniers comptent trop peu de coefficients : la régression
    % ne garde que les octaves du milieu. C'est la précaution d'usage de
    % l'estimateur d'Abry et Veitch.
    if niveauMax >= 5
        niveaux = 2:(niveauMax - 2);
    else
        niveaux = 1:niveauMax;
    end
    logVarianceDetail = zeros(1, numel(niveaux));
    effectifs = zeros(1, numel(niveaux));
    for indice = 1:numel(niveaux)
        j = niveaux(indice);
        d = detcoef(C, L, j);
        % Les premiers coefficients de chaque niveau dépendent des deux
        % bouts du signal : on les écarte.
        marge = min(4, floor(numel(d) / 4));
        d = d((marge + 1):end);
        logVarianceDetail(indice) = log2(max(mean(d .^ 2), realmin));
        effectifs(indice) = numel(d);
    end
    penteSimple = polyfit(niveaux, logVarianceDetail, 1);
    estimations(2) = min(max((penteSimple(1) - 1) / 2, 0), 1);
    % Pondération par le nombre de coefficients : les niveaux fins
    % comptent davantage, leur variance étant mieux estimée.
    poids = effectifs / sum(effectifs);
    moyenneNiveau = sum(poids .* niveaux);
    moyenneValeur = sum(poids .* logVarianceDetail);
    covariance = sum(poids .* (niveaux - moyenneNiveau) .* (logVarianceDetail - moyenneValeur));
    variance = sum(poids .* (niveaux - moyenneNiveau) .^ 2);
    if variance > 0
        estimations(3) = min(max((covariance / variance - 1) / 2, 0), 1);
    else
        estimations(3) = estimations(2);
    end
end
