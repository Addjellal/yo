function varargout = javaArray(varargin)
%JAVAARRAY Crée un tableau Java.
%   JAVAARRAY(CLASSE,DIMS...) construirait un tableau Java.
%
%   MatLibre n'embarque pas de machine virtuelle Java : l'appel échoue
%   avec l'identifiant « MATLAB:Java:NoJVM ». Échouer clairement vaut
%   mieux que rendre un objet factice, dont la première méthode appelée
%   trahirait l'illusion loin de sa cause.
%
%   Exemple :
%      try, javaArray('java.lang.String'); catch e, disp(e.identifier); end
%
%   Voir aussi USEJAVA, ISJAVA, JAVACLASSPATH.
    error('MATLAB:Java:NoJVM', ...
          ['MatLibre has no Java Virtual Machine: ' ...
           'JAVAARRAY cannot create anything. USEJAVA(''jvm'') returns ' ...
           'false, so code can plan another way.']);
end
