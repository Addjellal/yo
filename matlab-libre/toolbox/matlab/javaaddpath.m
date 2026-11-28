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
          ['MatLibre has no Java Virtual Machine: ' ...
           'the class path cannot be extended. USEJAVA(''jvm'') ' ...
           'returns false, so code can plan another way.']);
end
