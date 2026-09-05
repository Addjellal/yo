function poles = matlibre_id_proc_compte(type)
%MATLIBRE_ID_PROC_COMPTE Nombre de pôles que déclare un type de procédé.
%   N = MATLIBRE_ID_PROC_COMPTE(TYPE) lit le chiffre qui suit la lettre P.
%
%   Exemple :
%      matlibre_id_proc_compte('P2ZD')      % 2
%
%   Voir aussi IDPROC, PROCEST.
    chiffres = type(isstrprop(type, 'digit'));
    if isempty(chiffres)
        poles = 1;
    else
        poles = str2double(chiffres(1));
    end
end
