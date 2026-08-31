function [sysr, info] = reduce(sys, ordre, varargin)
%REDUCE Réduction de modèle, toutes méthodes.
%   SYSR = REDUCE(SYS,N) réduit SYS à l'ordre N par troncature
%   équilibrée. C'est la porte d'entrée de la famille : elle appelle la
%   méthode nommée et rend le même résultat qu'elle.
%
%   SYSR = REDUCE(SYS) choisit l'ordre lui-même.
%
%   REDUCE(...,'Algorithm',A) choisit la méthode :
%      'balance'   troncature équilibrée (défaut), c'est BALANCMR ;
%      'schur'     la même par les sous-espaces, c'est SCHURMR ;
%      'hankel'    l'optimum en norme de Hankel, c'est HANKELMR ;
%      'bst'       la troncature stochastique, c'est BSTMR, qui borne
%                  l'erreur relative au lieu de l'absolue ;
%      'ncf'       la troncature des facteurs premiers normalisés, qui
%                  s'applique aussi à un modèle instable.
%
%   REDUCE(...,'MaxError',E) choisit le plus petit ordre dont la borne
%   reste sous E.
%   REDUCE(...,'Display','on') écrit les valeurs de Hankel et la borne.
%
%   [SYSR,INFO] = REDUCE(...) rend la structure d'information de la
%   méthode employée.
%
%   Exemples :
%      G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
%      reduce(G, 2);
%      reduce(G, [], 'MaxError', 0.01);
%      reduce(G, 2, 'Algorithm', 'hankel');
%
%   Voir aussi BALANCMR, SCHURMR, HANKELMR, BSTMR, NCFMR, BALRED, MODRED.
    methode = 'balance';
    affichage = false;
    reste = {};
    k = 1;
    while k <= numel(varargin)
        if (ischar(varargin{k}) || isstring(varargin{k})) && k + 1 <= numel(varargin)
            nom = lower(char(varargin{k}));
            if strcmp(nom, 'algorithm')
                methode = lower(char(varargin{k + 1}));
                k = k + 2;
                continue;
            elseif strcmp(nom, 'display')
                affichage = strcmpi(char(varargin{k + 1}), 'on');
                k = k + 2;
                continue;
            end
        end
        reste{end + 1} = varargin{k};      %#ok<AGROW>
        k = k + 1;
    end
    if nargin < 2
        ordre = [];
    end
    switch methode
        case {'balance', 'balancmr', 'bal'}
            [sysr, info] = balancmr(sys, ordre, reste{:});
        case {'schur', 'schurmr'}
            [sysr, info] = schurmr(sys, ordre, reste{:});
        case {'hankel', 'hankelmr'}
            [sysr, info] = hankelmr(sys, ordre, reste{:});
        case {'bst', 'bstmr'}
            [sysr, info] = bstmr(sys, ordre, reste{:});
        case {'ncf', 'ncfmr'}
            [sysr, info] = ncfmr(sys, ordre, reste{:});
        otherwise
            error('robust:reduce:BadAlgorithm', ...
                  'Unknown algorithm ''%s''.', methode);
    end
    if affichage
        fprintf('  valeurs de Hankel :');
        fprintf(' %.4g', info.hsv);
        fprintf('\n  ordre retenu : %d, borne d''erreur : %.4g\n', ...
                info.n, info.ErrorBound);
    end
end
