function b = firls(n, f, a, w, ftype)
%FIRLS Filtre RIF à phase linéaire, au sens des moindres carrés.
%   B = FIRLS(N,F,A) rend les N+1 coefficients du filtre d'ordre N dont la
%   réponse en amplitude approche le gabarit (F,A) au sens des moindres
%   carrés intégrés. F est normalisé entre 0 et 1, un pour Nyquist, et se
%   donne par paires : chaque paire ouvre et ferme une bande, où le
%   gabarit est le segment qui joint les amplitudes A des deux bords.
%   B = FIRLS(N,F,A,W) pondère les bandes, un poids par bande.
%   B = FIRLS(N,F,A,'hilbert') ou FIRLS(N,F,A,W,'hilbert') conçoit un
%   filtre antisymétrique (types III et IV) : B(k) = -B(N+2-k), et la
%   réponse vaut j A(w) exp(-j w N/2), comme celle de FIRPM.
%
%   L'erreur minimisée est l'intégrale, sur les bandes seulement, du
%   carré de l'écart pondéré : les intégrales des produits de cosinus (ou
%   de sinus) sont calculées en forme fermée, comme MATLAB, puis le
%   système normal est résolu. Ce qui sépare deux bandes n'est pas
%   contraint : ce sont les bandes de transition, où le filtre fait ce
%   qu'il veut.
%
%   Le filtre est symétrique (ou antisymétrique), donc à phase linéaire :
%   toutes les fréquences subissent le même retard de N/2 échantillons.
%   À ordre impair (type II), la réponse s'annule forcément à Nyquist ; à
%   ordre pair antisymétrique (type III), à zéro et à Nyquist.
%
%   L'option 'differentiator' de MATLAB, qui pondère l'erreur en 1/f²,
%   n'est pas encore là : FIRLS la refuse en le disant ; FIRPM la connaît.
%
%   Exemple :
%      b = firls(40, [0 0.3 0.4 1], [1 1 0 0]);
%      max(abs(b - fliplr(b)))         % nul : le filtre est symetrique
%      [h, w] = freqz(b, 1, 512);
%      max(abs(h(w / pi > 0.4)))       % petit : la bande est bien coupee
%      bh = firls(30, [0.1 0.9], [1 1], 'hilbert');   % transformateur de Hilbert
%
%   Voir aussi FIRPM, FIR1, FIR2, FREQZ.
    if nargin < 4, w = []; end
    if nargin < 5, ftype = ''; end
    if ischar(w) || isstring(w)
        ftype = w;
        w = [];
    end
    ftype = lower(char(ftype));
    if ~isscalar(n) || n < 1 || n ~= fix(n)
        error('signal:firls:Ordre', 'L''ordre N est un entier positif.');
    end
    f = double(f(:)).';
    a = double(a(:)).';
    if numel(f) ~= numel(a)
        error('signal:firls:Gabarit', 'F et A doivent avoir la même longueur.');
    end
    if mod(numel(f), 2) ~= 0 || isempty(f)
        error('signal:firls:Bandes', 'F se donne par paires : une paire par bande.');
    end
    if any(f < 0) || any(f > 1) || any(diff(f) < 0)
        error('signal:firls:Frequences', ...
              'F est croissant, entre 0 et 1 (un pour la moitié de la fréquence d''échantillonnage).');
    end
    nBandes = numel(f) / 2;
    if isempty(w)
        w = ones(1, nBandes);
    end
    w = double(w(:)).';
    if numel(w) ~= nBandes || any(w <= 0)
        error('signal:firls:Poids', 'Il faut un poids positif par bande.');
    end
    switch ftype
        case ''
            symetrique = true;
        case {'hilbert', 'h'}
            symetrique = false;
        case {'differentiator', 'd'}
            error('signal:firls:Derivateur', ...
                  ['FIRLS ne pondère pas encore l''erreur en 1/f² des dérivateurs : ' ...
                   'FIRPM(N,F,A,''differentiator'') les conçoit.']);
        otherwise
            error('signal:firls:Type', ...
                  'Le type est ''hilbert'' ou ''differentiator'', non ''%s''.', ftype);
    end
    pair = mod(n, 2) == 0;
    if symetrique && pair
        mu = (0:n / 2).';                 % type I : cos(k w)
    elseif symetrique
        mu = (0:(n - 1) / 2).' + 0.5;     % type II : cos((k + 1/2) w)
    elseif pair
        mu = (1:n / 2).';                 % type III : sin(k w)
    else
        mu = (0:(n - 1) / 2).' + 0.5;     % type IV : sin((k + 1/2) w)
    end
    somme = mu + mu.';
    difference = mu - mu.';
    G = zeros(numel(mu));
    q = zeros(numel(mu), 1);
    for s = 1:nBandes
        F1 = f(2 * s - 1); F2 = f(2 * s);
        if F2 == F1
            continue
        end
        pente = (a(2 * s) - a(2 * s - 1)) / (F2 - F1);
        origine = a(2 * s - 1) - pente * F1;
        % Primitive de cos(nu pi t) sur [0, x] : x sinc(nu x).
        P = @(nu, x) x * sinusCardinal(nu * x);
        if symetrique
            G = G + w(s) / 2 * (P(somme, F2) - P(somme, F1) + P(difference, F2) ...
                                - P(difference, F1));
            q = q + w(s) * second(mu, F1, F2, pente, origine, true);
        else
            G = G + w(s) / 2 * (P(difference, F2) - P(difference, F1) - P(somme, F2) ...
                                + P(somme, F1));
            q = q + w(s) * second(mu, F1, F2, pente, origine, false);
        end
    end
    coef = (G \ q).';
    if symetrique && pair
        b = [fliplr(coef(2:end)) / 2, coef(1), coef(2:end) / 2];
    elseif symetrique
        b = [fliplr(coef), coef] / 2;
    elseif pair
        b = [fliplr(coef) / 2, 0, -coef / 2];
    else
        b = [fliplr(coef), -coef] / 2;
    end
end

function q = second(mu, F1, F2, pente, origine, symetrique)
%SECOND Intégrales du gabarit linéaire contre chaque fonction de base.
    D1 = pente * F1 + origine;
    D2 = pente * F2 + origine;
    q = zeros(size(mu));
    for k = 1:numel(mu)
        x = mu(k) * pi;
        if symetrique && mu(k) == 0
            q(k) = origine * (F2 - F1) + pente * (F2 ^ 2 - F1 ^ 2) / 2;
        elseif symetrique
            q(k) = D2 * F2 * sinusCardinal(mu(k) * F2) - D1 * F1 * sinusCardinal(mu(k) * F1) ...
                   + pente * (cos(x * F2) - cos(x * F1)) / x ^ 2;
        else
            q(k) = -(D2 * cos(x * F2) - D1 * cos(x * F1)) / x ...
                   + pente * (sin(x * F2) - sin(x * F1)) / x ^ 2;
        end
    end
end

function y = sinusCardinal(x)
    y = ones(size(x));
    nonNul = x ~= 0;
    y(nonNul) = sin(pi * x(nonNul)) ./ (pi * x(nonNul));
end
