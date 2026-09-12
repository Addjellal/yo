function modele = delete_param(modele, varargin)
%DELETE_PARAM Retire un réglage du modèle.
%   MODELE = DELETE_PARAM(MODELE,'Nom',...) enlève un ou plusieurs
%   réglages posés par ADD_PARAM. Le modèle retrouve alors le
%   comportement par défaut : SIM reprend ses dix secondes et son
%   centième de seconde.
%
%   Un réglage absent est refusé en le nommant, plutôt que passé sous
%   silence : croire avoir retiré ce qui n'y était pas mène à chercher
%   longtemps pourquoi rien n'a changé.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_param(m, 'StopTime', 2);
%      m = delete_param(m, 'StopTime');
%      isfield(m.parametres, 'StopTime')        % faux
%
%   Voir aussi ADD_PARAM, SET_PARAM, GET_PARAM, NEW_SYSTEM.
    if ~isfield(modele, 'parametres')
        modele.parametres = struct();
    end
    for k = 1:numel(varargin)
        nom = char(varargin{k});
        if ~isfield(modele.parametres, nom)
            error('Simulink:Commands:DeleteParamAbsent', ...
                  'Le modele ne porte pas de reglage ''%s''.', nom);
        end
        modele.parametres = rmfield(modele.parametres, nom);
    end
end
