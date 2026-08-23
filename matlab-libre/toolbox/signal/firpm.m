function [b, err, res] = firpm(n, f, a, w, genre)
%FIRPM Filtre RIF équiondulant, par l'échange de Remez.
%   B = FIRPM(N,F,A) conçoit le filtre à phase linéaire d'ordre N — donc
%   N+1 coefficients — dont l'écart maximal au gabarit est le plus petit
%   possible. F donne les bords de bande par paires, normalisés entre 0
%   et 1 où 1 est la moitié de la fréquence d'échantillonnage ; A donne
%   l'amplitude visée à chacun de ces bords.
%
%   B = FIRPM(N,F,A,W) pondère les bandes : une bande de poids double
%   verra son ondulation deux fois plus faible que les autres.
%
%   B = FIRPM(N,F,A,'hilbert') ou 'differentiator' conçoit un filtre
%   antisymétrique.
%
%   [B,ERR,RES] = FIRPM(...) rend aussi l'ondulation obtenue et une
%   structure décrivant la convergence.
%
%   Le principe est celui de Parks et McClellan : le meilleur
%   approximant au sens de Tchebychev est celui dont l'erreur pondérée
%   atteint son maximum, en alternant de signe, en au moins L+2 points.
%   On part d'un jeu de fréquences, on résout exactement l'erreur
%   d'alternance, on cherche les nouveaux extrema, et on recommence.
%
%   Exemple :
%      b = firpm(20, [0 0.3 0.5 1], [1 1 0 0]);
%
%   Voir aussi FIR1, FIR2, FIRLS.
    if nargin < 4 || isempty(w), w = ones(1, numel(f) / 2); end
    if nargin < 5, genre = 'bandpass'; end
    if (ischar(w) || isstring(w))
        genre = char(w);
        w = ones(1, numel(f) / 2);
    end
    f = double(f(:))';
    a = double(a(:))';
    w = double(w(:))';
    if mod(numel(f), 2) ~= 0 || numel(a) ~= numel(f)
        error('signal:firpm:BadBands', ...
              'F et A doivent avoir un nombre pair d''éléments, et le même.');
    end
    n = round(n);
    antisymetrique = any(strcmpi(genre, {'hilbert', 'differentiator', 'h', 'd'}));
    N = n + 1;
    % Type du filtre, et facteur Q qui porte la partie non polynomiale
    % de la réponse en amplitude.
    if ~antisymetrique
        if mod(n, 2) == 0
            type = 1;
            L = n / 2;
        else
            type = 2;
            L = (n - 1) / 2;
        end
    else
        if mod(n, 2) == 0
            type = 3;
            L = n / 2 - 1;
        else
            type = 4;
            L = (n - 1) / 2;
        end
    end
    if L < 1
        error('signal:firpm:OrderTooSmall', 'L''ordre est trop petit.');
    end
    nombreExtrema = L + 2;

    % Grille dense, seize points par coefficient dans chaque bande.
    densite = 16;
    grille = [];
    desire = [];
    poids = [];
    for bande = 1:2:numel(f)
        debut = f(bande) * pi;
        fin = f(bande + 1) * pi;
        points = max(4, ceil(densite * (L + 1) * (fin - debut) / pi));
        omega = linspace(debut, fin, points);
        pente = 0;
        if fin > debut
            pente = (a(bande + 1) - a(bande)) / (fin - debut);
        end
        grille = [grille omega];                                    %#ok<AGROW>
        desire = [desire a(bande) + pente * (omega - debut)];       %#ok<AGROW>
        poids = [poids w((bande + 1) / 2) * ones(1, points)];       %#ok<AGROW>
    end
    % Les bornes 0 et pi sont singulières pour certains types : on les
    % écarte d'un pas de grille plutôt que de diviser par zéro.
    marge = 1e-6;
    if type == 2 || type == 3
        grille(grille > pi - marge) = pi - marge;
    end
    if type == 3 || type == 4
        grille(grille < marge) = marge;
    end
    facteur = facteurQ(grille, type);
    desireReduit = desire ./ facteur;
    poidsReduit = poids .* facteur;

    % Jeu initial : extrema répartis également sur la grille.
    indices = round(linspace(1, numel(grille), nombreExtrema));
    err = 0;
    iterations = 0;
    for iterations = 1:60
        x = cos(grille(indices));
        [delta, valeurs] = resoudreAlternance(x, desireReduit(indices), ...
                                              poidsReduit(indices));
        if ~isfinite(delta)
            break
        end
        approx = interpolerBary(cos(grille), x(1:end-1), valeurs);
        erreur = poidsReduit .* (desireReduit - approx);
        nouveaux = choisirExtrema(erreur, nombreExtrema);
        err = abs(delta);
        if isequal(nouveaux, indices)
            break
        end
        indices = nouveaux;
    end
    % Réponse en amplitude sur toute la grille, facteur Q remis.
    x = cos(grille(indices));
    [delta, valeurs] = resoudreAlternance(x, desireReduit(indices), poidsReduit(indices));
    err = abs(delta);

    % Reconstruction de la réponse impulsionnelle : on échantillonne la
    % réponse en fréquence complète sur une grille assez fine pour qu'il
    % n'y ait pas de repliement, puis transformée inverse.
    nfft = 2 ^ nextpow2(8 * N);
    omega = (0:nfft-1)' * 2 * pi / nfft;
    demi = floor(nfft / 2) + 1;
    omegaDemi = omega(1:demi);
    omegaEval = omegaDemi;
    if type == 2 || type == 3
        omegaEval = min(omegaEval, pi - marge);
    end
    if type == 3 || type == 4
        omegaEval = max(omegaEval, marge);
    end
    amplitude = interpolerBary(cos(omegaEval), x(1:end-1), valeurs) .* ...
                facteurQ(omegaEval, type);
    H = zeros(nfft, 1);
    retard = exp(-1i * omegaDemi * n / 2);
    if type <= 2
        H(1:demi) = amplitude .* retard;
    else
        H(1:demi) = 1i * amplitude .* retard;
    end
    for k = demi+1:nfft
        H(k) = conj(H(nfft - k + 2));
    end
    h = real(ifft(H));
    b = h(1:N)';
    % Symétrisation exacte : la reconstruction laisse des miettes.
    if type <= 2
        b = (b + fliplr(b)) / 2;
    else
        b = (b - fliplr(b)) / 2;
    end
    res = struct('fgrid', grille(:) / pi, 'H', amplitude(:), 'error', err, ...
                 'iextr', indices(:), 'iterations', iterations);
