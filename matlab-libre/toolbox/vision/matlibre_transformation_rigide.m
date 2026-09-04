function M = matlibre_transformation_rigide(transformation)
%MATLIBRE_TRANSFORMATION_RIGIDE Matrice homogène 4x4 d'une transformation.
%   Accepte une matrice 4x4 dans l'une ou l'autre convention, une
%   rotation 3x3, ou une structure à champ T ou A. La convention de
%   MATLAB place la translation en dernière ligne ; on la reconnaît à ce
%   que sa dernière colonne vaut [0 0 0 1].
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isstruct(transformation)
        if isfield(transformation, 'T')
            transformation = transformation.T;
        elseif isfield(transformation, 'A')
            transformation = transformation.A;
        end
    end
    M = double(transformation);
    if isequal(size(M), [3 3])
        M = [M, zeros(3, 1); 0 0 0 1];
        return
    end
    if ~isequal(size(M), [4 4])
        error('vision:transformation:Taille', ...
              'La transformation doit être 3x3 ou 4x4.');
    end
    if max(abs(M(1:3, 4))) < 1e-12 && abs(M(4, 4) - 1) < 1e-12
        % Dernière colonne nulle : c'est la convention des lignes.
        M = M.';
    end
end
