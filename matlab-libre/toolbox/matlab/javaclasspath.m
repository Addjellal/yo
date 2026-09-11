function chemin = javaclasspath(varargin)
%JAVACLASSPATH Chemin de classes Java.
%   C = JAVACLASSPATH() rend, dans une cellule, le chemin de classes
%   dynamique. MatLibre n'embarque pas de machine virtuelle Java : le
%   chemin est donc toujours vide.
%
%   C'est la réponse exacte, et non une approximation : un chemin vide
%   décrit fidèlement un interpréteur sans Java, et un programme qui
%   parcourt le résultat n'a rien de particulier à prévoir.
%
%   Exemple :
%      isempty(javaclasspath())        % 1 : aucune classe Java
%
%   Voir aussi USEJAVA, JAVAADDPATH, JAVAOBJECT.
    chemin = {};
end
