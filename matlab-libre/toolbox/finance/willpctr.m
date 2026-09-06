function indicateur = willpctr(haut, bas, cloture, periode)
%WILLPCTR Indicateur de Williams, en pourcentage.
%   W = WILLPCTR(HAUT,BAS,CLOTURE,N) situe la clôture dans l'amplitude
%   des N dernières séances, sur une échelle allant de -100 — la clôture
%   est au plus bas — à zéro — elle est au plus haut. N vaut 14 par
%   défaut.
%
%   Exemple :
%      rng(1);
%      clotures = 100 + cumsum(randn(60, 1));
%      willpctr(clotures + 1, clotures - 1, clotures, 14)
%
%   Voir aussi STOCHOSC, HHIGH, LLOW, RSINDEX.
    if nargin < 4 || isempty(periode), periode = 14; end
    if nargin < 2
        series = matlibre_colonnes_marche(haut, {}, {'haut', 'bas', 'cloture'});
    else
        series = matlibre_colonnes_marche(haut, {bas, cloture}, {'haut', 'bas', 'cloture'});
    end
    plusHaut = hhigh(series{1}, periode);
    plusBas = llow(series{2}, periode);
    amplitude = plusHaut - plusBas;
    amplitude(amplitude == 0) = eps;
    indicateur = -100 * (plusHaut - series{3}) ./ amplitude;
end
