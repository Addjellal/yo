function y = pulstran(t, d, fonction, varargin)
%PULSTRAN Train d'impulsions.
%   Y = PULSTRAN(T,D,@FONC,...) somme les impulsions FONC(T-D(k)). Si D
%   a deux colonnes, la seconde donne l'amplitude de chaque impulsion.
%
%   Y = PULSTRAN(T,D,P,FS) répète le prototype échantillonné P, supposé
%   échantillonné à FS hertz, par interpolation linéaire.
%
%   Exemple :
%      t = 0:1/1e3:1;  y = pulstran(t, 0:0.1:1, @rectpuls, 0.02);
    t = double(t);
    d = double(d);
    if size(d, 2) == 1
        amplitudes = ones(size(d, 1), 1);
        retards = d(:);
    else
        retards = d(:, 1);
        amplitudes = d(:, 2);
    end
    y = zeros(size(t));
    if isa(fonction, 'function_handle') || ischar(fonction) || isstring(fonction)
        if ischar(fonction) || isstring(fonction)
            fonction = str2func(char(fonction));
        end
        for k = 1:numel(retards)
            y = y + amplitudes(k) * fonction(t - retards(k), varargin{:});
        end
    else
        prototype = double(fonction(:));
        fs = 1;
        if ~isempty(varargin), fs = varargin{1}; end
        tp = (0:numel(prototype) - 1)' / fs;
        for k = 1:numel(retards)
            y = y + amplitudes(k) * interp1(tp, prototype, t - retards(k), 'linear', 0);
        end
    end
end
