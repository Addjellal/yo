function y = imrotate(x, angle, varargin)
%IMROTATE Rotation d'une image, en degrés, autour de son centre.
%   Y = IMROTATE(X,ANGLE) tourne X de ANGLE degrés dans le sens direct,
%   par plus proche voisin, et agrandit l'image pour que rien n'en sorte.
%
%   Y = IMROTATE(X,ANGLE,METHODE) où METHODE vaut 'nearest' (défaut),
%   'bilinear' ou 'bicubic'.
%   Y = IMROTATE(X,ANGLE,METHODE,CADRE) où CADRE vaut 'loose' (défaut,
%   l'image grandit) ou 'crop' (même taille, les coins sortent).
%   Y = IMROTATE(X,ANGLE,CADRE) accepte aussi le cadre seul.
%
%   La rotation se calcule à l'envers : pour chaque pixel de la sortie on
%   cherche d'où il vient dans l'entrée, et on y interpole. Faire
%   l'inverse — envoyer chaque pixel d'entrée vers sa place de sortie —
%   laisserait des trous, puisqu'une rotation ne fait pas correspondre
%   les grilles.
%
%   Les points qui viennent de l'extérieur de l'image sont mis à zéro.
%
%   Exemple :
%      I = mat2gray(peaks(100));
%      J = imrotate(I, 30, 'bilinear');
%      K = imrotate(I, 30, 'bilinear', 'crop');   % meme taille que I
%
%   Voir aussi IMRESIZE, IMTRANSLATE, IMCROP, IMWARP.
    methode = 'nearest';
    cadre = 'loose';
    for k = 1:numel(varargin)
        option = lower(char(varargin{k}));
        switch option
            case {'nearest', 'bilinear', 'bicubic'}
                methode = option;
            case {'loose', 'crop'}
                cadre = option;
            otherwise
                error('images:imrotate:Option', 'Option inconnue : %s.', option);
        end
    end
    classeEntree = class(x);
    x = double(x);
    [h, l, plans] = size(x);
    t = angle * pi / 180;
    c = cos(t);
    s = sin(t);
    if strcmp(cadre, 'crop')
        hs = h;
        ls = l;
    else
        % Les quatre coins tournés donnent l'encombrement de la sortie.
        hs = ceil(abs(h * c) + abs(l * s));
        ls = ceil(abs(h * s) + abs(l * c));
    end
    ci = (h + 1) / 2;
    cj = (l + 1) / 2;
    cis = (hs + 1) / 2;
    cjs = (ls + 1) / 2;
    [J, I] = meshgrid(1:ls, 1:hs);
    di = I - cis;
    dj = J - cjs;
    si = ci + c * di + s * dj;
    sj = cj - s * di + c * dj;
    y = zeros(hs, ls, plans);
    for p = 1:plans
        y(:, :, p) = interpolerPlan(x(:, :, p), si, sj, methode);
    end
    if ~strcmp(classeEntree, 'double')
        y = cast(y, classeEntree);
    end
end

function sortie = interpolerPlan(plan, si, sj, methode)
    [h, l] = size(plan);
    sortie = zeros(size(si));
    switch methode
        case 'nearest'
            i0 = round(si);
            j0 = round(sj);
            dedans = i0 >= 1 & i0 <= h & j0 >= 1 & j0 <= l;
            sortie(dedans) = plan(i0(dedans) + (j0(dedans) - 1) * h);
        case 'bilinear'
            sortie = interpolerVoisinage(plan, si, sj, 1, @poidsLineaire);
        case 'bicubic'
            sortie = interpolerVoisinage(plan, si, sj, 2, @poidsCubique);
    end
end

function sortie = interpolerVoisinage(plan, si, sj, portee, poidsDe)
%INTERPOLERVOISINAGE Somme pondérée des pixels voisins.
%   Le même squelette sert au bilinéaire et au bicubique : seul le noyau
%   de pondération change, et sa portée avec lui.
    [h, l] = size(plan);
    dedans = si >= 0.5 & si <= h + 0.5 & sj >= 0.5 & sj <= l + 0.5;
    sortie = zeros(size(si));
    if ~any(dedans(:))
        return
    end
    iBase = floor(si);
    jBase = floor(sj);
    fi = si - iBase;
    fj = sj - jBase;
    accumulation = zeros(size(si));
    for di = (1 - portee):portee
        pi_ = poidsDe(di - fi);
        for dj = (1 - portee):portee
            pj = poidsDe(dj - fj);
            % Les indices sortants sont ramenés au bord, puis leur
            % contribution est annulée : cela évite un test par pixel.
            ii = min(max(iBase + di, 1), h);
            jj = min(max(jBase + dj, 1), l);
            valide = (iBase + di >= 1) & (iBase + di <= h) & ...
                     (jBase + dj >= 1) & (jBase + dj <= l);
            contribution = plan(ii + (jj - 1) * h) .* pi_ .* pj;
            contribution(~valide) = 0;
            accumulation = accumulation + contribution;
        end
    end
    sortie(dedans) = accumulation(dedans);
end

function p = poidsLineaire(d)
    p = max(0, 1 - abs(d));
end

function p = poidsCubique(d)
%POIDSCUBIQUE Noyau de Keys, avec a = -0.5.
%   C'est le noyau que MATLAB emploie : il vaut un en zéro, zéro aux
%   autres entiers, et reproduit exactement les polynômes de degré un.
    a = -0.5;
    d = abs(d);
    p = zeros(size(d));
    proche = d <= 1;
    loin = d > 1 & d < 2;
    p(proche) = (a + 2) * d(proche) .^ 3 - (a + 3) * d(proche) .^ 2 + 1;
    p(loin) = a * d(loin) .^ 3 - 5 * a * d(loin) .^ 2 + 8 * a * d(loin) - 4 * a;
end
