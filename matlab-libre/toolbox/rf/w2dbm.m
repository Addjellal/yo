function d = w2dbm(watts)
%W2DBM Conversion watts vers dBm.
%   D = W2DBM(WATTS) rend la puissance en dBm. C'est la réciproque exacte
%   de DBM2W.
%
%   Une puissance nulle rend moins l'infini, ce qui est la limite juste et
%   non une erreur : aucune puissance, aucun décibel.
%
%   Exemple :
%      w2dbm(1)                        % 30
%      w2dbm(dbm2w(-42))               % -42
%
%   Voir aussi DBM2W, FRIISNOISE.
    d = 10 * log10(watts) + 30;
end
