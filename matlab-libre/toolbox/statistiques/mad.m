function m = mad(x, drapeau)
%MAD Écart absolu moyen, ou médian si le second argument vaut 1.
    x = x(:);
    if nargin > 1 && drapeau == 1
        m = median(abs(x - median(x)));
    else
        m = mean(abs(x - mean(x)));
    end
end