end

function q = facteurQ(omega, type)
%FACTEURQ Partie fixe de la réponse en amplitude selon le type.
    switch type
        case 1
            q = ones(size(omega));
        case 2
            q = cos(omega / 2);
        case 3
            q = sin(omega);
        otherwise
            q = sin(omega / 2);
    end
end

function [delta, valeurs] = resoudreAlternance(x, d, w)
%RESOUDREALTERNANCE Ondulation et valeurs cibles du jeu d'extrema.
%   La condition d'alternance donne delta en forme fermée, par les poids
%   barycentriques du jeu complet.
    r = numel(x);
    b = poidsBarycentriques(x);
    haut = sum(b .* d);
    bas = 0;
    for k = 1:r
        bas = bas + b(k) * (-1) ^ (k - 1) / w(k);
    end
    delta = haut / bas;
    valeurs = d(1:r-1) - ((-1) .^ (0:r-2)) * delta ./ w(1:r-1);
end

function b = poidsBarycentriques(x)
%POIDSBARYCENTRIQUES Produits inverses des écarts, pour Lagrange.
    r = numel(x);
    b = ones(1, r);
    for k = 1:r
        produit = 1;
        for i = 1:r
            if i ~= k
                produit = produit * (x(k) - x(i));
            end
        end
        b(k) = 1 / produit;
    end
end

function y = interpolerBary(xEval, xNoeuds, valeurs)
%INTERPOLERBARY Interpolation de Lagrange sous forme barycentrique.
    b = poidsBarycentriques(xNoeuds);
    y = zeros(size(xEval));
    for indice = 1:numel(xEval)
        haut = 0;
        bas = 0;
        exact = 0;
        for k = 1:numel(xNoeuds)
            ecart = xEval(indice) - xNoeuds(k);
            if abs(ecart) < 1e-14
                exact = k;
                break
            end
            poids = b(k) / ecart;
            haut = haut + poids * valeurs(k);
            bas = bas + poids;
        end
        if exact > 0
            y(indice) = valeurs(exact);
        else
            y(indice) = haut / bas;
        end
    end
end

function indices = choisirExtrema(erreur, nombre)
%CHOISIREXTREMA Nouveaux extrema alternés de l'erreur pondérée.
%   On relève tous les extrema locaux, bornes comprises, on ne garde
%   qu'un extremum par plage de signe constant — le plus grand — puis on
%   élague les plus petits jusqu'à en avoir le compte voulu.
    n = numel(erreur);
    candidats = [];
    if n >= 2 && abs(erreur(1)) >= abs(erreur(2))
        candidats(end + 1) = 1;                        %#ok<AGROW>
    end
    for k = 2:n-1
        if (erreur(k) > erreur(k-1) && erreur(k) >= erreur(k+1)) || ...
           (erreur(k) < erreur(k-1) && erreur(k) <= erreur(k+1))
            candidats(end + 1) = k;                    %#ok<AGROW>
        end
    end
    if n >= 2 && abs(erreur(n)) >= abs(erreur(n-1))
        candidats(end + 1) = n;                        %#ok<AGROW>
    end
    if isempty(candidats)
        indices = round(linspace(1, n, nombre));
        return
    end
    % Un seul extremum par plage de même signe : le plus grand.
    gardes = candidats(1);
    for k = 2:numel(candidats)
        precedent = gardes(end);
        if sign(erreur(candidats(k))) == sign(erreur(precedent))
            if abs(erreur(candidats(k))) > abs(erreur(precedent))
                gardes(end) = candidats(k);
            end
        else
            gardes(end + 1) = candidats(k);            %#ok<AGROW>
        end
    end
    % Trop d'alternances : on retire les plus faibles par les bouts.
    while numel(gardes) > nombre
        if abs(erreur(gardes(1))) < abs(erreur(gardes(end)))
            gardes(1) = [];
        else
            gardes(end) = [];
        end
    end
    while numel(gardes) < nombre
        % Trop peu : on complète par les points les plus extrêmes non pris.
        reste = setdiff(1:n, gardes);
        [~, ordre] = sort(abs(erreur(reste)), 'descend');
        gardes = sort([gardes reste(ordre(1))]);
    end
    indices = sort(gardes);
end
