function K = matlibre_camera_matrice(parametres)
%MATLIBRE_CAMERA_MATRICE Matrice interne, dans la convention des lignes.
%   Accepte une structure de paramètres ou directement une matrice 3x3.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isstruct(parametres)
        K = parametres.IntrinsicMatrix;
    else
        K = double(parametres);
    end
    if ~isequal(size(K), [3 3])
        error('vision:camera:Matrice', 'The intrinsic matrix must be 3-by-3.');
    end
end
