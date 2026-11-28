% La période du cycle limite — entre deux montées par zéro de x1, après
% le transitoire — et son amplitude.
function [periode, amplitude] = cycle110(sortie)
    t = sortie.yout{1}.Values.Time;
    x = sortie.yout{1}.Values.Data;
    k = find(x(1:end - 1) < 0 & x(2:end) >= 0 & t(1:end - 1) > 15);
    tz = t(k) - x(k) .* (t(k + 1) - t(k)) ./ (x(k + 1) - x(k));
    periode = mean(diff(tz));
    amplitude = max(x(t > 15));
end
