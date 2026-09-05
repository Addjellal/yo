function [a, d] = dualtree(x, varargin)
%DUALTREE Transformée en ondelettes complexes par arbre double.
%   [A,D] = DUALTREE(X) décompose X sur deux arbres décalés d'un demi
%   échantillon. A rend les coefficients d'échelle du dernier niveau, une
%   colonne par arbre ; D est une cellule de matrices complexes, une par
%   niveau, dont la partie réelle vient du premier arbre et la partie
%   imaginaire du second.
%
%   [A,D] = DUALTREE(X,'Level',J) fixe le nombre de niveaux.
%   [A,D] = DUALTREE(X,'FilterLength',L) choisit la longueur des filtres
%   des étages suivants, 10, 14, 16 ou 18.
%
%   Le module de D{j} ne dépend presque plus du décalage du signal, ce
%   qu'aucune transformée discrète décimée ne sait faire : c'est ce que
%   les deux arbres achètent, au prix d'un facteur deux de redondance.
%
%   La reconstruction par IDUALTREE est exacte : chaque arbre est un banc
%   orthonormal, et rien n'est jeté entre les deux.
%
%   La longueur de X doit être divisible par deux puissance J.
%
%   Exemple :
%      x = randn(256, 1);
%      [a, d] = dualtree(x, 'Level', 4);
%      max(abs(idualtree(a, d) - x))          % de l'ordre de 1e-15
%
%   Voir aussi IDUALTREE, DTFILTERS, QSHIFTFILTRE, DWT.
    [x, colonne, J, longueur] = lireArgumentsDualtree(x, varargin);
    n = size(x, 1);
    if mod(n, 2 ^ J) ~= 0
        error('wavelet:dualtree:Longueur', ...
              'La longueur du signal doit être divisible par %d.', 2 ^ J);
    end
    premier = dtfilters('fsfarras');
    suivant = dtfilters(sprintf('qshift%d', find([10 14 16 18] == longueur)));
    courant = {x, x};
    d = cell(1, J);
    for niveau = 1:J
        if niveau == 1
            banc = premier;
        else
            banc = suivant;
        end
        detail = cell(1, 2);
        for arbre = 1:2
            [bas, haut] = etageAnalyse(courant{arbre}, banc{arbre});
            courant{arbre} = bas;
            detail{arbre} = haut;
        end
        d{niveau} = (detail{1} + 1i * detail{2}) / sqrt(2);
    end
    a = [courant{1}, courant{2}];
    if colonne
        return
    end
    a = a.';
    for niveau = 1:J
        d{niveau} = d{niveau}.';
    end
end

function [bas, haut] = etageAnalyse(x, banc)
    bas = filtrerDecimer(x, banc(:, 1));
    haut = filtrerDecimer(x, banc(:, 2));
end

function y = filtrerDecimer(x, filtre)
%FILTRERDECIMER Convolution circulaire puis un point sur deux.
    n = size(x, 1);
    complet = real(ifft(fft(x, [], 1) .* replierNoyau(filtre, n)));
    y = complet(1:2:end, :);
end

function noyau = replierNoyau(filtre, n)
%REPLIERNOYAU Transformée du filtre, replié si le signal est plus court.
    filtre = filtre(:);
    m = numel(filtre);
    etale = zeros(n, 1);
    for k = 1:m
        indice = mod(k - 1, n) + 1;
        etale(indice) = etale(indice) + filtre(k);
    end
    noyau = fft(etale);
end

function [x, colonne, J, longueur] = lireArgumentsDualtree(x, arguments)
    x = double(x);
    colonne = size(x, 1) > 1 || size(x, 2) == 1;
    if ~colonne
        x = x.';
    end
    n = size(x, 1);
    if mod(n, 2) ~= 0 || n < 4
        error('wavelet:dualtree:Parite', ...
              'La longueur du signal doit être paire et valoir au moins quatre.');
    end
    J = [];
    longueur = 10;
    for k = 1:2:numel(arguments)
        switch lower(char(arguments{k}))
            case 'level'
                J = round(double(arguments{k + 1}));
            case 'filterlength'
                longueur = round(double(arguments{k + 1}));
                if ~any(longueur == [10 14 16 18])
                    error('wavelet:dualtree:Filtre', ...
                          'FilterLength vaut 10, 14, 16 ou 18.');
                end
            otherwise
                error('wavelet:dualtree:Option', 'Option inconnue : %s.', ...
                      char(arguments{k}));
        end
    end
    if isempty(J)
        J = max(1, floor(log2(n)) - 3);
    end
    if J < 1
        error('wavelet:dualtree:Niveau', 'Level doit valoir au moins un.');
    end
end
