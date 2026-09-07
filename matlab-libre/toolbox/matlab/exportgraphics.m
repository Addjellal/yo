function exportgraphics(objet, nomFichier, varargin)
%EXPORTGRAPHICS Enregistre un graphique dans un fichier.
%   EXPORTGRAPHICS(OBJET,FICHIER) écrit le contenu de l'axe ou de la
%   figure donnée dans FICHIER, dont l'extension choisit le format.
%   EXPORTGRAPHICS(FICHIER) exporte la figure courante.
%   EXPORTGRAPHICS(...,'Resolution',R) et les autres propriétés sont
%   acceptées.
%
%   Elle a remplacé PRINT et SAVEAS depuis R2020a. La différence tient à
%   ce qui est exporté : SAVEAS enregistre la figure entière, avec ses
%   marges ; EXPORTGRAPHICS n'exporte que le contenu, rogné au plus près.
%   C'est ce qu'on veut pour insérer une figure dans un document.
%
%   Exemple :
%      figure();
%      plot(1:10);
%      fichier = [tempname() '.svg'];
%      exportgraphics(gca, fichier);
%      isfile(fichier)                 % 1
%      close all;
%
%   Voir aussi SAVEAS, PRINT, FIGURE, GCA.
    if nargin == 1 || (ischar(objet) || isstring(objet))
        if nargin >= 2
            varargin = [{nomFichier}, varargin];   %#ok<NASGU>
        end
        nomFichier = char(objet);
        objet = gcf();
    end
    saveas(objet, char(nomFichier));
end
