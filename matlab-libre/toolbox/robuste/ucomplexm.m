function M = ucomplexm(nom, nominal, varargin)
%UCOMPLEXM Matrice complexe incertaine.
%   M = UCOMPLEXM('nom',NOMINAL) crée une matrice complexe incertaine
%   dont la valeur nominale est NOMINAL et qui peut s'en écarter, en
%   norme, du dixième de la norme de NOMINAL.
%
%   M = UCOMPLEXM('nom',NOMINAL,'Radius',R) donne le rayon en clair.
%
%   C'est l'équivalent matriciel d'UCOMPLEX : une matrice pleine dont on
%   ne connaît que l'ordre de grandeur de l'erreur. Elle correspond au
%   bloc plein complexe de l'analyse mu, celui pour lequel mu vaut
%   exactement la plus grande valeur singulière.
%
%   Exemples :
%      D = ucomplexm('D', eye(2), 'Radius', 0.2);
%      size(D)
%      usample(D)
%
%   Voir aussi UCOMPLEX, UREAL, ULTIDYN, UMAT, MUSSV.
    nominal = double(nominal);
    rayon = 0.1 * max(svd(nominal));
    if rayon == 0
        rayon = 0.1;
    end
    k = 1;
    while k + 1 <= numel(varargin)
        option = lower(char(varargin{k}));
        if strcmp(option, 'radius')
            rayon = abs(varargin{k + 1});
        elseif strcmp(option, 'percentage')
            rayon = abs(varargin{k + 1}) / 100 * max(svd(nominal));
        end
        k = k + 2;
    end
    nomChaine = char(nom);
    parametres = {struct('Name', nomChaine, 'Nominal', nominal, ...
                         'Range', [0, rayon], 'Kind', 'complexm')};
    M = umat([], parametres, @(v) v.(nomChaine), size(nominal));
end
