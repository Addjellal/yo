function valeur = get_param(modele, nom, parametre)
%GET_PARAM Lit un paramètre d'un bloc, ou la description d'un bloc.
%   V = GET_PARAM(MODELE,NOM,'Param') rend la valeur du paramètre du bloc
%   nommé. GET_PARAM(MODELE,NOM) rend la structure entière du bloc : son
%   type, son nom et tous ses paramètres.
%   GET_PARAM(MODELE,'Name') et GET_PARAM(MODELE,'Blocks') répondent sur
%   le modèle lui-même, ainsi que tout réglage posé par ADD_PARAM —
%   StopTime, FixedStep — quand aucun bloc ne porte ce nom.
%
%   C'est le pendant de SET_PARAM, sans lequel on pouvait écrire un
%   réglage sans jamais pouvoir le relire — et donc ni le vérifier, ni le
%   sauvegarder, ni l'afficher.
%
%   Un paramètre absent lève une erreur qui le nomme, plutôt que de rendre
%   une valeur vide dont on ne saurait pas si elle est le réglage ou son
%   absence.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'gain', 'g', 'Gain', 2);
%      get_param(m, 'g', 'Gain')            % 2
%      m = set_param(m, 'g', 'Gain', 5);
%      get_param(m, 'g', 'Gain')            % 5
%      get_param(m, 'g').type               % 'gain'
%      m = add_param(m, 'StopTime', 4);
%      get_param(m, 'StopTime')             % 4
%
%   Voir aussi SET_PARAM, ADD_PARAM, ADD_BLOCK, FIND_SYSTEM, NEW_SYSTEM.
    if nargin == 2 && (strcmpi(nom, 'Name') || strcmpi(nom, 'Blocks'))
        if strcmpi(nom, 'Name')
            valeur = modele.nom;
        else
            valeur = cell(1, numel(modele.blocs));
            for i = 1:numel(modele.blocs)
                valeur{i} = modele.blocs{i}.nom;
            end
        end
        return
    end
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            bloc = modele.blocs{i};
            if nargin < 3
                valeur = bloc;
                return
            end
            champ = char(parametre);
            if strcmpi(champ, 'BlockType') || strcmpi(champ, 'Type')
                valeur = bloc.type;
                return
            end
            if strcmpi(champ, 'Name')
                valeur = bloc.nom;
                return
            end
            if isfield(bloc.parametres, champ)
                valeur = bloc.parametres.(champ);
                return
            end
            error('simulink:get_param:unknownParameter', ...
                  'Le bloc ''%s'' n''a pas de paramètre ''%s''.', nom, champ);
        end
    end
    % Aucun bloc de ce nom : c'est peut-être un réglage du modèle.
    if nargin == 2 && isfield(modele, 'parametres') && isfield(modele.parametres, char(nom))
        valeur = modele.parametres.(char(nom));
        return
    end
    error('simulink:get_param:unknownBlock', 'Unknown block ''%s''.', nom);
end
