function [b, a] = stmcb(x, varargin)
%STMCB Modèle rationnel par la méthode de Steiglitz-McBride.
%   [B,A] = STMCB(H,NB,NA) rend le filtre d'ordre NB au numérateur et NA
%   au dénominateur dont la réponse impulsionnelle approche H au sens des
%   moindres carrés. Contrairement à PRONY, l'erreur minimisée est celle
%   de la sortie, non celle de l'équation : le modèle obtenu est en
%   général meilleur.
%
%   [B,A] = STMCB(Y,X,NB,NA) modélise le filtre qui transforme l'entrée X
%   en la sortie Y.
%   [B,A] = STMCB(...,NITER) fait NITER itérations (5 par défaut).
%   [B,A] = STMCB(...,NITER,AI) part du dénominateur AI.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      h = impz(b, a, 60);
%      [bb, aa] = stmcb(h, 4, 4);
%      max(abs(impz(bb, aa, 60) - h))     % très petit
%
%   Voir aussi PRONY, LEVINSON, LPC, INVFREQZ.
    x = double(x(:));
    entree = [];
    k = 1;
    if numel(varargin) >= 3 && ~isscalar(varargin{1})
        entree = double(varargin{1}(:));
        k = 2;
    end
    if numel(varargin) < k + 1
        error('signal:stmcb:Arguments', 'stmcb attend les deux ordres.');
    end
    nb = round(varargin{k});
    na = round(varargin{k + 1});
    niter = 5;
    a = [];
    if numel(varargin) >= k + 2 && ~isempty(varargin{k + 2})
        niter = round(varargin{k + 2});
    end
    if numel(varargin) >= k + 3 && ~isempty(varargin{k + 3})
        a = double(varargin{k + 3}(:));
    end
    n = numel(x);
    if isempty(entree)
        entree = [1; zeros(n - 1, 1)];
    end
    if isempty(a)
        % Le point de départ est le modèle de Prony, comme dans MATLAB.
        [~, a] = prony(x, nb, na);
        a = a(:);
    end
    b = zeros(nb + 1, 1);
    for iteration = 1:niter
        u = filter(1, a, x);
        v = filter(1, a, entree);
        C1 = convmtx(u, na + 1);
        C2 = convmtx(v, nb + 1);
        T = [-C1(1:n, 2:(na + 1)), C2(1:n, :)];
        second = C1(1:n, 1);
        solution = T \ second;
        a = [1; solution(1:na)];
        b = solution((na + 1):end);
    end
    b = b(:).';
    a = a(:).';
end
