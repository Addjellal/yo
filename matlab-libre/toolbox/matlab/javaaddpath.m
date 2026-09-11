function javaaddpath(varargin)
%JAVAADDPATH Ajoute au chemin de classes Java.
%   JAVAADDPATH(CHEMIN) ajouterait CHEMIN au chemin de classes. MatLibre
%   n'embarque pas de machine virtuelle Java : l'appel échoue au lieu de
%   faire croire que la classe sera trouvée plus tard.
%
%   Exemple :
%      try, javaaddpath('/tmp/x.jar'); catch e, disp(e.identifier); end
%
%   Voir aussi JAVACLASSPATH, USEJAVA, JAVAOBJECT.
    error('MATLAB:Java:NoJVM', ...
          ['MatLibre n''embarque pas de machine virtuelle Java : ' ...
           'le chemin de classes ne peut pas être étendu. USEJAVA(''jvm'') ' ...
           'rend faux et permet de prévoir une autre voie.']);
end
