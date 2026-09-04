function carte = disparitySGM(gauche, droite, varargin)
%DISPARITYSGM Carte de disparité par appariement semi-global.
%   D = DISPARITYSGM(G,D) rend, pour chaque pixel de l'image gauche, le
%   décalage horizontal qui l'apparie dans l'image droite. Les deux images
%   sont supposées rectifiées.
%
%   L'appariement bloc à bloc décide de chaque pixel isolément, ce qui le
%   rend bruyant dans les zones sans texture. L'appariement semi-global
%   ajoute un coût au changement de disparité entre voisins et propage ce
%   coût le long de plusieurs directions de balayage : chaque pixel est
%   alors décidé en tenant compte de toute une ligne, sans qu'il faille
%   pour autant optimiser l'image entière d'un coup.
%
%   La ressemblance est mesurée par la transformée de recensement, qui ne
%   retient que l'ordre des intensités : deux prises de vue d'éclairage
%   différent restent comparables.
%
%   Options et valeurs par défaut :
%     'DisparityRange'        [0 64], à valeurs entières et de largeur
%                             multiple de 16 dans MATLAB
%     'UniquenessThreshold'   15 ; un pixel dont le second meilleur coût
%                             n'est pas plus grand d'au moins ce
%                             pourcentage est déclaré non apparié (NaN)
%
%   La carte rendue est en simple précision ; elle est raffinée au
%   sous-pixel par ajustement d'une parabole sur les trois coûts autour du
%   minimum.
%
%   Exemple :
%      rng(1);
%      motif = imfilter(rand(40, 100), fspecial('gaussian', 7, 1.5), 'replicate');
%      g = motif(:, 11:80);
%      d = motif(:, 14:83);       % la même scène, vue trois colonnes plus loin
%      carte = disparitySGM(g, d, 'DisparityRange', [0 16]);
%      median(median(carte(10:30, 25:60)))      % 3
%
%   Voir aussi DISPARITYBM, RECTIFYSTEREOIMAGES, RECONSTRUCTSCENE.
    intervalle = [0 64];
    unicite = 15;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'disparityrange',      intervalle = round(double(varargin{k + 1}));
            case 'uniquenessthreshold', unicite = double(varargin{k + 1});
            otherwise
                error('vision:disparitySGM:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    G = enNiveaux(gauche);
    D = enNiveaux(droite);
    if ~isequal(size(G), size(D))
        error('vision:disparitySGM:Taille', ...
              'Les deux images doivent avoir la même taille.');
    end
    disparites = intervalle(1):intervalle(2);
    cout = matlibre_cout_recensement(G, D, disparites);
    agrege = matlibre_agreger_sgm(cout);
    carte = matlibre_disparite_finale(agrege, disparites, unicite);
end

function J = enNiveaux(I)
    J = double(I);
    if ndims(J) == 3
        J = rgb2gray(J);
    end
    if max(J(:)) > 1
        J = J / 255;
    end
end
