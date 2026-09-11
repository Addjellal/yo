function noms = find_system(modele, varargin)
%FIND_SYSTEM Les blocs d'un modèle, éventuellement filtrés.
%   NOMS = FIND_SYSTEM(MODELE) rend le nom de tous les blocs.
%   NOMS = FIND_SYSTEM(MODELE,'BlockType',TYPE) ne garde que ceux du type
%   donné. D'autres couples nom-valeur filtrent sur les paramètres.
%
%   Le filtre est conjonctif : un bloc n'est gardé que s'il répond à tous
%   les critères. Sans critère, tous les blocs sortent.
%
%   La comparaison est textuelle, y compris sur les valeurs numériques :
%   un gain de 2 se retrouve aussi bien par 2 que par '2', puisque c'est
%   ainsi qu'ADD_BLOCK accepte de l'écrire.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'gain', 'g1', 'Gain', 2);
%      m = add_block(m, 'gain', 'g2', 'Gain', 3);
%      m = add_block(m, 'constant', 'c', 'Value', 1);
%      numel(find_system(m))                        % 3
%      numel(find_system(m, 'BlockType', 'gain'))   % 2
%      find_system(m, 'Gain', 3)                    % {'g2'}
%
%   Voir aussi GET_PARAM, SET_PARAM, ADD_BLOCK, NEW_SYSTEM.
    noms = {};
    for i = 1:numel(modele.blocs)
        bloc = modele.blocs{i};
        garde = true;
        for k = 1:2:numel(varargin) - 1
            critere = char(varargin{k});
            attendu = varargin{k + 1};
            if strcmpi(critere, 'BlockType') || strcmpi(critere, 'Type')
                obtenu = bloc.type;
            elseif strcmpi(critere, 'Name')
                obtenu = bloc.nom;
            elseif isfield(bloc.parametres, critere)
                obtenu = bloc.parametres.(critere);
            else
                garde = false;
                break
            end
            if ~matlibre_meme_valeur(obtenu, attendu)
                garde = false;
                break
            end
        end
        if garde
            noms{end + 1} = bloc.nom;   %#ok<AGROW>
        end
    end
end
