function [seuil, genre, garderApproximation, critere] = ddencmp(but, transformee, x)
%DDENCMP Réglages par défaut du débruitage ou de la compression.
%   [THR,SORH,KEEPAPP] = DDENCMP('den','wv',X) rend le seuil universel de
%   Donoho et Johnstone mis à l'échelle du bruit estimé, le seuillage
%   doux, et l'ordre de garder l'approximation. 'cmp' vise la
%   compression : le seuillage y est dur et le seuil plus bas.
%
%   [THR,SORH,KEEPAPP,CRIT] = DDENCMP('den','wp',X) donne les réglages
%   pour une décomposition en paquets d'ondelettes ; CRIT nomme alors le
%   critère d'entropie, et le seuil tient compte du nombre de bases que
%   la recherche du meilleur arbre explore.
%
%   Le bruit est estimé par l'écart médian absolu des détails du premier
%   niveau, divisé par 0.6745 : c'est l'estimateur robuste standard, qui
%   rend l'écart type d'une gaussienne.
%
%   Exemple :
%      [thr, sorh, keepapp] = ddencmp('den', 'wv', randn(1, 256));
%
%   Voir aussi WDENCMP, THSELECT, WNOISEST.
    if nargin < 2 || isempty(transformee), transformee = 'wv'; end
    but = lower(char(but));
    transformee = lower(char(transformee));
    x = double(x);
    x = x(:)';
    n = numel(x);
    [C, L] = wavedec(x, 1, 'db1');
    sigma = wnoisest(C, L, 1);
    paquets = strncmp(transformee, 'wp', 2);
    garderApproximation = 1;
    critere = '';
    if strncmp(but, 'den', 3)
        if paquets
            % La recherche du meilleur arbre visite de l'ordre de
            % n*log2(n) bases : le seuil universel est corrigé d'autant.
            seuil = sigma * sqrt(2 * log(n * log(n) / log(2)));
            genre = 'h';
            critere = 'sure';
        else
            seuil = sigma * sqrt(2 * log(n));
            genre = 's';
        end
    else
        seuil = median(abs(detcoef(C, L, 1)));
        genre = 'h';
        if paquets
            critere = 'threshold';
        end
    end
end
