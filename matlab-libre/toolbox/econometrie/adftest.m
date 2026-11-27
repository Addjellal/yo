function [rejet, pValeur, statistique, valeurCritique] = adftest(serie, varargin)
%ADFTEST Test de racine unitaire de Dickey-Fuller augmenté.
%   H = ADFTEST(Y) teste si Y a une racine unitaire. H vaut un quand
%   l'hypothèse est rejetée : la série est stationnaire.
%
%   ADFTEST(...,'Model',M) choisit le modèle — 'AR' sans terme
%   déterministe (défaut, comme dans MATLAB), 'ARD' avec une constante,
%   'TS' avec constante et tendance —, 'Lags',L le nombre de différences
%   retardées ajoutées à la régression (zéro par défaut), 'Test',T la
%   forme de la statistique — 't1', le rapport de Student (défaut), ou
%   't2', le coefficient normalisé —, 'Alpha',A le seuil (0,05 ; de
%   0,001 à 0,999).
%   [H,P,STAT,CRIT] = ADFTEST(...) rend la valeur p, la statistique et la
%   valeur critique. Comme dans MATLAB, elles sont interpolées dans des
%   tables de Monte-Carlo, selon la taille effective de l'échantillon —
%   le nombre d'observations de la régression ; une statistique hors des
%   tables rend une valeur p de 0,001 ou 0,999.
%
%   ADFTEST(Y,L), avec L numérique, garde la forme abrégée : L retards.
%
%   Le test régresse la différence de la série sur son niveau retardé.
%   Si ce niveau n'apporte rien, la série ne revient vers rien : elle a
%   une racine unitaire. Les différences retardées servent à blanchir les
%   résidus, faute de quoi la statistique n'a pas la loi annoncée.
%
%   Sous l'hypothèse nulle, la statistique ne suit pas une loi de
%   Student : sa loi limite est celle d'une fonctionnelle du mouvement
%   brownien, décalée vers la gauche. C'est pourquoi les valeurs
%   critiques sont si négatives.
%
%   Exemple :
%      adftest(randn(1, 200))          % 1 : pas de racine unitaire
%      adftest(cumsum(randn(1, 200)))  % 0 : il y en a une
%
%   Voir aussi PPTEST, KPSSTEST, LMCTEST, VRATIOTEST, EGCITEST.
    serie = double(serie(:));
    modele = 'ar';
    retards = 0;
    forme = 't1';
    alpha = 0.05;
    if ~isempty(varargin) && isnumeric(varargin{1})
        retards = round(varargin{1});
        varargin = varargin(2:end);
    end
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'model', modele = lower(char(varargin{k+1}));
            case 'lags',  retards = round(varargin{k+1});
            case 'test',  forme = lower(char(varargin{k+1}));
            case 'alpha', alpha = varargin{k+1};
            otherwise
                error('econ:adftest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if ~(isscalar(alpha) && alpha >= 0.001 && alpha <= 0.999)
        error('econ:adftest:Alpha', 'Alpha must be a number from 0.001 to 0.999.');
    end
    [statistique, ~] = matlibre_dickey_fuller(serie, retards, modele, forme);
    taille = numel(serie) - 1 - retards;
    [pValeur, valeurCritique] = ...
        matlibre_dickey_table(statistique, modele, alpha, forme, taille);
    rejet = statistique < valeurCritique;
end
