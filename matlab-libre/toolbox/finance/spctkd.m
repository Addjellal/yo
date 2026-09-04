function [lentK, lentD] = spctkd(rapideK, rapideD, periode)
%SPCTKD Stochastiques lentes.
%   [K,D] = SPCTKD(RAPIDEK,RAPIDED,M) lisse les stochastiques rapides :
%   le K lent est l'ancien D rapide, et le D lent en est la moyenne
%   mobile sur M séances. M vaut 3 par défaut.
%
%   Le lissage supprime les croisements les plus nombreux, qui sont aussi
%   les moins informatifs.
%
%   Exemple :
%      [k, d] = fpctkd(hauts, bas, clotures);
%      [kl, dl] = spctkd(k, d);
%
%   Voir aussi FPCTKD, STOCHOSC.
    if nargin < 3 || isempty(periode), periode = 3; end
    if nargin < 2 || isempty(rapideD)
        rapideD = matlibre_moyenne_simple(rapideK, periode);
    end
    lentK = double(rapideD(:));
    lentD = matlibre_moyenne_simple(lentK, periode);
end
