function nom = matlibre_id_propriete(donne)
%MATLIBRE_ID_PROPRIETE Nom exact d'une propriété de IDDATA.
%   N = MATLIBRE_ID_PROPRIETE(DONNE) rapproche le nom donné, quelle qu'en
%   soit la casse, de celui de la propriété.
%
%   Exemple :
%      matlibre_id_propriete('outputname')      % OutputName
%
%   Voir aussi IDDATA.
    connus = {'OutputData', 'InputData', 'Ts', 'Tstart', 'TimeUnit', ...
              'Name', 'OutputName', 'InputName', 'ExperimentName'};
    position = find(strcmpi(connus, donne), 1);
    if isempty(position)
        error('ident:iddata:Propriete', 'Propriété inconnue : %s.', donne);
    end
    nom = connus{position};
end
