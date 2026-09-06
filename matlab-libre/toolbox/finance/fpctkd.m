function [rapideK, rapideD] = fpctkd(haut, bas, cloture, periodeK, periodeD)
%FPCTKD Stochastiques rapides.
%   [K,D] = FPCTKD(HAUT,BAS,CLOTURE,N,M) rend la place de la clôture dans
%   l'amplitude des N dernières séances, en pourcentage, et sa moyenne
%   mobile sur M séances. N vaut 10 par défaut, M vaut 3.
%
%   Exemple :
%      rng(1);
%      clotures = 100 + cumsum(randn(60, 1));
%      [k, d] = fpctkd(clotures + 1, clotures - 1, clotures);
%      all(k >= 0 & k <= 100)            % 1 : c'est un pourcentage
%
%   Voir aussi SPCTKD, STOCHOSC, WILLPCTR.
    if nargin < 4 || isempty(periodeK), periodeK = 10; end
    if nargin < 5 || isempty(periodeD), periodeD = 3;  end
    if nargin < 2
        series = matlibre_colonnes_marche(haut, {}, {'haut', 'bas', 'cloture'});
    else
        series = matlibre_colonnes_marche(haut, {bas, cloture}, {'haut', 'bas', 'cloture'});
    end
    plusHaut = hhigh(series{1}, periodeK);
    plusBas = llow(series{2}, periodeK);
    amplitude = plusHaut - plusBas;
    amplitude(amplitude == 0) = eps;
    rapideK = 100 * (series{3} - plusBas) ./ amplitude;
    rapideD = matlibre_moyenne_simple(rapideK, periodeD);
end
