function javarmpath(varargin)
%JAVARMPATH Retire du chemin de classes Java.
%   JAVARMPATH(CHEMIN) retirerait CHEMIN du chemin de classes. MatLibre
%   n'embarque pas de machine virtuelle Java : l'appel échoue.
%
%   Exemple :
%      try, javarmpath('/tmp/x.jar'); catch e, disp(e.identifier); end
%
%   Voir aussi JAVACLASSPATH, JAVAADDPATH, USEJAVA.
    error('MATLAB:Java:NoJVM', ...
          ['MatLibre has no Java Virtual Machine: ' ...
           'there is no class path to remove from.']);
end
