function stats = goodnessOfFit(y, yhat)
%GOODNESSOFFIT Indicateurs de qualité d'un ajustement.
    y = y(:);
    yhat = yhat(:);
    residus = y - yhat;
    sse = sum(residus .^ 2);
    sst = sum((y - mean(y)) .^ 2);
    stats = struct();
    stats.SSE = sse;
    stats.RMSE = sqrt(sse / numel(y));
    if sst == 0
        stats.R2 = 1;
    else
        stats.R2 = 1 - sse / sst;
    end
end
