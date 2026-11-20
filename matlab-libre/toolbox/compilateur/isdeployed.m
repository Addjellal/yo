function oui = isdeployed()
%ISDEPLOYED Vrai dans une application produite par MCC.
%   OUI = ISDEPLOYED() vaut vrai quand le programme tourne par le lanceur
%   que MCC a fabriqué, faux dans l'interpréteur. C'est ce qu'un programme
%   teste pour ne régler son chemin qu'en développement :
%      if ~isdeployed, addpath('outils'); end
%
%   Exemple :
%      isdeployed()                    % false : on est dans l'interpréteur
%
%   Voir aussi MCC, ISMCC.
    oui = strcmp(getenv('MATLIBRE_DEPLOYE'), '1');
end
