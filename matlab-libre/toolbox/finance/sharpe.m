function s = sharpe(rendements, sansRisque)
%SHARPE Ratio de Sharpe d'une série de rendements.
    if nargin < 2
        sansRisque = 0;
    end
    exces = rendements(:) - sansRisque;
    e = std(exces);
    if e == 0
        s = 0;
    else
        s = mean(exces) / e;
    end
end
