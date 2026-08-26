function [contributions, risque] = riskContribution(poids, covariance)
%RISKCONTRIBUTION Contribution marginale de chaque actif au risque total.
    poids = poids(:);
    risque = sqrt(poids.' * covariance * poids);
    if risque == 0
        contributions = zeros(size(poids));
    else
        contributions = poids .* (covariance * poids) / risque;
    end
end
