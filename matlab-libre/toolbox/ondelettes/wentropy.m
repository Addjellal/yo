function e = wentropy(x, type, parametre)
%WENTROPY Entropie d'un vecteur ou d'une matrice de coefficients.
%   E = WENTROPY(X,T) mesure la concentration de X selon le critère T :
%     'shannon'     - somme(-s log s), s = x^2 ; nulle si toute
%                     l'énergie est sur un seul coefficient, maximale si
%                     elle est répartie également
%     'log energy'  - somme(log(x^2))
%     'threshold'   - nombre de coefficients dépassant P en module
%     'sure'        - estimateur sans biais du risque de Stein, seuil P
%     'norm'        - somme(|x|^P)
%
%   E = WENTROPY(X,T,P) donne le paramètre, obligatoire pour
%   'threshold', 'sure' et 'norm'.
%
%   Ces critères sont additifs : l'entropie d'un vecteur est la somme de
%   celles de ses morceaux. C'est ce qui permet à BESTTREE de comparer un
%   nœud à ses enfants et de choisir la meilleure base.
%
%   Exemple :
%      wentropy([1 0 0 0], 'shannon')   % 0 : toute l'énergie en un point
%      wentropy([1 1 1 1] / 2, 'shannon')   % log(4) : elle est répartie
%      wentropy([3 1 0.1], 'threshold', 0.5)  % 2
%
%   Voir aussi BESTTREE, WPDEC, WPTHCOEF, WPDENCMP.
    if nargin < 2 || isempty(type), type = 'shannon'; end
    x = double(x(:)).';
    type = lower(char(type));
    switch type
        case 'shannon'
            carres = x .^ 2;
            nonNuls = carres > 0;
            e = -sum(carres(nonNuls) .* log(carres(nonNuls)));
        case {'log energy', 'logenergy', 'log'}
            carres = x .^ 2;
            nonNuls = carres > 0;
            e = sum(log(carres(nonNuls)));
        case 'threshold'
            exigerParametre(nargin, type);
            e = sum(abs(x) > parametre);
        case 'sure'
            exigerParametre(nargin, type);
            n = numel(x);
            petits = abs(x) <= parametre;
            e = n - 2 * sum(petits) + sum(min(x .^ 2, parametre ^ 2));
        case 'norm'
            exigerParametre(nargin, type);
            if parametre < 1
                error('wavelet:wentropy:Puissance', ...
                      'La puissance de la norme doit valoir au moins un.');
            end
            e = sum(abs(x) .^ parametre);
        otherwise
            error('wavelet:wentropy:Type', 'Critère inconnu : %s.', type);
    end
end

function exigerParametre(nombreArguments, type)
    if nombreArguments < 3
        error('wavelet:wentropy:Parametre', ...
              'Le critère ''%s'' demande un paramètre.', type);
    end
end
