function [tr, e, logv] = hmmtrain(seqs, trGuess, eGuess, varargin)
%HMMTRAIN Estime un modèle caché dont on ne connaît pas les états.
%   [TR,E] = HMMTRAIN(SEQS,TRGUESS,EGUESS) part d'un modèle approché et
%   l'améliore par l'algorithme de Baum et Welch : chaque tour calcule
%   les probabilités a posteriori des états, puis réestime les deux
%   matrices comme si ces probabilités étaient des comptes. La
%   vraisemblance ne peut que croître.
%
%   SEQS est une suite, ou un tableau de cellules de suites.
%
%   HMMTRAIN(...,'Algorithm','Viterbi') réestime au contraire à partir du
%   seul chemin le plus probable.
%   HMMTRAIN(...,'Maxiterations',N) et 'Tolerance',T règlent l'arrêt
%   (500 et 1e-6 par défaut).
%
%   [TR,E,LOGV] = HMMTRAIN(...) rend en outre la log-vraisemblance à
%   chaque tour, ce qui permet de vérifier qu'elle croît bien.
%
%   Exemple :
%      tr = [0.95 0.05; 0.10 0.90];
%      e  = [1/6 1/6 1/6 1/6 1/6 1/6; 0.5 0.1 0.1 0.1 0.1 0.1];
%      seq = hmmgenerate(500, tr, e);
%      [trEstime, eEstime] = hmmtrain(seq, [0.9 0.1; 0.2 0.8], ...
%                                     [repmat(1/6, 1, 6); 0.4 0.12 0.12 0.12 0.12 0.12]);
%
%   Voir aussi HMMESTIMATE, HMMDECODE, HMMVITERBI, HMMGENERATE.
    maxIterations = 500;
    tolerance = 1e-6;
    algorithme = 'baumwelch';
    symboles = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'maxiterations', maxIterations = round(varargin{k+1});
            case 'tolerance',     tolerance = double(varargin{k+1});
            case 'algorithm',     algorithme = lower(char(varargin{k+1}));
            case 'symbols',       symboles = varargin{k+1};
            case 'verbose'        % accepté et sans effet
            otherwise
                error('stats:hmmtrain:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    tr = normaliserLignes(double(trGuess));
    e = normaliserLignes(double(eGuess));
    n = size(tr, 1);
    m = size(e, 2);
    if ~iscell(seqs)
        seqs = {seqs};
    end
    suites = cell(size(seqs));
    for k = 1:numel(seqs)
        suites{k} = indicesSymboles(seqs{k}, symboles, m);
    end
    logv = zeros(1, 0);
    precedente = -inf;
    for iteration = 1:maxIterations
        comptesTr = zeros(n, n);
        comptesE = zeros(n, m);
        total = 0;
        for s = 1:numel(suites)
            suite = suites{s};
            if strncmp(algorithme, 'v', 1)
                etats = hmmviterbi(suite, tr, e);
                for k = 1:numel(suite)
                    comptesE(etats(k), suite(k)) = comptesE(etats(k), suite(k)) + 1;
                    if k > 1
                        comptesTr(etats(k - 1), etats(k)) = comptesTr(etats(k - 1), etats(k)) + 1;
                    else
                        comptesTr(1, etats(k)) = comptesTr(1, etats(k)) + 1;
                    end
                end
                [~, logp] = hmmdecode(suite, tr, e);
                total = total + logp;
                continue;
            end
            [~, logp, avant, arriere, echelle] = hmmdecode(suite, tr, e);
            total = total + logp;
            l = numel(suite);
            % Les comptes attendus : pour la transition i -> j au pas k,
            % avant(i,k) * tr(i,j) * e(j,o_k) * arriere(j,k+1), le tout
            % remis à l'échelle comme l'a été le passage avant.
            for k = 1:l
                colonne = e(:, suite(k)) .* arriere(:, k + 1);
                comptesTr = comptesTr + ...
                    (avant(:, k) * colonne.') .* tr / echelle(k + 1);
                probaEtat = avant(:, k + 1) .* arriere(:, k + 1);
                comptesE(:, suite(k)) = comptesE(:, suite(k)) + probaEtat;
            end
        end
        trNouveau = normaliserLignes(comptesTr);
        eNouveau = normaliserLignes(comptesE);
        logv(end + 1) = total;   %#ok<AGROW>
        changement = max([max(abs(trNouveau(:) - tr(:))), max(abs(eNouveau(:) - e(:)))]);
        tr = trNouveau;
        e = eNouveau;
        if changement < tolerance || abs(total - precedente) < tolerance * abs(total)
            break;
        end
        precedente = total;
    end
end
