function [C, info] = pidtool(sys, type)
%PIDTOOL Réglage d'un correcteur PID.
%   PIDTOOL(SYS) règle un PID sur le procédé SYS et trace la réponse
%   indicielle de la boucle fermée, avec celle du procédé seul.
%   PIDTOOL(SYS,TYPE) choisit la forme : 'p', 'pi', 'pd', 'pid' ou un
%   correcteur de départ.
%
%   [C,INFO] = PIDTOOL(...) rend le correcteur et les marges obtenues,
%   sans rien tracer.
%
%   MATLAB ouvre une application où l'on déplace deux curseurs — rapidité
%   et robustesse — et voit la réponse changer. MatLibre n'a pas
%   d'application interactive : il règle le correcteur comme le fait
%   PIDTUNE et montre le résultat.
%
%   Exemple :
%      C = pidtool(tf(1, [1 3 3 1]), 'pid');
%
%   Voir aussi PIDTUNE, PID, PIDSTD, MARGIN, STEP.
    if nargin < 2 || isempty(type)
        type = 'pi';
    end
    [C, info] = pidtune(sys, type);
    if nargout > 0
        return;
    end
    boucle = feedback(C * sys, 1);
    step(boucle);
    hold('on');
    step(sys);
    hold('off');
    legend('boucle fermée', 'procédé seul');
    title(sprintf('PID réglé : marge de phase %.1f degrés', info.PhaseMargin));
end
