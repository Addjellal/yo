function y = dlconv(x, poids, biais, varargin)
%DLCONV Convolution dérivable, à une ou deux dimensions.
%   Y = DLCONV(X,POIDS,BIAIS) convolue X par chacun des filtres et ajoute
%   le biais. X est rangé en hauteur-largeur-canaux-observations, POIDS en
%   hauteur-largeur-canaux-filtres, et le biais a une valeur par filtre.
%   Une entrée à trois dimensions est traitée comme unidimensionnelle :
%   position-canaux-observations.
%
%   Options et valeurs par défaut :
%     'Stride'          1, le pas du filtre
%     'Padding'         0, un nombre, un couple, une matrice deux par
%                       deux, ou 'same' pour conserver la taille
%     'DilationFactor'  1, l'écartement des coefficients du filtre
%     'DataFormat'      le format, quand X n'en porte pas
%
%   Le filtre est retourné avant le produit : DLCONV calcule une
%   convolution au sens propre, comme CONV2. Pour une couche apprise, la
%   convention est sans effet ; elle compte quand on impose un filtre.
%
%   L'opération est dérivable par rapport à l'entrée, aux poids et au
%   biais : c'est elle qui porte l'apprentissage d'un réseau convolutif.
%
%   Exemple :
%      x = dlarray(reshape(1:9, 3, 3), 'SS');
%      y = dlconv(x, ones(2, 2), 0);
%      extractdata(y)      % les sommes de chaque carre de quatre
%
%   Voir aussi DLARRAY, DLGRADIENT, CONVOLUTION2DLAYER, FULLYCONNECT.
    pas = [1 1];
    remplissage = 0;
    dilatation = [1 1];
    format = '';
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'stride',         pas = matlibre_dl_couple(varargin{k + 1});
            case 'padding',        remplissage = varargin{k + 1};
            case 'dilationfactor', dilatation = matlibre_dl_couple(varargin{k + 1});
            case 'dataformat',     format = upper(char(varargin{k + 1}));
            case 'weightsformat'
                % Le format des poids est celui de MATLAB, seul traité.
            otherwise
                error('nnet:dlconv:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    if isempty(format) && isa(x, 'dlarray')
        format = dims(x);
    end
    vx = matlibre_dl_valeur(x);
    vpoids = matlibre_dl_valeur(poids);
    unidimensionnel = matlibre_dl_est_unidimensionnel(vx, vpoids, format);
    if unidimensionnel
        vx = reshape(vx, size(vx, 1), 1, size(vx, 2), size(vx, 3));
        vpoids = reshape(vpoids, size(vpoids, 1), 1, size(vpoids, 2), size(vpoids, 3));
        pas(2) = 1;
        dilatation(2) = 1;
    end
    tailleX = [size(vx, 1), size(vx, 2)];
    noyau = [size(vpoids, 1), size(vpoids, 2)];
    bords = matlibre_dl_remplissage(remplissage, tailleX, noyau, pas, dilatation);
    if unidimensionnel
        bords(3:4) = 0;
    end
    [valeur, contexte] = matlibre_dl_convoluer(vx, vpoids, matlibre_dl_valeur(biais), ...
                                               pas, bords, dilatation);
    contexte.unidimensionnel = unidimensionnel;
    if unidimensionnel
        valeur = reshape(valeur, size(valeur, 1), size(valeur, 3), size(valeur, 4));
    end
    noeud = matlibre_bande('ajouter', 'convolution', ...
                           [matlibre_dl_noeud(x), matlibre_dl_noeud(poids), ...
                            matlibre_dl_noeud(biais)], {contexte});
    y = matlibre_dl_construire(valeur, format, noeud);
end
