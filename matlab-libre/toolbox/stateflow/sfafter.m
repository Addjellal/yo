function vrai = sfafter(contexte, n, unite)
%SFAFTER Vrai après N réveils — ou N secondes — passés dans l'état.
%   VRAI = SFAFTER(CONTEXTE,N) vaut vrai quand l'état dont on essaie la
%   transition est actif depuis au moins N réveils du diagramme : c'est
%   after(N, tick) de Stateflow. SFAFTER(CONTEXTE,N,'sec') compte en
%   secondes : after(N, sec), pour un diagramme qui connaît le temps — le
%   bloc Chart d'un schéma, ou un contexte qui porte l'instant sf_t.
%
%   On l'écrit dans la garde d'une transition, qui reçoit le contexte :
%      @(c, u) sfafter(c, 3)
%
%   Exemple :
%      m = sfchart('minuterie');
%      m = sfstate(m, 'attente');
%      m = sfstate(m, 'fini');
%      m = sftransition(m, 'attente', 'fini', @(c, u) sfafter(c, 3));
%      sfrun(m, zeros(1, 4))      % attente, attente, fini, fini
%
%   Voir aussi SFBEFORE, SFAT, SFEVERY, SFSTEP.
    if nargin < 3
        unite = 'tick';
    end
    vrai = duree(contexte, unite) >= n;
end

function d = duree(contexte, unite)
    switch lower(char(unite))
        case 'tick'
            champ = 'sf_ticks';
        case {'sec', 's'}
            champ = 'sf_temps';
        otherwise
            error('Stateflow:UniteTemporelle', ...
                  'L''unite est ''tick'' ou ''sec'' ; pas ''%s''.', char(unite));
    end
    if ~isstruct(contexte) || ~isfield(contexte, champ) || isnan(contexte.(champ))
        error('Stateflow:TempsInconnu', ...
              ['La logique temporelle lit le champ %s du contexte, que pose SFSTEP ; ' ...
               'en secondes, le contexte doit porter l''instant sf_t.'], champ);
    end
    d = contexte.(champ);
end
