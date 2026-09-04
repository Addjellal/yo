function num = matlibre_essai_difference(fonction, A)
%MATLIBRE_ESSAI_DIFFERENCE Dérivée par différence finie centrée.
%   NUM = MATLIBRE_ESSAI_DIFFERENCE(FONCTION,A) rend la dérivée
%   approchée, terme à terme, qui sert d'étalon aux dérivées exactes.
    h = 1e-6;
    num = zeros(numel(A), 1);
    for k = 1:numel(A)
        avant = A; avant(k) = avant(k) + h;
        apres = A; apres(k) = apres(k) - h;
        num(k) = (matlibre_essai_nu(fonction, avant) - ...
                  matlibre_essai_nu(fonction, apres)) / (2 * h);
    end
end

function v = matlibre_essai_nu(fonction, A)
    r = fonction(A);
    if isa(r, 'dlarray')
        r = extractdata(r);
    end
    v = r;
end
