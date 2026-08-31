function [rho, pval] = corr(x, y, varargin)
%CORR Corrélation linéaire ou de rangs entre colonnes.
%   RHO = CORR(X) rend la matrice P x P des corrélations entre les P
%   colonnes de X. La diagonale vaut 1.
%
%   RHO = CORR(X,Y) rend la matrice des corrélations entre chaque colonne
%   de X et chaque colonne de Y ; elle a autant de lignes que X a de
%   colonnes et autant de colonnes que Y en a.
%
%   [RHO,PVAL] = CORR(...) rend en outre la probabilité critique du test
%   « la corrélation vraie est nulle ». Une petite valeur — moins de 0.05
%   par exemple — signifie qu'une corrélation aussi forte serait rare si
%   les deux variables étaient sans lien.
%
%   CORR(...,'type',T) choisit la mesure :
%      'Pearson'   la corrélation linéaire ordinaire (défaut) ;
%      'Spearman'  la corrélation de Pearson sur les rangs, qui mesure
%                  une croissance conjointe même non linéaire ;
%      'Kendall'   le tau de Kendall, fondé sur les paires concordantes.
%
%   CORR diffère de CORRCOEF sur deux points : il accepte deux matrices
%   de largeurs différentes, et il connaît les rangs.
%
%   Exemples :
%      x = (1:10)';
%      corr(x, x .^ 3)                       % 0.9284 : lié, mais courbé
%      corr(x, x .^ 3, 'type', 'Spearman')   % 1 exactement : monotone
%      [r, p] = corr(randn(50, 1), randn(50, 1));   % p souvent grand
%
%   Voir aussi CORRCOEF, COV, TIEDRANK, PARTIALCORR, REGRESS.
    type = 'pearson';
    debut = 1;
    if nargin < 2
        y = [];
    elseif ischar(y) || isstring(y)
        varargin = [{y}, varargin];
        y = [];
    end
    while debut + 1 <= numel(varargin)
        nom = lower(char(varargin{debut}));
        if strcmp(nom, 'type')
            type = lower(char(varargin{debut + 1}));
        elseif strcmp(nom, 'rows') || strcmp(nom, 'tail')
            % acceptés et sans effet : MatLibre ne traite que les données
            % complètes et le test bilatéral
        else
            error('stats:corr:BadOption', 'Unknown option ''%s''.', nom);
        end
        debut = debut + 2;
    end
    if isvector(x)
        x = x(:);
    end
    if isempty(y)
        y = x;
        symetrique = true;
    else
        if isvector(y)
            y = y(:);
        end
        symetrique = false;
    end
    if size(x, 1) ~= size(y, 1)
        error('stats:corr:InputSizeMismatch', ...
              'X and Y must have the same number of rows.');
    end
    n = size(x, 1);
    p = size(x, 2);
    q = size(y, 2);
    rho = zeros(p, q);
    pval = zeros(p, q);
    for i = 1:p
        for j = 1:q
            [rho(i, j), pval(i, j)] = corrUnePaire(x(:, i), y(:, j), type, n);
        end
    end
    if symetrique
        % La diagonale vaut 1 sans arrondi, et la matrice est exactement
        % symétrique : l'ordre des sommes ne doit pas se voir.
        rho = (rho + rho') / 2;
        for i = 1:min(p, q)
            rho(i, i) = 1;
            pval(i, i) = 1;
        end
    end
end

function [r, p] = corrUnePaire(a, b, type, n)
%CORRUNEPAIRE La corrélation de deux vecteurs, et sa probabilité critique.
    switch type
        case 'pearson'
            r = pearson(a, b);
            p = probabilitePearson(r, n);
        case 'spearman'
            r = pearson(tiedrank(a), tiedrank(b));
            p = probabilitePearson(r, n);
        case 'kendall'
            [r, p] = kendall(a, b, n);
        otherwise
            error('stats:corr:UnknownType', 'Unknown correlation type ''%s''.', type);
    end
end

function r = pearson(a, b)
%PEARSON Corrélation linéaire de deux vecteurs.
    a = a - mean(a);
    b = b - mean(b);
    na = sqrt(sum(a .^ 2));
    nb = sqrt(sum(b .^ 2));
    if na == 0 || nb == 0
        r = NaN;
    else
        r = sum(a .* b) / (na * nb);
        r = max(-1, min(1, r));
    end
end

function p = probabilitePearson(r, n)
%PROBABILITEPEARSON Test bilatéral de nullité, par la loi de Student.
    if n < 3 || isnan(r)
        p = NaN;
        return;
    end
    if abs(r) >= 1
        p = 0;
        return;
    end
    t = r * sqrt((n - 2) / (1 - r ^ 2));
    p = 2 * (1 - tcdf(abs(t), n - 2));
end

function [tau, p] = kendall(a, b, n)
%KENDALL Tau-b de Kendall, et son test normal approché.
    concordantes = 0;
    discordantes = 0;
    liensA = 0;
    liensB = 0;
    for i = 1:n - 1
        for j = i + 1:n
            da = a(i) - a(j);
            db = b(i) - b(j);
            if da == 0 && db == 0
                liensA = liensA + 1;
                liensB = liensB + 1;
            elseif da == 0
                liensA = liensA + 1;
            elseif db == 0
                liensB = liensB + 1;
            elseif da * db > 0
                concordantes = concordantes + 1;
            else
                discordantes = discordantes + 1;
            end
        end
    end
    denominateur = sqrt((concordantes + discordantes + liensA) * ...
                        (concordantes + discordantes + liensB));
    if denominateur == 0
        tau = NaN;
        p = NaN;
        return;
    end
    tau = (concordantes - discordantes) / denominateur;
    if n < 3
        p = NaN;
        return;
    end
    variance = 2 * (2 * n + 5) / (9 * n * (n - 1));
    p = 2 * (1 - normcdf(abs(tau) / sqrt(variance)));
end
