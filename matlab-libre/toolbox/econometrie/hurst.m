function h = hurst(x)
%HURST Exposant de Hurst estimé par l'analyse R/S.
%   H = HURST(X) estime l'exposant de Hurst par l'analyse de l'étendue
%   remise à l'échelle. La série est découpée en blocs de tailles
%   croissantes ; sur chaque bloc on centre, on cumule, on prend l'étendue
%   du cumul et on la divise par l'écart type du bloc. La pente de log(R/S)
%   contre log(taille) est H.
%
%   X est la série des accroissements, non la trajectoire cumulée. Un demi
%   signale des accroissements indépendants — la marche aléatoire, dont
%   l'étendue croît comme la racine du temps. Au-dessus, la série
%   persiste : une hausse tend à être suivie d'une hausse, et les
%   tendances se prolongent. En dessous, elle est antipersistante et
%   revient vers sa moyenne. Passer par mégarde la trajectoire déjà
%   cumulée rend H proche de un, quelle que soit la série.
%
%   L'estimateur est biaisé vers le haut sur les séries courtes : du bruit
%   blanc de cinq cents points rend couramment 0,6. Une simple tendance
%   déterministe suffit aussi à faire monter H sans qu'il y ait la moindre
%   mémoire longue, d'où la nécessité de détendancer avant d'interpréter.
%
%   Exemple :
%      rng(1);
%      h = hurst(randn(512, 1));
%
%   Voir aussi ARSIM, AUTOCORR, ADFTEST.
    x = x(:);
    n = numel(x);
    tailles = unique(round(logspace(log10(8), log10(floor(n/2)), 10)));
    logTailles = [];
    logRS = [];
    for t = 1:numel(tailles)
        m = tailles(t);
        blocs = floor(n / m);
        if blocs < 1
            continue;
        end
        valeurs = [];
        for b = 1:blocs
            segment = x((b-1)*m + 1 : b*m);
            ecart = segment - mean(segment);
            cumule = cumsum(ecart);
            R = max(cumule) - min(cumule);
            S = std(segment);
            if S > 0
                valeurs(end+1) = R / S;
            end
        end
        if ~isempty(valeurs)
            logTailles(end+1) = log(m);
            logRS(end+1) = log(mean(valeurs));
        end
    end
    p = polyfit(logTailles, logRS, 1);
    h = p(1);
end
