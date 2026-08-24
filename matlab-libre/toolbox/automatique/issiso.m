function reponse = issiso(sys)
%ISSISO Le modèle a-t-il une entrée et une sortie ?
%   Les fonctions de transfert le sont toujours ; un modèle d'état ne
%   l'est que si B a une colonne et C une ligne.
%
%   Exemple :
%      issiso(ss([0 1; 0 0], [0; 1], [1 0], 0))   % vrai
%
%   Voir aussi ORDER, SSDATA.
    if strcmp(sys.type, 'ss')
        reponse = size(sys.B, 2) == 1 && size(sys.C, 1) == 1;
    else
        reponse = true;
    end
end
