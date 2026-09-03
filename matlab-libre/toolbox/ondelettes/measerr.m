function [PSNR, MSE, MAXERR, L2RAT] = measerr(X, Xapp, BPS)
%MEASERR Mesures de qualité entre un signal et son approximation.
%   [PSNR,MSE,MAXERR,L2RAT] = MEASERR(X,XAPP) compare l'approximation
%   XAPP à l'original X et rend :
%     PSNR    rapport signal sur bruit de crête, en décibels
%     MSE     erreur quadratique moyenne
%     MAXERR  plus grand écart en valeur absolue
%     L2RAT   rapport des énergies, XAPP sur X
%
%   MEASERR(X,XAPP,BPS) donne le nombre de bits par échantillon, dont
%   dépend la valeur de crête : 2^BPS - 1. Par défaut, huit bits.
%
%   Le PSNR est la mesure d'usage pour juger une compression : il
%   rapporte l'erreur à la dynamique du codage, non au signal lui-même,
%   ce qui le rend comparable d'une image à l'autre.
%
%   Exemple :
%      x = double(0:255);
%      approx = x + 0.5;
%      [p, m, e, r] = measerr(x, approx);
%      m                              % 0.25
%      e                              % 0.5
%
%   Voir aussi WDENCMP, WDENOISE, WTHRESH, WPDENCMP.
    if nargin < 3 || isempty(BPS), BPS = 8; end
    X = double(X);
    Xapp = double(Xapp);
    if ~isequal(size(X), size(Xapp))
        error('wavelet:measerr:Tailles', ...
              'Les deux entrées doivent avoir la même taille.');
    end
    ecart = X(:) - Xapp(:);
    MSE = sum(ecart .^ 2) / numel(ecart);
    MAXERR = max(abs(ecart));
    energie = sum(X(:) .^ 2);
    if energie > 0
        L2RAT = sum(Xapp(:) .^ 2) / energie;
    else
        L2RAT = 0;
    end
    crete = 2 ^ BPS - 1;
    if MSE > 0
        PSNR = 10 * log10(crete ^ 2 / MSE);
    else
        PSNR = Inf;      % l'approximation est exacte
    end
end
