function [instants, montantes] = signalTraverses(x, t, seuil)
%SIGNALTRAVERSES Instants de traversée d'un seuil, par interpolation.
%   Rend les instants où X coupe SEUIL et, pour chacun, un booléen vrai
%   si la traversée est montante.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    x = x(:);
    t = t(:);
    instants = [];
    montantes = logical([]);
    % Un échantillon posé exactement sur le seuil appartient à
    % l'intervalle qui le précède : sans cette convention, la traversée
    % serait comptée deux fois.
    for k = 1:numel(x) - 1
        a = x(k) - seuil;
        b = x(k + 1) - seuil;
        if (a < 0 && b >= 0) || (a > 0 && b <= 0)
            if b == a
                instant = t(k);
            else
                instant = t(k) + (t(k + 1) - t(k)) * (-a) / (b - a);
            end
            instants(end + 1, 1) = instant;            %#ok<AGROW>
            montantes(end + 1, 1) = b > a;             %#ok<AGROW>
        end
    end
end
