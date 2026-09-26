function vrai = sfevery(contexte, n)
%SFEVERY Vrai tous les N réveils passés dans l'état.
%   VRAI = SFEVERY(CONTEXTE,N) vaut vrai au N-ième réveil depuis qu'on est
%   entré dans l'état, puis au 2N-ième, et ainsi de suite : every(N, tick)
%   de Stateflow, qu'on écrit le plus souvent dans une action de séjour,
%   ou dans la garde d'une transition vers soi.
%
%   Exemple :
%      m = sfchart('clignotant');
%      m = sfstate(m, 'actif', [], @(c, u) setfield(c, 'coups', c.coups + sfevery(c, 2)));
%      [~, c] = sfrun(m, zeros(1, 6), struct('coups', 0));
%      c.coups                     % 3
%
%   Voir aussi SFAFTER, SFAT.
    vrai = false;
    if ~isstruct(contexte) || ~isfield(contexte, 'sf_ticks')
        error('Stateflow:TempsInconnu', ...
              'La logique temporelle lit le champ sf_ticks du contexte, que pose SFSTEP.');
    end
    if contexte.sf_ticks > 0
        vrai = mod(contexte.sf_ticks, n) == 0;
    end
end
