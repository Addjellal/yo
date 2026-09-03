function etats = hmmviterbi(seq, tr, e, varargin)
%HMMVITERBI Suite d'états la plus probable d'un modèle caché.
%   ETATS = HMMVITERBI(SEQ,TR,E) rend la suite d'états qui rend la suite
%   observée la plus probable — non pas l'état le plus probable à chaque
%   instant, que donne HMMDECODE, mais le chemin le plus probable dans
%   son ensemble.
%
%   Le calcul se fait en logarithmes : sur une longue suite, le produit
%   des probabilités descendrait sous le plus petit flottant.
%
%   Exemple :
%      tr = [0.95 0.05; 0.10 0.90];
%      e  = [1/6 1/6 1/6 1/6 1/6 1/6; 0.5 0.1 0.1 0.1 0.1 0.1];
%      [seq, vrais] = hmmgenerate(200, tr, e);
%      estimes = hmmviterbi(seq, tr, e);
%      mean(estimes == vrais) > 0.8
%
%   Voir aussi HMMDECODE, HMMGENERATE, HMMTRAIN, HMMESTIMATE.
    [symboles, nomsEtats] = lireNomsHmm(varargin{:});
    seq = indicesSymboles(seq, symboles, size(e, 2));
    tr = normaliserLignes(double(tr));
    e = normaliserLignes(double(e));
    n = size(tr, 1);
    l = numel(seq);
    logTr = log(tr);
    logE = log(e);
    scores = -inf(n, l);
    precedents = zeros(n, l);
    % L'état de départ est l'état 1, avant la première émission.
    scores(:, 1) = logTr(1, :).' + logE(:, seq(1));
    for k = 2:l
        for j = 1:n
            [meilleur, argument] = max(scores(:, k - 1) + logTr(:, j));
            scores(j, k) = meilleur + logE(j, seq(k));
            precedents(j, k) = argument;
        end
    end
    etats = zeros(1, l);
    [~, etats(l)] = max(scores(:, l));
    for k = l:-1:2
        etats(k - 1) = precedents(etats(k), k);
    end
    if ~isempty(nomsEtats)
        etats = nomsEtats(etats);
    end
end
