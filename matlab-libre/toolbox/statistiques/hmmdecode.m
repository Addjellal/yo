function [pEtats, logp, avant, arriere, echelle] = hmmdecode(seq, tr, e, varargin)
%HMMDECODE Probabilités a posteriori des états d'un modèle caché.
%   PSTATES = HMMDECODE(SEQ,TR,E) rend, pour chaque instant, la
%   probabilité d'être dans chaque état sachant toute la suite observée.
%   C'est l'algorithme avant-arrière.
%
%   [PSTATES,LOGPSEQ] = HMMDECODE(...) rend en outre le logarithme de la
%   probabilité de la suite.
%   [PSTATES,LOGPSEQ,FORWARD,BACKWARD,S] = HMMDECODE(...) rend les
%   variables avant et arrière, mises à l'échelle par S : c'est cette
%   mise à l'échelle qui évite que les probabilités ne s'annulent sur une
%   longue suite.
%
%   Comme dans MATLAB, le modèle part de l'état 1 avant la première
%   émission.
%
%   Exemple :
%      tr = [0.9 0.1; 0.05 0.95];
%      e  = [1/6 1/6 1/6 1/6 1/6 1/6; 0.5 0.1 0.1 0.1 0.1 0.1];
%      seq = hmmgenerate(50, tr, e);
%      p = hmmdecode(seq, tr, e);
%      all(abs(sum(p, 1) - 1) < 1e-12)     % vrai
%
%   Voir aussi HMMVITERBI, HMMGENERATE, HMMTRAIN, HMMESTIMATE.
    [symboles, ~] = lireNomsHmm(varargin{:});
    seq = indicesSymboles(seq, symboles, size(e, 2));
    tr = normaliserLignes(double(tr));
    e = normaliserLignes(double(e));
    n = size(tr, 1);
    l = numel(seq);
    % L'état de départ est certain : c'est l'état 1, avant toute
    % émission. On le porte comme un instant zéro.
    avant = zeros(n, l + 1);
    avant(1, 1) = 1;
    echelle = ones(1, l + 1);
    for k = 1:l
        colonne = (avant(:, k).' * tr).' .* e(:, seq(k));
        echelle(k + 1) = sum(colonne);
        if echelle(k + 1) == 0
            error('stats:hmmdecode:ZeroProbability', ...
                  'La suite observée est impossible avec ce modèle.');
        end
        avant(:, k + 1) = colonne / echelle(k + 1);
    end
    arriere = ones(n, l + 1);
    for k = l:-1:1
        arriere(:, k) = tr * (e(:, seq(k)) .* arriere(:, k + 1)) / echelle(k + 1);
    end
    pEtats = avant .* arriere;
    % La colonne de tête est celle de l'instant zéro : MATLAB ne la rend
    % pas, la suite commence à la première émission.
    pEtats = pEtats(:, 2:end);
    logp = sum(log(echelle));
end
