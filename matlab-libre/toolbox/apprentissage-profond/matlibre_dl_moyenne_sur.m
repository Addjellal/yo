function m = matlibre_dl_moyenne_sur(x, dimensions)
%MATLIBRE_DL_MOYENNE_SUR Moyenne sur plusieurs dimensions à la fois.
%   M = MATLIBRE_DL_MOYENNE_SUR(X,DIMENSIONS) réduit successivement les
%   dimensions données ; celles-ci restent présentes, de taille un, ce qui
%   permet de retrancher M de X par diffusion.
%
%   Exemple :
%      size(matlibre_dl_moyenne_sur(zeros(4, 5, 6), [1 3]))     % 1 5 1
%
%   Voir aussi BATCHNORM, LAYERNORM, GROUPNORM.
    m = x;
    for k = 1:numel(dimensions)
        m = mean(m, dimensions(k));
    end
end
