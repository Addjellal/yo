function [indices, deciles] = concentrationIndices(portefeuille, varargin)
%CONCENTRATIONINDICES Mesures de concentration d'un portefeuille.
%   I = CONCENTRATIONINDICES(EXPOSITIONS) rend une structure portant
%   plusieurs indices, tous calculés sur les parts relatives des
%   expositions :
%      CR   part des plus grosses expositions (une par défaut)
%      Gini inégalité de la répartition, de zéro à presque un
%      HH   indice de Herfindahl-Hirschman, somme des carrés des parts
%      HK   indice de Hannah et Kay, d'ordre réglable
%      HT   indice de Hall et Tideman
%      TE   indice d'entropie de Theil, normalisé
%
%   [I,D] = CONCENTRATIONINDICES(...) rend aussi la part cumulée détenue
%   par chaque décile, du plus gros au plus petit.
%
%   Tous valent leur minimum quand les expositions sont égales, et leur
%   maximum quand une seule contrepartie porte tout le portefeuille :
%   c'est ce qui permet de les comparer entre portefeuilles de tailles
%   différentes.
%
%   CONCENTRATIONINDICES(...,'CRIndex',K) compte les K plus grosses,
%   'HKIndex',A règle l'ordre de l'indice de Hannah et Kay (2 par défaut),
%   'ScaleIndices',false rend les indices bruts, non normalisés.
%
%   Exemple :
%      concentrationIndices([100 100 100 100])     % reparti egalement
%      concentrationIndices([400 0 0 0])           % tout sur un seul
%
%   Voir aussi ASRF, RISKCONTRIBUTION, CREDITDEFAULTCOPULA.
    rangCR = 1;
    ordreHK = 2;
    normaliser = true;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'crindex',      rangCR = round(varargin{k+1});
            case 'hkindex',      ordreHK = varargin{k+1};
            case 'scaleindices', normaliser = logical(varargin{k+1});
            otherwise
                error('risque:concentration:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    expositions = double(portefeuille(:));
    if any(expositions < 0)
        error('risque:concentration:Negatif', ...
              'Les expositions doivent être positives ou nulles.');
    end
    total = sum(expositions);
    if total <= 0
        error('risque:concentration:Total', ...
              'Le portefeuille est vide.');
    end
    parts = sort(expositions / total, 'descend');
    n = numel(parts);
    % Part des plus grosses expositions.
    rangCR = min(max(rangCR, 1), n);
    cr = sum(parts(1:rangCR));
    % Herfindahl-Hirschman, éventuellement ramené entre zéro et un.
    hh = sum(parts .^ 2);
    if normaliser && n > 1
        hhNormalise = (hh - 1 / n) / (1 - 1 / n);
    else
        hhNormalise = hh;
    end
    % Hannah et Kay : à l'ordre deux, il redonne Herfindahl-Hirschman.
    if abs(ordreHK - 1) < 1e-12
        hk = exp(-sum(parts(parts > 0) .* log(parts(parts > 0))));
        hk = 1 / hk;
    else
        hk = sum(parts .^ ordreHK) ^ (1 / (ordreHK - 1));
    end
    % Hall et Tideman : les parts sont pondérées par leur rang.
    rangs = (1:n).';
    ht = 1 / (2 * sum(rangs .* parts) - 1);
    if normaliser && n > 1
        ht = (ht - 1 / n) / (1 - 1 / n);
    end
    % Gini : deux fois l'aire entre la courbe de Lorenz et la diagonale.
    croissantes = sort(parts, 'ascend');
    gini = 2 * sum((1:n).' .* croissantes) / n - (n + 1) / n;
    if normaliser && n > 1
        gini = gini * n / (n - 1);
    end
    % Entropie de Theil, ramenée entre zéro — parts égales — et un.
    positives = parts(parts > 0);
    entropie = -sum(positives .* log(positives));
    if n > 1
        te = 1 - entropie / log(n);
    else
        te = 1;
    end
    indices = struct('CR', cr, 'Gini', gini, 'HH', hhNormalise, ...
                     'HK', hk, 'HT', ht, 'TE', te);
    if nargout > 1
        cumulees = cumsum(parts);
        deciles = zeros(1, 10);
        for j = 1:10
            rang = min(max(round(j * n / 10), 1), n);
            deciles(j) = cumulees(rang);
        end
    end
end
