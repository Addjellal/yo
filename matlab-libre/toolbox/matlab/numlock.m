function etat = numlock(nouvelEtat)
%NUMLOCK État de la touche de verrouillage numérique.
%   NUMLOCK('on') et NUMLOCK('off') demandent l'allumage ou l'extinction
%   du verrouillage numérique ; E = NUMLOCK rend l'état courant, 'on' ou
%   'off'.
%
%   La touche appartient au serveur graphique. Là où MatLibre ne peut pas
%   l'atteindre — une session sans écran, ou un système qui ne l'expose
%   pas —, l'état rendu est 'off' et la demande reste sans effet, sans
%   erreur.
%
%   Voir aussi INPUT, KEYBOARD.
    persistent demande
    if isempty(demande)
        demande = 'off';
    end
    if nargin > 0
        demande = lower(char(nouvelEtat));
        if ~any(strcmp(demande, {'on', 'off'}))
            error('MATLAB:numlock:BadState', 'numlock attend ''on'' ou ''off''.');
        end
        if ispc()
            % Rien à faire : sans accès au clavier du système, la demande
            % est seulement retenue.
        end
    end
    if nargout > 0 || nargin == 0
        etat = demande;
    end
end
