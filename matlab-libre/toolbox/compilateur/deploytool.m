function description = deploytool(script)
%DEPLOYTOOL Décrit le paquet de distribution d'un script.
%   D = DEPLOYTOOL('script.m') rend une structure disant ce qu'il faut
%   emporter pour que le programme tourne ailleurs :
%
%      script        le script lui-même
%      interpreteur  le chemin de l'interpréteur MatLibre
%      toolboxes     le dossier des boîtes à outils
%      remarque      ce que le paquet n'est pas
%
%   MATLAB distribue un programme compilé avec son « runtime », un
%   ensemble de bibliothèques à installer sur la machine cible. Ici la
%   dépendance est l'interpréteur et le dossier des toolboxes : c'est la
%   même chose, dite plus simplement.
%
%   Exemple :
%      d = deploytool('analyse.m');
%      d.toolboxes
%
%   Voir aussi MCC, MATLABROOT.
    description = struct();
    description.script = script;
    description.interpreteur = matlibre_executable();
    description.toolboxes = matlabroot();
    description.remarque = ['Le programme produit appelle l''interpreteur ' ...
                            'MatLibre ; il n''est pas autonome au sens binaire.'];
end
