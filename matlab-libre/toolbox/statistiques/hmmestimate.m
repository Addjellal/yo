function [tr, e] = hmmestimate(seq, etats, varargin)
%HMMESTIMATE Estime un modèle caché dont on connaît les états.
%   [TR,E] = HMMESTIMATE(SEQ,ETATS) compte les transitions et les
%   émissions observées, et en tire les deux matrices du modèle. C'est
%   l'estimation par maximum de vraisemblance quand les états sont
%   connus — le cas facile, dont HMMTRAIN se passe.
%
%   HMMESTIMATE(...,'Pseudotransitions',P) et 'Pseudoemissions' ajoutent
%   des comptes fictifs, ce qui évite les probabilités nulles.
%
%   Exemple :
%      tr = [0.9 0.1; 0.05 0.95];
%      e  = [1/6 1/6 1/6 1/6 1/6 1/6; 0.5 0.1 0.1 0.1 0.1 0.1];
%      [seq, etats] = hmmgenerate(5000, tr, e);
%      [trEstime, eEstime] = hmmestimate(seq, etats);
%
%   Voir aussi HMMTRAIN, HMMDECODE, HMMVITERBI, HMMGENERATE.
    pseudoTr = [];
    pseudoE = [];
    symboles = [];
    nomsEtats = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'pseudotransitions', pseudoTr = double(varargin{k+1});
            case 'pseudoemissions',   pseudoE = double(varargin{k+1});
            case 'symbols',           symboles = varargin{k+1};
            case 'statenames',        nomsEtats = varargin{k+1};
            otherwise
                error('stats:hmmestimate:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(symboles)
        indices = round(double(seq(:)).');
        m = max(indices);
    else
        m = numel(symboles);
        indices = indicesSymboles(seq, symboles, m);
    end
    if isempty(nomsEtats)
        etatsIndices = round(double(etats(:)).');
        n = max(etatsIndices);
    else
        n = numel(nomsEtats);
        etatsIndices = indicesSymboles(etats, nomsEtats, n);
    end
    comptesTr = zeros(n, n);
    comptesE = zeros(n, m);
    for k = 1:numel(indices)
        comptesE(etatsIndices(k), indices(k)) = comptesE(etatsIndices(k), indices(k)) + 1;
        if k > 1
            comptesTr(etatsIndices(k - 1), etatsIndices(k)) = ...
                comptesTr(etatsIndices(k - 1), etatsIndices(k)) + 1;
        end
    end
    if ~isempty(pseudoTr)
        comptesTr = comptesTr + pseudoTr;
    end
    if ~isempty(pseudoE)
        comptesE = comptesE + pseudoE;
    end
    tr = normaliserLignes(comptesTr);
    e = normaliserLignes(comptesE);
end
