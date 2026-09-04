function jeu = matlibre_jeu_vide()
%MATLIBRE_JEU_VIDE Jeu d'instruments sans instrument.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    jeu = struct('FinObj', 'Instruments', 'Type', {{}}, 'FieldName', {{}}, ...
                 'FieldClass', {{}}, 'FieldData', {{}}, 'Index', {{}}, ...
                 'Nombre', 0);
end
