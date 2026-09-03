function [b, nshifts] = shiftdim(x, n)
%SHIFTDIM Décalage des dimensions d'un tableau.
%   B = SHIFTDIM(X,N) décale les dimensions de X de N crans : pour N
%   positif, les N premières dimensions passent à la fin ; pour N
%   négatif, N dimensions de taille 1 sont ajoutées devant.
%
%   [B,NSHIFTS] = SHIFTDIM(X) supprime les dimensions de tête de taille 1
%   et rend leur nombre.
%
%   Exemple :
%      a = ones(1,1,3,2);
%      [b,n] = shiftdim(a);   % size(b) = [3 2], n = 2
%
%   Voir aussi PERMUTE, RESHAPE, SQUEEZE.
    t = size(x);
    if nargin < 2
        % Sans compte, on retire les dimensions de tête de taille 1 ;
        % un scalaire n'a rien à perdre.
        nshifts = 0;
        while nshifts < numel(t) - 1 && t(nshifts + 1) == 1
            nshifts = nshifts + 1;
        end
        if nshifts == 0
            b = x;
            return;
        end
        b = shiftdim(x, nshifts);
        return;
    end
    n = double(n);
    if n ~= fix(n)
        error('shiftdim:Entier', 'Le décalage doit être un entier.');
    end
    nshifts = n;
    if n == 0
        b = x;
        return;
    end
    if n > 0
        d = numel(t);
        n = mod(n, d);
        if n == 0
            b = x;
            return;
        end
        ordre = [(n+1):d, 1:n];
        b = permute(x, ordre);
        % Le décalage laisse des dimensions de queue de taille 1 : la
        % forme rendue ne les garde pas.
        b = reshape(b, tailleUtile(size(b)));
    else
        b = reshape(x, [ones(1, -n), t]);
    end
end

function t = tailleUtile(t)
% Toute forme MATLAB a au moins deux dimensions ; au-delà, les 1 de
% queue ne comptent pas.
    while numel(t) > 2 && t(end) == 1
        t(end) = [];
    end
    if numel(t) < 2
        t = [t, ones(1, 2 - numel(t))];
    end
end
