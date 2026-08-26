function r = rms(x, dim)
%RMS Valeur efficace (racine de la moyenne des carrés).
    if nargin < 2
        x = x(:);
        r = sqrt(mean(x .^ 2));
    else
        r = sqrt(mean(x .^ 2, dim));
    end
end
