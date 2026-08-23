function phat = betafit(x)
%BETAFIT Estimation des paramètres d'une loi bêta.
%   Le maximum de vraisemblance est cherché par NELDER-MEAD sur
%   BETALIKE, en partant de l'estimation par les moments.
    x = double(x(:));
    if any(x <= 0) || any(x >= 1)
        error('stats:betafit:BadData', 'Les données doivent être dans ]0,1[.');
    end
    m = mean(x);
    v = var(x);
    facteur = m * (1 - m) / v - 1;
    depart = [m * facteur, (1 - m) * facteur];
    if any(depart <= 0), depart = [1 1]; end
    % On optimise le logarithme des paramètres : ils restent positifs.
    but = @(t) betalike(exp(t), x);
    phat = exp(fminsearch(but, log(depart)));
    phat = phat(:)';
end
