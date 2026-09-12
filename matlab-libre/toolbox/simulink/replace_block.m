function modele = replace_block(modele, ancien, nouveau, varargin)
%REPLACE_BLOCK Remplace les blocs d'un type par un autre type.
%   MODELE = REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU) change le type de tous
%   les blocs de type ANCIEN en NOUVEAU. Les noms, les liens et les
%   paramètres sont conservés.
%   REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU,'Param',VALEUR,...) fixe en outre
%   des paramètres sur chaque bloc remplacé.
%
%   Le câblage ne bouge pas : c'est tout l'intérêt, remplacer un
%   intégrateur continu par son équivalent discret sans redessiner le
%   schéma.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'integrator', 'i1');
%      m = add_block(m, 'integrator', 'i2');
%      m = replace_block(m, 'integrator', 'discreteintegrator', ...
%                        'SampleTime', 0.1);
%      get_param(m, 'i1', 'BlockType')          % 'discreteintegrator'
%      get_param(m, 'i2', 'SampleTime')         % 0.1
%
%   Voir aussi ADD_BLOCK, DELETE_BLOCK, SET_PARAM, FIND_SYSTEM.
    ancien = lower(char(ancien));
    nouveau = lower(char(nouveau));
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.type, ancien)
            modele.blocs{i}.type = nouveau;
            for k = 1:2:numel(varargin) - 1
                modele.blocs{i}.parametres.(char(varargin{k})) = varargin{k + 1};
            end
        end
    end
end
