function oui = ismcc()
%ISMCC Vrai pendant la compilation par MCC.
%   OUI = ISMCC() vaut toujours faux dans MatLibre : MCC n'exécute pas le
%   programme pour l'analyser, comme le fait MATLAB Compiler, il fabrique
%   un lanceur. Un programme qui teste ISMCC pour sauter du code pendant
%   la compilation garde donc son comportement ordinaire.
%
%   Exemple :
%      ismcc()                         % false
%
%   Voir aussi ISDEPLOYED, MCC.
    oui = false;
end
