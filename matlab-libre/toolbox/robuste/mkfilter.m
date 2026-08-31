function W = mkfilter(frequence, ordre, type, ondulation)
%MKFILTER Filtre analogique passe-bas normalisé.
%   W = MKFILTER(F,N,TYPE) rend le filtre passe-bas d'ordre N et de
%   pulsation de coupure F, du type nommé :
%      'butterw'   Butterworth : gain le plus plat possible en bande
%                  passante, transition douce ;
%      'cheby'     Tchebychev de type I : transition plus raide, au prix
%                  d'une ondulation en bande passante ;
%      'bessel'    Bessel : phase la plus linéaire, transition lente ;
%      'rc'        cellules RC en cascade, la plus simple.
%
%   W = MKFILTER(F,N,'cheby',R) fixe l'ondulation à R décibels ; trois
%   par défaut.
%
%   Le filtre est rendu sous forme de modèle d'état, de gain statique un.
%   C'est la brique des pondérations de synthèse : quand une pondération
%   du premier ordre ne suffit pas à séparer deux bandes, un filtre
%   d'ordre trois ou quatre le fait.
%
%   Exemples :
%      W = mkfilter(10, 3, 'butterw');
%      abs(dcgain(W) - 1) < 1e-9
%      abs(evalfr(W, 1i * 10))         % 0.7071 : la coupure a -3 dB
%
%      bodemag(mkfilter(1, 4, 'butterw'), mkfilter(1, 4, 'cheby'));
%
%   Voir aussi MAKEWEIGHT, BUTTER, CHEBY1, BESSELF, AUGW, MIXSYN.
    if nargin < 2 || isempty(ordre)
        ordre = 1;
    end
    if nargin < 3 || isempty(type)
        type = 'butterw';
    end
    if nargin < 4 || isempty(ondulation)
        ondulation = 3;
    end
    if frequence <= 0
        error('robust:mkfilter:BadFrequency', ...
              'The cutoff frequency must be positive.');
    end
    type = lower(char(type));
    switch type
        case {'butterw', 'butter', 'b'}
            poles = polesButterworth(ordre);
        case {'cheby', 'cheby1', 'c'}
            poles = polesTchebychev(ordre, ondulation);
        case {'bessel', 'bes'}
            poles = polesBessel(ordre);
        case {'rc', 'r'}
            poles = -ones(1, ordre);
        otherwise
            error('robust:mkfilter:BadType', ...
                  'The type must be ''butterw'', ''cheby'', ''bessel'' or ''rc''.');
    end
    % On met a l'echelle de la pulsation demandee, et l'on normalise le
    % gain statique a un.
    poles = poles * frequence;
    den = real(poly(poles));
    num = den(end);
    W = ss(tf(num, den));
end

function p = polesButterworth(n)
%POLESBUTTERWORTH Les pôles sur le demi-cercle unité de gauche.
    k = 1:n;
    angles = pi * (2 * k + n - 1) / (2 * n);
    p = exp(1i * angles);
    p = p(real(p) < 0);
    if numel(p) < n
        p = [p, -1];
    end
end

function p = polesTchebychev(n, ondulationDb)
%POLESTCHEBYCHEV Les pôles sur une ellipse.
    epsilon = sqrt(10 ^ (ondulationDb / 10) - 1);
    a = asinh(1 / epsilon) / n;
    k = 1:n;
    theta = pi * (2 * k - 1) / (2 * n);
    p = -sinh(a) * sin(theta) + 1i * cosh(a) * cos(theta);
end

function p = polesBessel(n)
%POLESBESSEL Les racines du polynôme de Bessel, mises à l'échelle.
%   Le polynôme de Bessel a pour coefficients
%      a_k = (2n-k)! / (2^(n-k) k! (n-k)!)
%   Ses racines donnent un filtre dont la coupure n'est pas à un ; on la
%   ramène à un par dichotomie sur le facteur d'échelle, la réponse étant
%   décroissante en fréquence.
    coefficients = zeros(1, n + 1);
    for k = 0:n
        coefficients(n + 1 - k) = exp(gammaln(2 * n - k + 1) - ...
                                      (n - k) * log(2) - gammaln(k + 1) - ...
                                      gammaln(n - k + 1));
    end
    racines = roots(coefficients);
    racines = racines(:).';
    module = @(facteur) abs(prod(facteur * racines) / ...
                            prod(1i - facteur * racines));
    bas = 1e-6;
    haut = 1e6;
    for iteration = 1:200
        milieu = sqrt(bas * haut);
        if module(milieu) > 1 / sqrt(2)
            % La coupure est encore au-dela : on rapproche les poles.
            haut = milieu;
        else
            bas = milieu;
        end
    end
    p = sqrt(bas * haut) * racines;
end
