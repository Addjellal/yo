function y = sawtooth(t, largeur)
%SAWTOOTH Signal en dents de scie de période 2*pi.
%   Y = SAWTOOTH(T) monte de -1 à +1 sur chaque période.
%   Y = SAWTOOTH(T,LARGEUR) place le sommet à LARGEUR*2*pi.
    if nargin < 2
        largeur = 1;
    end
    phase = mod(t, 2 * pi) / (2 * pi);
    y = zeros(size(t));
    for k = 1:numel(t)
        p = phase(k);
        if largeur > 0 && p < largeur
            y(k) = 2 * p / largeur - 1;
        elseif largeur < 1
            y(k) = 1 - 2 * (p - largeur) / (1 - largeur);
        else
            y(k) = 1;
        end
    end
end
