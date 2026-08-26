function d = milliseconds(x)
%MILLISECONDS Durée en millisecondes, ou millisecondes d'une durée.
%   D = MILLISECONDS(X) construit une durée affichée en secondes.
%   X = MILLISECONDS(D) rend le nombre de millisecondes d'une durée.
    if isa(x, 'duration')
        d = x.Secondes * 1000;
    else
        d = duration.avec(double(x) / 1000, 's');
    end
end
