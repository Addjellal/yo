function modele = replace_block(modele, ancien, nouveau, varargin)
%REPLACE_BLOCK Remplace les blocs d'un type par un autre type.
%   MODELE = REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU) change le type de tous
%   les blocs de type ANCIEN en NOUVEAU. Les noms et les liens sont
%   conservés, ainsi que les paramètres que le nouveau type porte aussi ;
%   les autres sont retirés, puisque plus personne ne les lirait. Les
%   types se désignent comme dans ADD_BLOCK : nom MatLibre, type Simulink
%   ou chemin de bibliothèque.
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
    ancien = matlibre_sl_catalogue('type', ancien);
    nouveau = matlibre_sl_catalogue('type', nouveau);
    for i = 1:numel(modele.blocs)
        try
            actuel = matlibre_sl_catalogue('type', modele.blocs{i}.type);
        catch
            continue
        end
        if ~strcmp(actuel.type, ancien.type)
            continue
        end
        gardes = struct();
        anciens = fieldnames(modele.blocs{i}.parametres);
        for k = 1:numel(anciens)
            canon = matlibre_sl_catalogue('parametre', nouveau, anciens{k});
            if ~isempty(canon)
                gardes.(canon) = modele.blocs{i}.parametres.(anciens{k});
            end
        end
        for k = 1:2:numel(varargin) - 1
            canon = matlibre_sl_catalogue('parametre', nouveau, varargin{k});
            if isempty(canon)
                error('Simulink:Commands:ParamUnknown', ...
                      'Un bloc %s n''a pas de parametre nomme ''%s''.', nouveau.affiche, ...
                      char(varargin{k}));
            end
            gardes.(canon) = varargin{k + 1};
        end
        modele.blocs{i}.type = nouveau.type;
        modele.blocs{i}.parametres = gardes;
    end
end
