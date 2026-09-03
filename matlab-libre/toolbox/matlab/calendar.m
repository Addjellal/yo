function c = calendar(varargin)
%CALENDAR Calendrier d'un mois.
%   C = CALENDAR(A,M) rend une matrice 6x7 : une colonne par jour de la
%   semaine, dimanche en premier, une ligne par semaine. Les cases hors
%   du mois valent zéro.
%
%   C = CALENDAR(D) prend le mois de la date D, donnée en numéro de
%   série ou en texte. Sans argument, c'est le mois courant.
%
%   Sans sortie, le calendrier s'affiche.
%
%   Exemple :
%      calendar(2024, 2)
%
%   Voir aussi EOMDAY, WEEKDAY, DATENUM, DATESTR.
    if isempty(varargin)
        v = datevec(now());
        annee = v(1);
        mois = v(2);
    elseif numel(varargin) == 1
        v = datevec(varargin{1});
        annee = v(1);
        mois = v(2);
    else
        annee = double(varargin{1});
        mois = double(varargin{2});
    end
    premier = datenum(annee, mois, 1);
    jourSemaine = weekday(premier);          % 1 = dimanche
    nbJours = eomday(annee, mois);
    grille = zeros(6, 7);
    ligne = 1;
    colonne = jourSemaine;
    for j = 1:nbJours
        grille(ligne, colonne) = j;
        colonne = colonne + 1;
        if colonne > 7
            colonne = 1;
            ligne = ligne + 1;
        end
    end
    if nargout == 0
        afficher(grille, annee, mois);
    else
        c = grille;
    end
end

function afficher(grille, annee, mois)
    noms = {'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Jun', ...
            'Jui', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec'};
    fprintf('\n     %s %d\n', noms{mois}, annee);
    fprintf('  D   L   M   M   J   V   S\n');
    for i = 1:6
        if all(grille(i, :) == 0)
            continue;
        end
        for j = 1:7
            if grille(i, j) == 0
                fprintf('    ');
            else
                fprintf('%3d ', grille(i, j));
            end
        end
        fprintf('\n');
    end
    fprintf('\n');
end
