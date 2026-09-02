function s = icsignal(taille, nom)
%ICSIGNAL Signal nommé pour l'assemblage d'un schéma.
%   S = ICSIGNAL(N) crée un signal de N voies, nommé automatiquement.
%   S = ICSIGNAL(N,'nom') le nomme.
%
%   Les signaux d'ICSIGNAL servaient, dans les versions anciennes de la
%   boîte à outils, à décrire un schéma-blocs par des équations, à l'aide
%   d'ICONNECT. MatLibre assemble les schémas par SYSIC — la forme que le
%   H-infini emploie — et par CONNECT, qui relie par les noms des voies.
%
%   S porte les champs Name et Size ; on l'emploie avec ICONNECT.
%
%   Exemples :
%      e = icsignal(1, 'e');
%      u = icsignal(1, 'u');
%      e.Name
%
%   Voir aussi ICONNECT, SYSIC, CONNECT, SUMBLK, APPEND.
    persistent compteur
    if isempty(compteur)
        compteur = 0;
    end
    if nargin < 1 || isempty(taille)
        taille = 1;
    end
    if nargin < 2 || isempty(nom)
        compteur = compteur + 1;
        nom = sprintf('signal%d', compteur);
    end
    s = struct('Name', char(nom), 'Size', taille, 'Kind', 'icsignal');
end
