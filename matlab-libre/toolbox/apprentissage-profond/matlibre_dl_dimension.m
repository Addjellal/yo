function dimension = matlibre_dl_dimension(valeur, arguments)
%MATLIBRE_DL_DIMENSION Dimension visée par une somme ou une moyenne.
%   D = MATLIBRE_DL_DIMENSION(VALEUR,ARGUMENTS) lit les arguments passés
%   après le tableau : rien donne la première dimension non singleton,
%   'all' donne zéro — le tableau entier —, un nombre se lit tel quel.
%
%   Exemple :
%      matlibre_dl_dimension(zeros(1, 5), {})       % 2
%      matlibre_dl_dimension(zeros(3), {'all'})     % 0
%
%   Voir aussi DLARRAY.
    if isempty(arguments)
        dimension = find(size(valeur) > 1, 1);
        if isempty(dimension)
            dimension = 1;
        end
        return
    end
    premier = arguments{1};
    if ischar(premier)
        if strcmpi(premier, 'all')
            dimension = 0;
        else
            error('nnet:dlarray:Dimension', 'Option inconnue : %s.', premier);
        end
    else
        dimension = double(premier);
    end
end
