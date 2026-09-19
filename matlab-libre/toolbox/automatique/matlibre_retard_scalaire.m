function d = matlibre_retard_scalaire(sys, quoi)
%MATLIBRE_RETARD_SCALAIRE Le retard d'un modèle, quand il n'en a qu'un.
%   D = MATLIBRE_RETARD_SCALAIRE(SYS,QUOI) rend le retard total du
%   modèle. Toutes les voies doivent porter le même : un calcul qui ne
%   sait appliquer qu'un seul décalage ne peut pas en honorer plusieurs,
%   et le dire vaut mieux que d'en choisir un au hasard.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      g = tf(1, [1 1]); g.InputDelay = 2;
%      matlibre_retard_scalaire(g, 'LSIM')      % 2
%
%   Voir aussi TOTALDELAY, HASDELAY, MATLIBRE_SANS_RETARD.
    d = totaldelay(sys);
    if isempty(d)
        d = 0;
        return
    end
    if any(d(:) ~= d(1))
        error('Control:ltiobject:delayNotUniform', ...
              ['%s ne sait appliquer qu''un seul retard, et les voies du ' ...
               'modele en portent de differents (de %g a %g).'], ...
              upper(char(quoi)), min(d(:)), max(d(:)));
    end
    d = d(1);
end
