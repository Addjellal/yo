function modele = add_line(modele, source, destination, entree)
%ADD_LINE Relie la sortie d'un bloc à l'entrée d'un autre.
%   MODELE = ADD_LINE(MODELE,'source','destination') relie la sortie du
%   premier bloc à la première entrée du second.
%   ADD_LINE(MODELE,'source','destination',NUMERO) choisit l'entrée, ce
%   qui importe pour un bloc de somme dont les signes diffèrent.
%
%   Une sortie peut alimenter plusieurs entrées : il suffit de plusieurs
%   liens. Une entrée, non : le dernier lien posé l'emporterait.
%
%   Une boucle est permise pourvu qu'un bloc à état — intégrateur ou
%   retard — la coupe. Sans cela, la boucle est algébrique et le tri
%   topologique n'a pas de solution.
%
%   Exemple :
%      m = add_line(m, 'consigne', 'erreur', 1);
%      m = add_line(m, 'sortie', 'erreur', 2);   % le retour
%      m = add_line(m, 'erreur', 'gain');
%
%   Voir aussi ADD_BLOCK, NEW_SYSTEM, SIM.
    if nargin < 4
        entree = 1;
    end
    a = indiceBloc(modele, source);
    b = indiceBloc(modele, destination);
    modele.liens(end+1, :) = [a, b, entree];
end

function k = indiceBloc(modele, nom)
    k = 0;
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            k = i;
            return;
        end
    end
    error('simulink:add_line:unknownBlock', 'Unknown block ''%s''.', nom);
end
