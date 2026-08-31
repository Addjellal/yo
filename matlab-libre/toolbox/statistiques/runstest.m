function [h, p, statistiques] = runstest(x, v, varargin)
%RUNSTEST Test des suites : l'ordre des observations est-il quelconque ?
%   H = RUNSTEST(X) teste l'hypothèse « les observations de X sont dans
%   un ordre quelconque », en comptant les suites — les plages
%   consécutives de valeurs toutes au-dessus ou toutes au-dessous de la
%   médiane. Trop peu de suites signale une tendance ou une persistance ;
%   trop de suites, une alternance.
%
%   H = RUNSTEST(X,V) compare à V au lieu de la médiane. V peut aussi
%   être 'mean' pour la moyenne, ou 'median'.
%
%   [H,P] = RUNSTEST(...) rend la probabilité critique, par
%   l'approximation normale du nombre de suites.
%   [H,P,STATS] = RUNSTEST(...) rend le nombre de suites, les effectifs
%   au-dessus et au-dessous, et la statistique centrée réduite.
%
%   RUNSTEST(...,'Alpha',A) change le seuil.
%   RUNSTEST(...,'Method','exact') calcule la probabilité exacte, par
%   dénombrement, au lieu de l'approximation normale ; c'est ce qu'il
%   faut pour de petits échantillons.
%
%   C'est le test qu'on fait sur les résidus d'une régression : s'ils
%   sont bien du bruit, leurs signes doivent alterner au hasard ; s'ils
%   forment de longues plages de même signe, le modèle a manqué quelque
%   chose.
%
%   Exemples :
%      x = repmat([1 -1], 1, 20);
%      runstest(x)                       % 1 : quarante suites, bien trop
%      runstest(1:40)                    % 1 : une seule montee, deux suites
%      runstest(randn(100, 1))           % 0 : rien a signaler
%      [h, p, s] = runstest(1:8);
%      s.nruns                           % 2
%
%   Voir aussi SIGNTEST, KSTEST, AUTOCORR, MEDIAN.
    alpha = 0.05;
    methode = 'approximate';
    if nargin < 2
        v = [];
    end
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'alpha')
            alpha = varargin{k + 1};
        elseif strcmp(nom, 'method')
            methode = lower(char(varargin{k + 1}));
        elseif strcmp(nom, 'tail')
            % accepté et sans effet : le test est bilatéral
        else
            error('stats:runstest:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    x = x(:);
    x = x(~isnan(x));
    if isempty(v)
        seuil = median(x);
    elseif ischar(v) || isstring(v)
        if strcmpi(char(v), 'mean')
            seuil = mean(x);
        else
            seuil = median(x);
        end
    else
        seuil = v;
    end
    signes = x - seuil;
    signes = signes(signes ~= 0);
    n = numel(signes);
    if n < 2
        h = 0;
        p = 1;
        statistiques = struct('nruns', 0, 'n1', 0, 'n0', 0, 'z', 0);
        return;
    end
    dessus = signes > 0;
    n1 = sum(dessus);
    n0 = n - n1;
    suites = 1 + sum(dessus(2:end) ~= dessus(1:end - 1));
    if n1 == 0 || n0 == 0
        h = 0;
        p = 1;
        statistiques = struct('nruns', suites, 'n1', n1, 'n0', n0, 'z', 0);
        return;
    end
    moyenne = 2 * n1 * n0 / n + 1;
    variance = 2 * n1 * n0 * (2 * n1 * n0 - n) / (n ^ 2 * (n - 1));
    if variance <= 0
        z = 0;
    else
        % Correction de continuité : la loi est discrète.
        ecart = suites - moyenne;
        z = (ecart - sign(ecart) * 0.5) / sqrt(variance);
    end
    if strcmp(methode, 'exact')
        p = matlibre_probabilite_suites(suites, n1, n0);
    else
        p = 2 * (1 - normcdf(abs(z)));
    end
    p = max(0, min(1, p));
    h = double(p < alpha);
    statistiques = struct('nruns', suites, 'n1', n1, 'n0', n0, 'z', z);
end
