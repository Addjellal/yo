function x = imread(nomFichier, format)
%IMREAD Lit une image aux formats PGM et PPM en texte (P2 et P3).
%   X = IMREAD(FICHIER) rend une matrice de niveaux de gris pour un P2,
%   un tableau à trois plans pour un P3.
%
%   La classe rendue suit la valeur maximale déclarée dans le fichier :
%   uint8 jusqu'à 255, uint16 au-delà. C'est la convention de MATLAB, et
%   elle importe : une image entière et une image flottante ne se
%   traitent pas de la même façon, et IM2DOUBLE existe pour passer de
%   l'une à l'autre.
%
%   Seuls les deux formats en texte sont lus. Les formats compressés —
%   PNG, JPEG, TIFF — demandent une bibliothèque externe, que MatLibre
%   n'emporte pas. Les commentaires, introduits par un dièse, sont
%   ignorés.
%
%   Exemple :
%      imwrite(uint8(magic(8) * 4), 'essai.pgm');
%      x = imread('essai.pgm');
%      class(x)                        % uint8
%
%   Voir aussi IMWRITE, IM2DOUBLE, IMSHOW.
    if nargin > 1 && ~isempty(format)
        % Le format se déduit du contenu ; l'argument est accepté pour la
        % compatibilité, et seuls le PGM et le PPM se lisent de toute façon.
    end
    texte = fileread(nomFichier);
    jetons = strsplit(strtrim(regexprep(texte, '#[^\n]*', ' ')));
    if isempty(jetons)
        error('images:imread:vide', 'Le fichier « %s » est vide.', nomFichier);
    end
    entete = strtrim(jetons{1});
    if ~any(strcmp(entete, {'P2', 'P3'}))
        error('images:imread:format', ...
              ['Seuls les formats PGM et PPM en texte — P2 et P3 — se ' ...
               'lisent ; « %s » annonce « %s ».'], nomFichier, entete);
    end
    nombres = str2double(jetons(2:end));
    nombres = nombres(~isnan(nombres));
    if numel(nombres) < 3
        error('images:imread:entete', ...
              'L''en-tete de « %s » est incomplet.', nomFichier);
    end
    l = nombres(1);
    h = nombres(2);
    maxi = nombres(3);
    donnees = nombres(4:end);
    if strcmp(entete, 'P3')
        attendu = h * l * 3;
    else
        attendu = h * l;
    end
    if numel(donnees) < attendu
        error('images:imread:tronque', ...
              'Le fichier « %s » annonce %d valeurs et n''en porte que %d.', ...
              nomFichier, attendu, numel(donnees));
    end
    donnees = donnees(1:attendu);
    if strcmp(entete, 'P3')
        % Les valeurs sont rangées par pixel, canal par canal, ligne par
        % ligne : c'est l'ordre du fichier, non celui de MATLAB.
        cube = reshape(donnees, 3, l, h);
        x = permute(cube, [3 2 1]);
    else
        x = reshape(donnees, l, h).';
    end
    if maxi <= 255
        x = uint8(x * 255 / maxi);
    else
        x = uint16(x * 65535 / maxi);
    end
end
