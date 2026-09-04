function [parametres, vitesse] = sgdmupdate(parametres, gradients, vitesse, pas, inertie)
%SGDMUPDATE Un pas de descente de gradient à inertie.
%   [P,V] = SGDMUPDATE(P,G,V) retranche aux paramètres non pas le gradient
%   seul mais une vitesse, qui garde une part du déplacement précédent.
%   L'inertie traverse les creux étroits où le gradient seul oscillerait,
%   et accumule de la vitesse dans les vallées longues.
%
%   [P,V] = SGDMUPDATE(P,G,V,PAS,INERTIE) impose les réglages ; par
%   défaut, 0,01 et 0,9.
%
%   P, G et V peuvent être un DLARRAY, un tableau de cellules, une
%   structure ou une table de paramètres.
%
%   Exemple :
%      [p, v] = sgdmupdate(dlarray(1), dlarray(2), []);
%      extractdata(p)      % 0.98
%
%   Voir aussi ADAMUPDATE, RMSPROPUPDATE, TRAININGOPTIONS.
    if nargin < 4 || isempty(pas), pas = 0.01; end
    if nargin < 5 || isempty(inertie), inertie = 0.9; end
    if isempty(vitesse)
        vitesse = matlibre_dl_zeros_comme(parametres);
    end
    [parametres, vitesse] = matlibre_dl_combiner( ...
        @(p, g, v) pasInertie(p, g, v, pas, inertie), parametres, gradients, vitesse);
end

function [p, v] = pasInertie(p, g, v, pas, inertie)
    v = inertie * matlibre_dl_valeur(v) + pas * matlibre_dl_valeur(g);
    p = matlibre_dl_soustraire(p, v);
end
