function nom = matlibre_option_canonique(donne)
%MATLIBRE_OPTION_CANONIQUE Nom exact d'une option d'ajustement.
%   N = MATLIBRE_OPTION_CANONIQUE(DONNE) rend le nom du champ, quelle que
%   soit la casse employée. MATLAB accepte 'startpoint' comme
%   'StartPoint' ; il faut donc rapprocher les deux.
%
%   Exemple :
%      matlibre_option_canonique('startpoint')      % StartPoint
%
%   Voir aussi FITOPTIONS.
    connus = fieldnames(matlibre_options_defaut());
    position = find(strcmpi(connus, donne), 1);
    if isempty(position)
        error('curvefit:fitoptions:Option', 'Réglage inconnu : %s.', donne);
    end
    nom = connus{position};
end
