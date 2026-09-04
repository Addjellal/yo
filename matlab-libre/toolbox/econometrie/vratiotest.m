function [rejet, pValeur, statistique, valeurCritique, ratio] = vratiotest(serie, varargin)
%VRATIOTEST Test du rapport des variances de Lo et MacKinlay.
%   H = VRATIOTEST(Y) teste si Y est une marche aléatoire. Y est une
%   série de niveaux — des logarithmes de prix, typiquement. H vaut un
%   quand l'hypothèse de marche aléatoire est rejetée.
%
%   Sous une marche aléatoire, la variance croît proportionnellement à
%   l'horizon : celle des accroissements sur Q périodes vaut Q fois celle
%   des accroissements d'une période. Le rapport des deux doit donc valoir
%   un. S'il dépasse un, les mouvements se prolongent ; s'il reste en
%   dessous, ils se corrigent.
%
%   VRATIOTEST(...,'Period',Q) choisit l'horizon (deux par défaut),
%   'IID',true suppose les accroissements de même loi — la statistique
%   est alors plus puissante mais suppose la variance constante ; le
%   défaut, false, corrige l'hétéroscédasticité. 'Alpha',A règle le seuil
%   (0,05).
%   [H,P,STAT,CRIT,RATIO] = VRATIOTEST(...) rend la valeur p, la
%   statistique centrée réduite, la valeur critique et le rapport
%   lui-même.
%
%   Q peut être un vecteur : le test est mené pour chaque horizon.
%
%   Exemple :
%      vratiotest(cumsum(randn(1, 500)))          % 0 : marche aléatoire
%      x = filter(1, [1 -0.6], randn(1, 500));
%      vratiotest(cumsum(x))                      % 1 : mouvements liés
%
%   Voir aussi ADFTEST, KPSSTEST, LBQTEST, AUTOCORR.
    serie = double(serie(:));
    horizons = 2;
    memeLoi = false;
    alpha = 0.05;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'period', horizons = round(varargin{k+1}(:).');
            case 'iid',    memeLoi = logical(varargin{k+1});
            case 'alpha',  alpha = varargin{k+1};
            otherwise
                error('econ:vratiotest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    n = numel(serie) - 1;                % nombre d'accroissements
    if n < 4
        error('econ:vratiotest:Serie', 'La série est trop courte.');
    end
    if any(horizons < 2) || any(horizons > n)
        error('econ:vratiotest:Horizon', ...
              'Les horizons doivent rester entre deux et %d.', n);
    end
    accroissements = diff(serie);
    moyenne = (serie(end) - serie(1)) / n;
    ecarts = accroissements - moyenne;
    varianceUn = sum(ecarts .^ 2) / (n - 1);
    ratio = zeros(1, numel(horizons));
    statistique = zeros(1, numel(horizons));
    for j = 1:numel(horizons)
        q = horizons(j);
        % Variance des accroissements sur q périodes, avec le
        % dénombrement de Lo et MacKinlay qui rend l'estimateur non
        % biaisé sous la marche aléatoire.
        cumules = serie((q + 1):end) - serie(1:(end - q)) - q * moyenne;
        m = q * (n - q + 1) * (1 - q / n);
        varianceQ = sum(cumules .^ 2) / m;
        % Le dénominateur m porte déjà le facteur q : varianceQ estime la
        % variance d'une seule période, comparable à varianceUn.
        ratio(j) = varianceQ / varianceUn;
        if memeLoi
            variance = 2 * (2 * q - 1) * (q - 1) / (3 * q * n);
        else
            % Somme pondérée des covariances des carrés : la variance du
            % rapport ne dépend plus de l'homoscédasticité.
            denominateur = sum(ecarts .^ 2) ^ 2;
            variance = 0;
            for r = 1:(q - 1)
                numerateur = sum(ecarts((r + 1):n) .^ 2 .* ecarts(1:(n - r)) .^ 2);
                delta = numerateur / denominateur;
                variance = variance + (2 * (q - r) / q) ^ 2 * delta;
            end
        end
        statistique(j) = (ratio(j) - 1) / sqrt(variance);
    end
    pValeur = 2 * (1 - normcdf(abs(statistique)));
    valeurCritique = norminv(1 - alpha / 2) * ones(1, numel(horizons));
    rejet = pValeur < alpha;
end
