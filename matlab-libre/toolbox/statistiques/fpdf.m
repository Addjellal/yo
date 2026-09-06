function y = fpdf(x, d1, d2)
%FPDF Densité de la loi de Fisher.
%   Y = FPDF(X,V1,V2) rend la densité de la loi de Fisher à V1 et V2
%   degrés de liberté.
%
%   La loi de Fisher est le rapport de deux khi-deux réduits : c'est ce qui
%   en fait la loi de toutes les comparaisons de variances, donc de
%   l'analyse de la variance et des tests de significativité globale d'une
%   régression.
%
%   Elle est définie sur les x positifs, très asymétrique, et son inverse
%   suit une loi de Fisher aux degrés de liberté échangés.
%
%   Exemple :
%      fpdf(1, 10, 10)                 % le mode est proche de un
%
%   Voir aussi FCDF, FINV, NCFCDF, CHI2PDF.
    y = zeros(size(x));
    for k = 1:numel(x)
        v = x(k);
        if v <= 0
            y(k) = 0;
        else
            logNum = (d1/2) * log(d1/d2) + (d1/2 - 1) * log(v);
            logDen = ((d1 + d2)/2) * log(1 + d1 * v / d2) + ...
                     gammaln(d1/2) + gammaln(d2/2) - gammaln((d1 + d2)/2);
            y(k) = exp(logNum - logDen);
        end
    end
end
