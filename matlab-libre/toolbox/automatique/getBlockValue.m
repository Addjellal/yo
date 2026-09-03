function valeur = getBlockValue(modele, nom)
%GETBLOCKVALUE Valeur d'un bloc réglable d'un modèle.
%   V = GETBLOCKVALUE(M,NOM) rend le bloc nommé d'un modèle assemblé par
%   CONNECT ou par une structure de blocs : c'est ainsi qu'on récupère le
%   correcteur d'une boucle une fois réglé.
%
%   MATLAB range les blocs réglables dans un modèle « genss » ; MatLibre
%   n'en a pas, et lit le nom dans une structure de blocs — celle qu'on
%   se donne pour décrire une boucle — ou le nom d'un modèle.
%
%   Exemple :
%      blocs = struct('C', pid(1, 2), 'G', tf(1, [1 1]));
%      C = getBlockValue(blocs, 'C');
%
%   Voir aussi CONNECT, SUMBLK, PID, PIDTUNE, LOOPSENS.
    nom = char(nom);
    if isstruct(modele) && isfield(modele, nom)
        valeur = modele.(nom);
        return;
    end
    if isstruct(modele) && isfield(modele, 'Blocks') && isfield(modele.Blocks, nom)
        valeur = modele.Blocks.(nom);
        return;
    end
    if (isa(modele, 'ss') || isa(modele, 'tf') || isa(modele, 'zpk')) && ...
            strcmp(modele.Name, nom)
        valeur = modele;
        return;
    end
    error('control:getBlockValue:Bloc', ...
          'Aucun bloc nommé « %s » dans ce modèle.', nom);
end
