function [proportion, H] = normspec(bornes, mu, sigma, region)
%NORMSPEC Densité normale, avec la région entre deux tolérances.
%   NORMSPEC(BORNES) trace la densité de la loi normale centrée réduite
%   et colorie la partie qui tombe entre les deux tolérances de BORNES.
%   Une borne infinie — ou NaN — laisse ce côté ouvert.
%
%   NORMSPEC(BORNES,MU,SIGMA) emploie la loi de moyenne MU et d'écart
%   type SIGMA.
%
%   P = NORMSPEC(...) rend la probabilité de la région coloriée : c'est
%   la proportion de la production qui respecterait les tolérances si le
%   procédé suivait cette loi.
%
%   NORMSPEC(BORNES,MU,SIGMA,REGION) choisit ce qui est colorié :
%   'inside' (défaut) ou 'outside', auquel cas P est la proportion de
%   rebuts.
%
%   [P,H] = NORMSPEC(...) rend les poignées du tracé.
%
%   C'est l'outil du contrôle de fabrication : on y lit d'un coup d'œil
%   si les tolérances laissent assez de marge au procédé.
%
%   Exemples :
%      normspec([-2 2])                    % 0.9545 : deux ecarts types
%      normspec([9.9 10.1], 10, 0.05)      % un procede bien centre
%      normspec([9.9 Inf], 10, 0.05)       % une seule tolerance
%      normspec([-1 1], 0, 1, 'outside')   % la proportion de rebuts
%
%   Voir aussi NORMCDF, NORMPDF, HISTFIT, CAPABILITY, BOXPLOT.
    if nargin < 2 || isempty(mu)
        mu = 0;
    end
    if nargin < 3 || isempty(sigma)
        sigma = 1;
    end
    if nargin < 4 || isempty(region)
        region = 'inside';
    end
    bornes = bornes(:)';
    if numel(bornes) ~= 2
        error('stats:normspec:BadSpecs', 'SPECS must have two elements.');
    end
    bas = bornes(1);
    haut = bornes(2);
    if isnan(bas)
        bas = -Inf;
    end
    if isnan(haut)
        haut = Inf;
    end
    dedans = normcdf(haut, mu, sigma) - normcdf(bas, mu, sigma);
    if strcmpi(char(region), 'outside')
        proportion = 1 - dedans;
    else
        proportion = dedans;
    end

    gauche = mu - 4 * sigma;
    droite = mu + 4 * sigma;
    if isfinite(bas)
        gauche = min(gauche, bas - sigma);
    end
    if isfinite(haut)
        droite = max(droite, haut + sigma);
    end
    t = linspace(gauche, droite, 400);
    densite = normpdf(t, mu, sigma);
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    H = plot(t, densite, 'b', 'LineWidth', 1.5);
    hold('on');
    if strcmpi(char(region), 'outside')
        garde = (t < bas) | (t > haut);
    else
        garde = (t >= bas) & (t <= haut);
    end
    if any(garde)
        u = t(garde);
        v = densite(garde);
        H(end + 1) = fill([u(1), u, u(end)], [0, v, 0], 'FaceColor', [0.6 0.8 1]);
    end
    if isfinite(bas)
        H(end + 1) = xline(bas, 'r--');
    end
    if isfinite(haut)
        H(end + 1) = xline(haut, 'r--');
    end
    if ~aEffacer
        hold('off');
    end
    xlabel('valeur');
    ylabel('densite');
    title(sprintf('Probabilite = %.4f', proportion));
    if nargout == 0
        clear proportion;
    end
end
