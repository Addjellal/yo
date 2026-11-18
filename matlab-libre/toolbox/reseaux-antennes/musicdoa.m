function [doas, spec, specang] = musicdoa(covmat, nsig, varargin)
%MUSICDOA Directions d'arrivée par le spectre de MUSIC.
%   DOAS = MUSICDOA(COVMAT,NSIG) cherche les NSIG pics du pseudo-spectre
%   de MUSIC (Schmidt, 1986) d'un réseau linéaire uniforme d'éléments
%   espacés d'une demi-longueur d'onde, dont COVMAT est la covariance
%   spatiale. DOAS est une ligne de NSIG angles en degrés, du pic le plus
%   haut au plus bas.
%   [DOAS,SPEC,SPECANG] = MUSICDOA(...) rend aussi le spectre et ses
%   angles.
%   Options : 'ScanAngles' (les angles balayés, croissants, -90:90 par
%   défaut) et 'ElementSpacing' (0.5 longueur d'onde par défaut).
%
%   Le spectre vaut 1 / (a' En En' a), a = STEERVEC : il diverge là où le
%   vecteur de pointage est orthogonal au sous-espace bruit En. La
%   résolution ne dépend donc plus de l'ouverture du réseau, mais du
%   rapport signal sur bruit et du nombre d'échantillons. Les directions
%   sont celles de la grille : un angle entre deux points est arrondi.
%
%   Exemple :
%      % Documentation de MATLAB.
%      covmat = sensorcov((0:10) * 0.5, [0 -12 85], db2pow(-5));
%      doas = musicdoa(covmat, 3)          % 0, 85, -12
%
%   Voir aussi ROOTMUSICDOA, ESPRITDOA, SENSORCOV, MUSICSPECTRUM.
    [covmat, d, o] = matlibre_doa_options(covmat, nsig, varargin, 'musicdoa', ...
                                          {'ScanAngles', 'ElementSpacing'});
    specang = o.ScanAngles(:).';
    if isempty(specang) || any(diff(specang) <= 0) || any(abs(specang) > 90)
        error('phased:musicdoa:Angles', ...
              'ScanAngles est un vecteur croissant d''angles entre -90 et 90 degrés.');
    end
    n = size(covmat, 1);
    [V, D] = eig(covmat);
    [~, ordre] = sort(real(diag(D)), 'ascend');
    En = V(:, ordre(1:n - nsig));
    A = steervec((0:n - 1) * d, specang);
    nul = real(sum(abs(En' * A) .^ 2, 1));
    spec = 1 ./ max(nul, realmin);
    % Les pics : maxima locaux, les bords comptant s'ils dominent leur voisin.
    gauche = [-Inf, spec(1:end - 1)];
    droite = [spec(2:end), -Inf];
    pics = find(spec > gauche & spec >= droite);
    [~, rang] = sort(spec(pics), 'descend');
    pics = pics(rang);
    if numel(pics) < nsig
        error('phased:musicdoa:Pics', ...
              'Le spectre n''a que %d pics sur la grille, pour %d signaux.', numel(pics), nsig);
    end
    doas = specang(pics(1:nsig));
end
