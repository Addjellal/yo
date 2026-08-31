function p = matlibre_probabilite_suites(suites, n1, n0)
%MATLIBRE_PROBABILITE_SUITES Probabilité exacte du test des suites.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Le nombre de suites d'une permutation au hasard de N1 signes plus et
%   N0 signes moins a une loi connue :
%
%      P(R = 2k)   = 2 C(n1-1,k-1) C(n0-1,k-1) / C(n1+n0, n1)
%      P(R = 2k+1) = [C(n1-1,k) C(n0-1,k-1) + C(n1-1,k-1) C(n0-1,k)]
%                    / C(n1+n0, n1)
%
%   La fonction rend la probabilité bilatérale : deux fois la queue la
%   plus petite, plafonnée à un.
    n = n1 + n0;
    maximum = 2 * min(n1, n0) + double(n1 ~= n0);
    lois = zeros(1, maximum + 1);
    logTotal = gammaln(n + 1) - gammaln(n1 + 1) - gammaln(n0 + 1);
    for r = 2:maximum
        if mod(r, 2) == 0
            k = r / 2;
            if k <= n1 && k <= n0
                lois(r + 1) = 2 * exp(logCombinaison(n1 - 1, k - 1) + ...
                                      logCombinaison(n0 - 1, k - 1) - logTotal);
            end
        else
            k = (r - 1) / 2;
            terme = 0;
            if k <= n1 - 1 && k >= 1 && k <= n0
                terme = terme + exp(logCombinaison(n1 - 1, k) + ...
                                    logCombinaison(n0 - 1, k - 1) - logTotal);
            end
            if k >= 1 && k <= n1 && k <= n0 - 1
                terme = terme + exp(logCombinaison(n1 - 1, k - 1) + ...
                                    logCombinaison(n0 - 1, k) - logTotal);
            end
            lois(r + 1) = terme;
        end
    end
    if suites < 2 || suites > maximum
        p = 1;
        return;
    end
    basse = sum(lois(1:suites + 1));
    haute = sum(lois(suites + 1:end));
    p = min(1, 2 * min(basse, haute));
end

function c = logCombinaison(n, k)
%LOGCOMBINAISON Logarithme du coefficient binomial, nul hors du domaine.
    if k < 0 || k > n || n < 0
        c = -Inf;
        return;
    end
    c = gammaln(n + 1) - gammaln(k + 1) - gammaln(n - k + 1);
end
