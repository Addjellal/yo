function [seq, etats] = hmmgenerate(l, tr, e, varargin)
%HMMGENERATE Tire une suite d'un modèle de Markov caché.
%   [SEQ,ETATS] = HMMGENERATE(L,TR,E) tire une suite de L émissions du
%   modèle dont TR est la matrice de transition — TR(i,j) est la
%   probabilité de passer de l'état i à l'état j — et E la matrice
%   d'émission, E(i,k) étant la probabilité d'émettre le symbole k depuis
%   l'état i.
%
%   Comme dans MATLAB, le modèle part de l'état 1 avant la première
%   émission : la première transition a donc lieu avant le premier
%   symbole.
%
%   HMMGENERATE(...,'Symbols',S) nomme les symboles, HMMGENERATE(...,
%   'Statenames',N) nomme les états : la suite et les états sont alors
%   rendus sous ces noms.
%
%   Exemple :
%      tr = [0.9 0.1; 0.05 0.95];
%      e  = [1/6 1/6 1/6 1/6 1/6 1/6; 0.5 0.1 0.1 0.1 0.1 0.1];
%      [seq, etats] = hmmgenerate(100, tr, e);
%
%   Voir aussi HMMDECODE, HMMVITERBI, HMMTRAIN, HMMESTIMATE.
    [symboles, nomsEtats] = lireNomsHmm(varargin{:});
    tr = normaliserLignes(double(tr));
    e = normaliserLignes(double(e));
    n = size(tr, 1);
    m = size(e, 2);
    if size(e, 1) ~= n
        error('stats:hmmgenerate:Tailles', ...
              'Les deux matrices doivent avoir le même nombre d''états.');
    end
    l = round(l);
    seq = zeros(1, l);
    etats = zeros(1, l);
    courant = 1;
    cumulTr = cumsum(tr, 2);
    cumulE = cumsum(e, 2);
    for k = 1:l
        courant = tirer(cumulTr(courant, :), n);
        etats(k) = courant;
        seq(k) = tirer(cumulE(courant, :), m);
    end
    if ~isempty(symboles)
        seq = symboles(seq);
    end
    if ~isempty(nomsEtats)
        etats = nomsEtats(etats);
    end
end

function k = tirer(cumul, n)
% Tirage dans une loi discrète donnée par sa fonction de répartition.
    u = rand();
    k = find(cumul >= u, 1);
    if isempty(k)
        k = n;
    end
end
