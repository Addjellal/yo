function varargout = javaMethodEDT(varargin)
%JAVAMETHODEDT Appelle une méthode Java sur le fil graphique.
%   JAVAMETHODEDT(NOM,OBJET,ARGS...) appellerait une méthode sur le fil de distribution des événements.
%
%   MatLibre n'embarque pas de machine virtuelle Java : l'appel échoue
%   avec l'identifiant « MATLAB:Java:NoJVM ». Échouer clairement vaut
%   mieux que rendre un objet factice, dont la première méthode appelée
%   trahirait l'illusion loin de sa cause.
%
%   Exemple :
%      try, javaMethodEDT('java.lang.String'); catch e, disp(e.identifier); end
%
%   Voir aussi USEJAVA, ISJAVA, JAVACLASSPATH.
    error('MATLAB:Java:NoJVM', ...
          ['MatLibre has no Java Virtual Machine: ' ...
           'JAVAMETHODEDT cannot call anything. USEJAVA(''jvm'') returns ' ...
           'false, so code can plan another way.']);
end
