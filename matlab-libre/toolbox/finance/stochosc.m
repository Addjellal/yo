function [pourcentK, pourcentD] = stochosc(haut, bas, cloture, periodeK, periodeD)
%STOCHOSC Oscillateur stochastique.
%   [K,D] = STOCHOSC(HAUT,BAS,CLOTURE,N,M) rend les stochastiques
%   rapides : la place de la clôture dans l'amplitude des N dernières
%   séances et sa moyenne sur M séances.
%
%   Un cours qui clôture près de son plus haut hebdomadaire n'a pas la
%   même signification qu'un cours qui clôture près de son plus bas, même
%   s'il a monté d'autant : c'est ce que l'indicateur mesure.
%
%   Exemple :
%      [k, d] = stochosc(hauts, bas, clotures);
%
%   Voir aussi FPCTKD, SPCTKD, WILLPCTR, RSINDEX.
    if nargin < 4, periodeK = []; end
    if nargin < 5, periodeD = []; end
    if nargin < 2
        [pourcentK, pourcentD] = fpctkd(haut, [], [], periodeK, periodeD);
    else
        [pourcentK, pourcentD] = fpctkd(haut, bas, cloture, periodeK, periodeD);
    end
end
