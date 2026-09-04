function [rejet, pValeur, statistique, valeurCritique, estimations] = jcitest(Y, varargin)
%JCITEST Test de cointégration de Johansen.
%   H = JCITEST(Y) teste le rang de cointégration des colonnes de Y. Le
%   test est mené pour chaque rang possible : H(1) correspond à
%   l'hypothèse « aucune relation », H(2) à « au plus une », et ainsi de
%   suite. H(k) vaut un quand l'hypothèse est rejetée.
%
%   On lit le résultat de gauche à droite et l'on s'arrête au premier
%   rang non rejeté : c'est le nombre de relations de cointégration
%   retenu. Rejeter « aucune relation » sans rejeter « au plus une »
%   conclut à une relation.
%
%   Là où le test d'Engle et Granger passe par une régression et n'en
%   trouve qu'une, celui de Johansen les cherche toutes à la fois, par
%   une régression de rang réduit du modèle à correction d'erreur. Les
%   valeurs propres de la corrélation canonique entre les différences et
%   les niveaux retardés portent l'information : autant de valeurs
%   propres non nulles, autant de relations.
%
%   JCITEST(...,'model',M) choisit la place des termes déterministes :
%      'H2'   ni constante ni tendance
%      'H1*'  constante dans la relation de cointégration
%      'H1'   constante libre (défaut)
%      'H*'   tendance dans la relation de cointégration
%      'H'    tendance libre
%   'lags',L donne le nombre de différences retardées (zéro par défaut),
%   'test',T la statistique — 'trace' (défaut) ou 'maxeig' —,
%   'alpha',A le seuil (0,05), 'display','off' se tait.
%
%   [H,P,STAT,CRIT,MLES] = JCITEST(...) rend les valeurs p, les
%   statistiques, les valeurs critiques et, pour chaque rang, une
%   structure portant les valeurs propres, la matrice B des relations de
%   cointégration, la matrice A des vitesses d'ajustement et la
%   log-vraisemblance.
%
%   Exemple :
%      x = cumsum(randn(300, 1));
%      Y = [x + randn(300, 1), x, cumsum(randn(300, 1))];
%      jcitest(Y)        % [1 0 0] : une relation
%
%   Voir aussi EGCITEST, ADFTEST, LMCTEST.
    Y = double(Y);
    if size(Y, 1) < size(Y, 2)
        Y = Y.';
    end
    n = size(Y, 2);
    if n < 2
        error('econ:jcitest:Series', ...
              'Il faut au moins deux séries pour parler de cointégration.');
    end
    modele = 'H1';
    retards = 0;
    forme = 'trace';
    alpha = 0.05;
    affichage = true;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'model',   modele = char(varargin{k+1});
            case 'lags',    retards = round(varargin{k+1});
            case 'test',    forme = lower(char(varargin{k+1}));
            case 'alpha',   alpha = varargin{k+1};
            case 'display', affichage = ~strcmpi(char(varargin{k+1}), 'off');
            otherwise
                error('econ:jcitest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if ~any(strcmpi(forme, {'trace', 'maxeig'}))
        error('econ:jcitest:Test', ...
              'La statistique vaut ''trace'' ou ''maxeig'', pas ''%s''.', forme);
    end
    [lambda, vecteurs, Teff, ~, S00, S01] = matlibre_johansen(Y, retards, modele);
    rejet = zeros(1, n);
    pValeur = zeros(1, n);
    statistique = zeros(1, n);
    valeurCritique = zeros(1, n);
    estimations = cell(1, n);
    constante = -(Teff * n / 2) * (log(2 * pi) + 1) - (Teff / 2) * log(det(S00));
    for r = 0:(n - 1)
        restantes = lambda((r + 1):n);
        if strcmpi(forme, 'trace')
            statistique(r + 1) = -Teff * sum(log(1 - restantes));
        else
            statistique(r + 1) = -Teff * log(1 - lambda(r + 1));
        end
        [pValeur(r + 1), valeurCritique(r + 1)] = matlibre_johansen_table( ...
            statistique(r + 1), modele, n - r, forme, alpha);
        rejet(r + 1) = statistique(r + 1) > valeurCritique(r + 1);
        B = vecteurs(:, 1:r);
        A = S01 * B;
        estimations{r + 1} = struct( ...
            'rang', r, 'valeursPropres', lambda, 'B', B, 'A', A, ...
            'logL', constante - (Teff / 2) * sum(log(1 - lambda(1:r))));
    end
    if affichage
        fprintf('\nTest de cointégration de Johansen (%s, modèle %s, %d retards)\n\n', ...
                forme, modele, retards);
        fprintf('  %-4s %-6s %10s %10s %10s\n', 'r', 'rejet', 'stat', 'crit', 'p');
        for r = 0:(n - 1)
            fprintf('  %-4d %-6d %10.4f %10.4f %10.4f\n', r, rejet(r + 1), ...
                    statistique(r + 1), valeurCritique(r + 1), pValeur(r + 1));
        end
        fprintf('\n');
    end
end
