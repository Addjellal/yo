function y = evalmf(x, type, parametres)
%EVALMF Évalue une fonction d'appartenance par son nom.
%   Y = EVALMF(X,TYPE,PARAMS) où TYPE vaut 'trimf', 'trapmf', 'gaussmf',
%   'gauss2mf', 'gbellmf', 'sigmf', 'dsigmf', 'psigmf', 'zmf', 'smf',
%   'pimf', ou, pour une sortie de Sugeno, 'constant' ou 'linear'.
%
%   Exemple :
%      evalmf(0:4, 'trimf', [0 2 4])   % [0 0.5 1 0.5 0]
%
%   Voir aussi TRIMF, TRAPMF, GAUSSMF, EVALFIS.
    switch lower(char(type))
        case 'trimf'
            y = trimf(x, parametres);
        case 'trapmf'
            y = trapmf(x, parametres);
        case 'gaussmf'
            y = gaussmf(x, parametres);
        case 'gauss2mf'
            y = gauss2mf(x, parametres);
        case 'gbellmf'
            y = gbellmf(x, parametres);
        case 'sigmf'
            y = sigmf(x, parametres);
        case 'dsigmf'
            y = dsigmf(x, parametres);
        case 'psigmf'
            y = psigmf(x, parametres);
        case 'zmf'
            y = zmf(x, parametres);
        case 'smf'
            y = smf(x, parametres);
        case 'pimf'
            y = pimf(x, parametres);
        case 'constant'
            y = repmat(parametres(1), size(x));
        case 'linear'
            % Conclusion affine d'une règle de Sugeno : le dernier
            % paramètre est le terme constant.
            p = parametres(:)';
            v = double(x(:))';
            n = min(numel(v), numel(p) - 1);
            y = sum(p(1:n) .* v(1:n)) + p(end);
        otherwise
            error('fuzzy:evalmf:unknown', ...
                  'Fonction d''appartenance inconnue : ''%s''.', type);
    end
end
