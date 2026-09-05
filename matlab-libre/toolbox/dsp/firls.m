function b = firls(n, f, m, poids)
%FIRLS Filtre RIF à phase linéaire, au sens des moindres carrés.
%   B = FIRLS(N,F,M) rend un filtre d'ordre N approchant le gabarit
%   défini par les couples (F,M). F est normalisé entre 0 et 1, un pour
%   Nyquist, et se donne par paires : chaque paire ouvre et ferme une
%   bande. M donne l'amplitude voulue aux deux bouts de chaque bande.
%   B = FIRLS(N,F,M,POIDS) pondère les bandes, un poids par bande.
%
%   Ce qui sépare deux bandes n'est pas contraint : ce sont les bandes de
%   transition, et c'est là que le filtre fait ce qu'il veut. Les inclure
%   dans l'ajustement forcerait un compromis inutile — un filtre ne peut
%   pas passer de un à zéro instantanément, et lui demander de le faire
%   dégrade les deux bandes utiles.
%
%   Le filtre est symétrique, donc à phase linéaire : toutes les
%   fréquences subissent le même retard, de N/2 échantillons. C'est ce
%   qu'on ne peut pas obtenir d'un filtre récursif, et la raison
%   principale de préférer un filtre à réponse finie.
%
%   Exemple :
%      b = firls(40, [0 0.3 0.4 1], [1 1 0 0]);
%      max(abs(b - fliplr(b)))         % nul : le filtre est symetrique
%      [h, w] = freqz(b, 1, 512);
%      max(abs(h(w / pi > 0.4)))       % petit : la bande est bien coupee
%
%   Voir aussi FIR1, FIR2, FIRPM, FREQZ.
    n = round(n);
    f = double(f(:)).';
    m = double(m(:)).';
    if numel(f) ~= numel(m)
        error('dsp:firls:Gabarit', 'F et M doivent avoir la même longueur.');
    end
    if mod(numel(f), 2) ~= 0
        error('dsp:firls:Bandes', ...
              'F se donne par paires : une paire par bande.');
    end
    nBandes = numel(f) / 2;
    if nargin < 4 || isempty(poids)
        poids = ones(1, nBandes);
    end
    poids = double(poids(:)).';
    if numel(poids) ~= nBandes
        error('dsp:firls:Poids', 'Il faut un poids par bande.');
    end
    pair = mod(n, 2) == 0;
    if pair
        % Type I : b symétrique de longueur impaire.
        %   H(w) = b(c) + 2 sum_k b(c-k) cos(k w),  c = n/2 + 1
        nLibres = n / 2 + 1;
    else
        % Type II : b symétrique de longueur paire.
        %   H(w) = 2 sum_k b(k) cos((k - 1/2) w)
        nLibres = (n + 1) / 2;
    end
    % La grille ne couvre que les bandes demandées : le reste est libre.
    parBande = max(64, ceil(1024 / nBandes));
    grille = [];
    cible = [];
    poidsGrille = [];
    for k = 1:nBandes
        bornes = f(2 * k - 1:2 * k);
        amplitudes = m(2 * k - 1:2 * k);
        points = linspace(bornes(1), bornes(2), parBande);
        if bornes(2) > bornes(1)
            valeurs = interp1(bornes, amplitudes, points);
        else
            valeurs = repmat(amplitudes(1), 1, parBande);
        end
        grille = [grille, points];                                   %#ok<AGROW>
        cible = [cible, valeurs];                                    %#ok<AGROW>
        poidsGrille = [poidsGrille, repmat(poids(k), 1, parBande)];  %#ok<AGROW>
    end
    omega = pi * grille(:);
    A = zeros(numel(omega), nLibres);
    if pair
        A(:, 1) = 1;
        for k = 1:(nLibres - 1)
            A(:, k + 1) = 2 * cos(k * omega);
        end
    else
        for k = 1:nLibres
            A(:, k) = 2 * cos((k - 0.5) * omega);
        end
    end
    racines = sqrt(poidsGrille(:));
    solution = (A .* racines) \ (cible(:) .* racines);
    if pair
        centre = solution(1);
        cotes = solution(2:end);
        b = [flipud(cotes(:)).', centre, cotes(:).'];
    else
        moitie = solution(:).';
        b = [fliplr(moitie), moitie];
    end
end
