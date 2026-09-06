function modele = set_param(modele, nom, varargin)
%SET_PARAM Modifie les paramètres d'un bloc.
%   MODELE = SET_PARAM(MODELE,NOM,'Param',VALEUR,...) change un ou
%   plusieurs paramètres du bloc nommé, sans toucher aux autres ni au
%   câblage.
%
%   C'est ainsi qu'on balaie un réglage : construire le modèle une fois,
%   puis le simuler pour chaque valeur d'un gain ou d'une condition
%   initiale.
%
%   Les noms de paramètres reconnus sont ceux qu'ADD_BLOCK décrit, par
%   type de bloc. Un nom inconnu est simplement ajouté ; il ne sera lu par
%   personne.
%
%   Exemple :
%      for K = [1 2 5]
%          m = set_param(m, 'gain', 'Gain', K);
%          r = sim(m, 5, 0.001);
%      end
%
%   Voir aussi ADD_BLOCK, NEW_SYSTEM, SIM.
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            b = modele.blocs{i};
            for k = 1:2:numel(varargin)-1
                b.parametres.(char(varargin{k})) = varargin{k+1};
            end
            modele.blocs{i} = b;
            return;
        end
    end
    error('simulink:set_param:unknownBlock', 'Unknown block ''%s''.', nom);
end
