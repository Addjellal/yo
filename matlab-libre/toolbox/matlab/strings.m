function s = strings(varargin)
%STRINGS Tableau de chaînes vides.
%   S = STRINGS(N) rend un tableau N sur N de chaînes vides.
%   S = STRINGS(M,N) rend un tableau M sur N.
%   S = STRINGS(SIZE) accepte aussi un vecteur de dimensions.
%   S = STRINGS() rend une seule chaîne vide.
%
%   Une chaîne vide n'est pas une chaîne manquante : "" a une longueur
%   nulle, alors que MISSING n'a pas de valeur. C'est pourquoi STRINGS
%   sert à préallouer — les cases sont utilisables telles quelles — là où
%   un tableau de manquantes signalerait qu'il reste du travail.
%
%   Préallouer avant une boucle évite de réallouer à chaque tour, ce qui
%   coûte cher dès que le tableau devient grand.
%
%   Exemple :
%      s = strings(1, 3);
%      strlength(s)                    % [0 0 0]
%      s(2) = "milieu";
%
%   Voir aussi STRING, BLANKS, CELL, ZEROS, ISMISSING.
    if isempty(varargin)
        dimensions = [1 1];
    elseif numel(varargin) == 1
        d = double(varargin{1});
        if isscalar(d)
            dimensions = [d d];
        else
            dimensions = d(:).';
        end
    else
        dimensions = cell2mat(varargin);
        dimensions = double(dimensions(:)).';
    end
    dimensions = round(max(dimensions, 0));
    if any(dimensions == 0)
        s = repmat(string(''), dimensions);
        return
    end
    s = repmat(string(''), dimensions);
end
