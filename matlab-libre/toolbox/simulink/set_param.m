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
%   MODELE = SET_PARAM(MODELE,'Nom',VALEUR) — une seule valeur, sans nom
%   de bloc devant — change un réglage du modèle lui-même, comme
%   StopTime ou FixedStep. La forme se distingue sans ambiguïté : un
%   réglage de bloc se donne toujours par couples, donc en nombre pair
%   d'arguments après le nom du bloc.
%
%   Exemple :
%      m = new_system('boucle');
%      m = add_block(m, 'constant', 'consigne', 'Value', 1);
%      m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
%      m = add_block(m, 'gain', 'gain', 'Gain', 2);
%      m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
%      m = add_line(m, 'consigne', 'erreur', 1);
%      m = add_line(m, 'sortie', 'erreur', 2);
%      m = add_line(m, 'erreur', 'gain');
%      m = add_line(m, 'gain', 'sortie');
%      for K = [1 2 5]
%          m = set_param(m, 'gain', 'Gain', K);
%          r = sim(m, 5, 0.01);
%      end
%
%   Voir aussi ADD_BLOCK, ADD_PARAM, NEW_SYSTEM, SIM.
    if mod(numel(varargin), 2) == 1
        % Nombre impair : c'est « nom du reglage, valeur » sur le modele.
        if ~isfield(modele, 'parametres')
            modele.parametres = struct();
        end
        modele.parametres.(char(nom)) = varargin{1};
        return
    end
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
