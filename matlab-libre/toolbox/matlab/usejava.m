function disponible = usejava(composant)
%USEJAVA Dit si une partie de Java est disponible.
%   T = USEJAVA(COMPOSANT) rend vrai si le composant demandé est
%   utilisable. Les composants sont 'jvm', 'awt', 'swing' et 'desktop'.
%
%   MatLibre n'embarque pas de machine virtuelle Java : la réponse est
%   donc toujours faux. C'est la réponse utile — le rôle de USEJAVA est
%   précisément de permettre à un programme de choisir une autre voie,
%   et un programme qui interroge obtient ici de quoi le faire au lieu
%   d'une fonction introuvable.
%
%   Exemple :
%      usejava('jvm')                  % 0 : pas de machine virtuelle
%      if ~usejava('swing'), disp('interface en mode texte'); end
%
%   Voir aussi ISJAVA, JAVACLASSPATH, JAVAOBJECT, COMPUTER.
    if nargin < 1
        error('MATLAB:minrhs', 'USEJAVA attend le nom d''un composant.');
    end
    composant = lower(char(composant));
    connus = {'jvm', 'awt', 'swing', 'desktop'};
    if ~any(strcmp(composant, connus))
        error('MATLAB:usejava:invalidComponent', ...
              'Composant inconnu « %s » ; attendus : %s.', ...
              composant, strjoin(connus, ', '));
    end
    disponible = false;
end
