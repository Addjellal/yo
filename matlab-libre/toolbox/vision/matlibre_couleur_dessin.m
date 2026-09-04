function rvb = matlibre_couleur_dessin(specification, nombre)
%MATLIBRE_COULEUR_DESSIN Couleur d'annotation, ramenée à [0,1].
%   C = MATLIBRE_COULEUR_DESSIN(SPEC) accepte un nom ('red', 'yellow',
%   'black', ...), un triplet dans [0,1], un triplet dans [0,255], une
%   liste de noms ou une matrice de triplets, et rend une matrice de
%   couleurs à trois colonnes dans [0,1].
%
%   C = MATLIBRE_COULEUR_DESSIN(SPEC,N) répète la couleur pour obtenir N
%   lignes lorsqu'une seule est donnée : chaque objet annoté a la sienne.
%
%   Exemple :
%      matlibre_couleur_dessin('yellow')     % 1 1 0
%      matlibre_couleur_dessin([255 0 0])    % 1 0 0
%
%   Voir aussi INSERTTEXT, INSERTOBJECTANNOTATION, LABELOVERLAY.
    if nargin < 2
        nombre = 1;
    end
    if ischar(specification)
        specification = {specification};
    end
    if iscell(specification)
        rvb = zeros(numel(specification), 3);
        for k = 1:numel(specification)
            rvb(k, :) = parNom(char(specification{k}));
        end
    else
        rvb = double(specification);
        if size(rvb, 2) ~= 3
            error('vision:couleur:Forme', 'Une couleur a trois composantes.');
        end
        % Un triplet dont une composante dépasse 1 est donné sur 255 :
        % c'est la convention des images entières.
        if any(rvb(:) > 1)
            rvb = rvb / 255;
        end
    end
    rvb = min(max(rvb, 0), 1);
    if size(rvb, 1) == 1 && nombre > 1
        rvb = repmat(rvb, nombre, 1);
    end
end

function c = parNom(nom)
    switch lower(strtrim(nom))
        case {'k', 'black'},   c = [0 0 0];
        case {'w', 'white'},   c = [1 1 1];
        case {'r', 'red'},     c = [1 0 0];
        case {'g', 'green'},   c = [0 1 0];
        case {'b', 'blue'},    c = [0 0 1];
        case {'c', 'cyan'},    c = [0 1 1];
        case {'m', 'magenta'}, c = [1 0 1];
        case {'y', 'yellow'},  c = [1 1 0];
        case 'orange',         c = [1 0.5 0];
        case 'gray',           c = [0.5 0.5 0.5];
        otherwise
            error('vision:couleur:Nom', 'Couleur inconnue : %s.', nom);
    end
end
