function ci = nlparci(beta, residus, varargin)
%NLPARCI Intervalles de confiance des paramètres d'un ajustement.
%   CI = NLPARCI(BETA,R,'jacobian',J) rend les intervalles de confiance à
%   95 pour cent des paramètres BETA, à partir des résidus R et de la
%   jacobienne J que rend NLINFIT.
%
%   CI = NLPARCI(BETA,R,'covar',COVB) part de la covariance des
%   paramètres plutôt que de la jacobienne. C'est la forme à préférer :
%   elle évite de refactoriser la jacobienne, et NLINFIT rend déjà COVB.
%
%   CI = NLPARCI(...,'alpha',A) change le niveau : A = 0.01 donne des
%   intervalles à 99 pour cent.
%
%   CI compte une ligne par paramètre : la borne basse, puis la haute.
%
%   L'intervalle repose sur la linéarisation du modèle autour de la
%   solution ; il n'est exact que si le modèle est peu courbé au
%   voisinage. Pour un modèle très non linéaire, un intervalle par
%   bootstrap est plus sûr.
%
%   Exemples :
%      x = (0:0.2:5)';
%      y = 2.5 * exp(-0.8 * x) + 0.01 * randn(size(x));
%      [b, r, J, covb] = nlinfit(x, y, @(p, t) p(1) * exp(-p(2) * t), [1; 1]);
%      nlparci(b, r, 'covar', covb)
%      nlparci(b, r, 'jacobian', J, 'alpha', 0.01)
%
%   Voir aussi NLINFIT, REGRESS, BOOTCI, TINV.
    alpha = 0.05;
    jacobienne = [];
    covariance = [];
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'jacobian'
                jacobienne = varargin{k + 1};
            case 'covar'
                covariance = varargin{k + 1};
            case 'alpha'
                alpha = varargin{k + 1};
            otherwise
                error('stats:nlparci:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    beta = beta(:);
    residus = residus(:);
    p = numel(beta);
    ddl = max(numel(residus) - p, 1);
    if isempty(covariance)
        if isempty(jacobienne)
            error('stats:nlparci:NoJacobian', ...
                  'NLPARCI needs either ''jacobian'' or ''covar''.');
        end
        erreurQuadratique = sum(residus .^ 2) / ddl;
        covariance = erreurQuadratique * pinv(jacobienne' * jacobienne);
    end
    erreurs = sqrt(abs(diag(covariance)));
    marge = tinv(1 - alpha / 2, ddl) * erreurs;
    ci = [beta - marge, beta + marge];
end
