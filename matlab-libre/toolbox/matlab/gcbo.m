function [h, f] = gcbo()
%GCBO Poignée de l'objet dont le rappel s'exécute.
%   H = GCBO() rend la poignée de l'objet dont le rappel est en cours ;
%   [H,F] = GCBO() rend aussi sa figure.
%
%   MatLibre n'exécute pas les rappels d'objets graphiques : hors d'un
%   rappel, MATLAB rend lui aussi un tableau vide, et c'est donc la
%   réponse exacte.
%
%   Exemple :
%      isempty(gcbo())                 % 1 : aucun rappel en cours
%
%   Voir aussi GCO, GCA, GCF.
    h = [];
    f = [];
end
