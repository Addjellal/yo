function W = makeweight(gainBas, croisement, gainHaut, Ts, ordre)
%MAKEWEIGHT Construit une pondération à partir de trois nombres.
%   W = MAKEWEIGHT(GBAS,WC,GHAUT) rend le filtre du premier ordre dont le
%   gain vaut GBAS en basse fréquence, GHAUT en haute, et qui traverse un
%   à la pulsation WC :
%
%      W(s) = (M s + A c) / (s + c)   avec A = GBAS, M = GHAUT et
%      c = wc * sqrt((1 - M^2) / (A^2 - 1))
%
%   C'est la façon la plus rapide d'écrire une pondération de synthèse
%   H-infini : on dit ce qu'on veut en basse fréquence, où l'on veut la
%   bande passante, et ce qu'on tolère en haute fréquence.
%
%   W = MAKEWEIGHT(GBAS,[WC,GC],GHAUT) impose en outre le gain GC à la
%   pulsation WC, au lieu du gain un.
%
%   W = MAKEWEIGHT(...,TS) rend un filtre échantillonné de période TS.
%   W = MAKEWEIGHT(...,TS,N) rend un filtre d'ordre N : les pentes sont
%   alors N fois plus raides, ce qui resserre la transition.
%
%   GBAS doit être plus petit que GHAUT pour un filtre passe-haut — celui
%   d'une pondération sur la sensibilité —, et plus grand pour un
%   passe-bas.
%
%   Exemples :
%      % Erreur statique sous 1 %, bande passante 10 rad/s, gain 2 au plus
%      W1 = makeweight(0.01, 10, 2);
%      dcgain(W1)                      % 0.01
%      abs(evalfr(W1, 1i * 10))        % 1 : le croisement
%      abs(evalfr(W1, 1i * 1e6))       % 2 : le gain en haute frequence
%
%      W2 = makeweight(0.01, 10, 2, 0, 2);   % pentes deux fois plus raides
%
%      G = ss(tf(200, [10 1]));
%      K = mixsyn(G, makeweight(0.01, 10, 2), 0.1, []);
%
%   Voir aussi MKFILTER, AUGW, MIXSYN, HINFSYN, LOOPSYN, TF.
    if nargin < 4 || isempty(Ts)
        Ts = 0;
    end
    if nargin < 5 || isempty(ordre)
        ordre = 1;
    end
    gainCroisement = 1;
    if numel(croisement) >= 2
        gainCroisement = croisement(2);
        croisement = croisement(1);
    end
    if croisement <= 0
        error('robust:makeweight:BadCrossover', ...
              'The crossover frequency must be positive.');
    end
    A = gainBas;
    M = gainHaut;
    if A == M
        error('robust:makeweight:EqualGains', ...
              'The low and high gains must differ.');
    end
    % La forme du premier ordre : W(s) = (M s + A c)/(s + c). Elle vaut A
    % en zero, M a l'infini, et l'on choisit c pour qu'elle vaille GC au
    % croisement. Le module au carre y donne
    %    c^2 (A^2 - gc^2) = wc^2 (gc^2 - M^2)
    % dont les deux membres sont de meme signe, que la ponderation soit
    % passe-haut ou passe-bas.
    wc = croisement;
    Aracine = A ^ (1 / ordre);
    Mracine = M ^ (1 / ordre);
    gcRacine = gainCroisement ^ (1 / ordre);
    denominateur = Aracine ^ 2 - gcRacine ^ 2;
    numerateur = gcRacine ^ 2 - Mracine ^ 2;
    if denominateur == 0 || numerateur / denominateur < 0
        error('robust:makeweight:BadGains', ...
              ['The crossover gain must lie strictly between the low and ' ...
               'high gains.']);
    end
    c = wc * sqrt(numerateur / denominateur);
    base = tf([Mracine, Aracine * c], [1, c]);
    W = base;
    for k = 2:ordre
        W = W * base;
    end
    if Ts ~= 0
        W = c2d(ss(W), Ts);
    end
end
