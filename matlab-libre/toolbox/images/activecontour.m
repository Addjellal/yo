function BW = activecontour(I, masque, n, methode, varargin)
%ACTIVECONTOUR Segmentation par contour actif.
%   BW = ACTIVECONTOUR(I,MASQUE) fait évoluer le contour initial MASQUE
%   jusqu'à épouser la région de l'image. Le contour se déplace de
%   lui-même vers un équilibre entre deux exigences : que l'intérieur et
%   l'extérieur soient chacun homogènes, et que le contour reste court.
%
%   BW = ACTIVECONTOUR(I,MASQUE,N) fait N itérations (100 par défaut).
%   BW = ACTIVECONTOUR(I,MASQUE,N,'edge') attire au contraire le contour
%   vers les forts gradients ; 'Chan-Vese' (défaut) ne regarde que les
%   moyennes des deux régions, ce qui marche même sur une image floue,
%   où il n'y a pas de contour net à suivre.
%
%   ACTIVECONTOUR(...,'SmoothFactor',S) pèse la longueur du contour
%   (0,5 par défaut) ; 'ContractionBias',B le fait se resserrer quand B
%   est positif, s'étendre quand il est négatif.
%
%   Exemple :
%      I = zeros(80, 80);
%      [X, Y] = meshgrid(1:80, 1:80);
%      I((X - 40) .^ 2 + (Y - 40) .^ 2 < 400) = 1;
%      masque = false(80, 80);
%      masque(30:50, 30:50) = true;
%      BW = activecontour(I, masque, 150);
%
%   Voir aussi IMSEGKMEANS, IMBINARIZE, WATERSHED, BWBOUNDARIES, EDGE.
    if nargin < 3 || isempty(n)
        n = 100;
    end
    if nargin < 4 || isempty(methode)
        methode = 'Chan-Vese';
    end
    lissage = 0.5;
    contraction = 0;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'smoothfactor',    lissage = double(varargin{k+1});
            case 'contractionbias', contraction = double(varargin{k+1});
            otherwise
                error('images:activecontour:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    I = im2double(I);
    if size(I, 3) > 1
        I = im2gray(I);
    end
    masque = logical(masque);
    if ~isequal(size(masque), size(I))
        error('images:activecontour:Taille', ...
              'Le masque doit avoir la taille de l''image.');
    end
    % La fonction de niveau : positive dedans, négative dehors. Faire
    % évoluer une fonction plutôt qu'une courbe laisse le contour se
    % séparer ou se rejoindre tout seul.
    phi = double(masque) * 2 - 1;
    phi = imfilter(phi, fspecial('gaussian', 7, 1.5), 'replicate');
    bordEdge = strncmpi(char(methode), 'edge', 4);
    if bordEdge
        [gx, gy] = imgradientxy(imfilter(I, fspecial('gaussian', 9, 2), 'replicate'));
        force = 1 ./ (1 + gx .^ 2 + gy .^ 2);
    end
    pas = 0.5;
    for iteration = 1:n
        dedans = phi >= 0;
        if ~any(dedans(:)) || all(dedans(:))
            break;
        end
        if bordEdge
            vitesse = force .* (1 - 2 * double(~dedans)) * 0 + force;
            vitesse = vitesse - contraction;
        else
            % Chan et Vese : chaque point avance vers la région dont la
            % moyenne lui ressemble le plus.
            moyenneDedans = mean(I(dedans));
            moyenneDehors = mean(I(~dedans));
            vitesse = (I - moyenneDehors) .^ 2 - (I - moyenneDedans) .^ 2 - contraction;
        end
        % La courbure raccourcit le contour : c'est le terme de lissage.
        courbure = courbureDe(phi);
        phi = phi + pas * (vitesse + lissage * courbure);
        % Réinitialisation légère : sans elle la fonction de niveau
        % s'aplatit ou s'emballe, et le contour ne bouge plus.
        if mod(iteration, 10) == 0
            phi = imfilter(phi, fspecial('gaussian', 5, 1), 'replicate');
        end
        maximum = max(abs(phi(:)));
        if maximum > 0
            phi = phi / maximum;
        end
    end
    BW = phi >= 0;
end

function k = courbureDe(phi)
% La divergence du gradient normalisé, calculée par différences finies.
    [gx, gy] = gradient(phi);
    norme = sqrt(gx .^ 2 + gy .^ 2) + 1e-10;
    nx = gx ./ norme;
    ny = gy ./ norme;
    [nxx, ~] = gradient(nx);
    [~, nyy] = gradient(ny);
    k = nxx + nyy;
end
