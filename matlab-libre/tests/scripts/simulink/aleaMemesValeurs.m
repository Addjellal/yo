% Deux relevés égaux : mêmes tailles, mêmes infinis et mêmes NaN, le reste
% au milliardième près.
function oui = aleaMemesValeurs(a, b)
    oui = isequal(size(a), size(b));
    if ~oui
        return
    end
    a = double(a(:));
    b = double(b(:));
    oui = all(a == b | (isnan(a) & isnan(b)) | abs(a - b) <= 1e-9 * max(1, abs(a)));
end
