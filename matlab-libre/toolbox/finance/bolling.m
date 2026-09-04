function [milieu, haute, basse] = bolling(actif, echantillons, alpha, largeur)
%BOLLING Bandes de Bollinger.
%   [M,H,B] = BOLLING(COURS,N,ALPHA,LARGEUR) rend une moyenne mobile sur
%   N séances et deux bandes situées à LARGEUR écarts types de part et
%   d'autre. ALPHA pondère la moyenne : zéro pour une moyenne
%   arithmétique — le défaut —, un pour une moyenne linéaire, deux pour
%   une moyenne quadratique. LARGEUR vaut deux.
%
%   L'écart type est celui des N dernières séances : les bandes se
%   resserrent quand le marché est calme et s'écartent quand il s'agite.
%   Un cours qui sort de la bande n'annonce rien par lui-même ; c'est
%   l'écartement soudain qui se remarque.
%
%   Exemple :
%      [m, h, b] = bolling(clotures, 20, 0, 2);
%
%   Voir aussi BOLLINGER, MOVAVG, CHAIKVOLAT.
    if nargin < 2 || isempty(echantillons), echantillons = 20; end
    if nargin < 3 || isempty(alpha),        alpha = 0;         end
    if nargin < 4 || isempty(largeur),      largeur = 2;       end
    series = matlibre_colonnes_marche(actif, {}, {'cloture'});
    x = series{1};
    n = numel(x);
    milieu = nan(n, 1);
    ecarts = nan(n, 1);
    poids = (1:echantillons) .^ alpha;
    poids = poids(:) / sum(poids);
    for k = echantillons:n
        fenetre = x((k - echantillons + 1):k);
        milieu(k) = sum(poids .* fenetre);
        ecarts(k) = sqrt(sum(poids .* (fenetre - milieu(k)) .^ 2));
    end
    haute = milieu + largeur * ecarts;
    basse = milieu - largeur * ecarts;
end
