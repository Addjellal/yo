function [xd, coefficientsDebruites, coefficientsOrigine] = wdenoise(x, varargin)
%WDENOISE Débruitage d'un signal par seuillage des coefficients d'ondelettes.
%   XD = WDENOISE(X) débruite X en le décomposant sur sym4, au niveau
%   MIN(FLOOR(LOG2(N)), WMAXLEV(N,'sym4')), puis en atténuant les
%   coefficients de détail par le seuillage par blocs de James et Stein.
%
%   XD = WDENOISE(X,NIVEAU) impose le niveau de décomposition.
%
%   XD = WDENOISE(...,'Wavelet',NOM) change d'ondelette.
%
%   XD = WDENOISE(...,'DenoisingMethod',M) choisit la règle qui fixe le
%   seuil :
%     'BlockJS'            seuillage par blocs (défaut)
%     'UniversalThreshold' seuil universel sqrt(2 log n) sigma
%     'SURE'               minimisation de l'estimateur sans biais du
%                          risque de Stein
%     'Minimax'            seuil minimax de Donoho et Johnstone
%     'Bayes'              seuil bayésien empirique (BayesShrink)
%     'FDR'                contrôle du taux de fausses découvertes
%
%   XD = WDENOISE(...,'ThresholdRule',R) choisit 'Soft' ou 'Hard'. La
%   méthode 'BlockJS' n'accepte que 'James-Stein', 'FDR' que 'Hard' ; les
%   autres méthodes prennent 'Soft' par défaut.
%
%   XD = WDENOISE(...,'NoiseEstimate',E) estime l'écart type du bruit une
%   fois pour toutes sur le premier niveau ('LevelIndependent', défaut)
%   ou niveau par niveau ('LevelDependent').
%
%   [XD,CD,CO] = WDENOISE(...) rend aussi les coefficients débruités et
%   les coefficients d'origine, au format de WAVEDEC.
%
%   Exemple :
%      [propre, bruite] = wnoise(3, 10, 7, 5);
%      xd = wdenoise(bruite, 'Wavelet', 'db4');
%      norm(xd - propre) < norm(bruite - propre)   % vrai
%
%   Voir aussi WDENCMP, THSELECT, WNOISEST, WTHRESH.
    estLigne = isrow(x);
    x = double(x);
    x = x(:)';
    n = numel(x);
    ondelette = 'sym4';
    methode = 'blockjs';
    regle = '';
    estimation = 'levelindependent';
    niveau = [];
    debut = 1;
    if ~isempty(varargin) && isnumeric(varargin{1})
        niveau = varargin{1};
        debut = 2;
    end
    for k = debut:2:numel(varargin)
        if k + 1 > numel(varargin)
            error('wavelet:wdenoise:PairAttendue', ...
                  'Les options vont par paires nom-valeur.');
        end
        nomOption = lower(char(varargin{k}));
        valeur = varargin{k + 1};
        switch nomOption
            case 'wavelet'
                ondelette = char(valeur);
            case 'denoisingmethod'
                methode = lower(char(valeur));
            case 'thresholdrule'
                regle = lower(char(valeur));
            case 'noiseestimate'
                estimation = lower(char(valeur));
            case 'level'
                niveau = valeur;
            otherwise
                error('wavelet:wdenoise:OptionInconnue', ...
                      'Option inconnue : %s.', nomOption);
        end
    end
    if isempty(niveau)
        niveau = min(floor(log2(max(n, 2))), max(1, wmaxlev(n, ondelette)));
    end
    niveau = max(1, round(niveau));
    if isempty(regle)
        if strcmp(methode, 'blockjs')
            regle = 'james-stein';
        elseif strcmp(methode, 'fdr')
            regle = 'hard';
        else
            regle = 'soft';
        end
    end
    if strcmp(regle, 'james-stein') && ~strcmp(methode, 'blockjs')
        error('wavelet:wdenoise:RegleIncompatible', ...
              'La règle ''James-Stein'' n''existe que pour ''BlockJS''.');
    end
    if strcmp(methode, 'blockjs') && ~strcmp(regle, 'james-stein')
        error('wavelet:wdenoise:RegleIncompatible', ...
              '''BlockJS'' n''accepte que la règle ''James-Stein''.');
    end

    [C, L] = wavedec(x, niveau, ondelette);
    coefficientsOrigine = C;
    dependant = strcmp(estimation, 'leveldependent');
    if ~dependant
        sigmaGlobal = wnoisest(C, L, 1);
    end
    position = L(1);
    for k = niveau:-1:1
        longueur = L(niveau - k + 2);
        plage = position + (1:longueur);
        detail = C(plage);
        if dependant
            sigma = median(abs(detail)) / 0.6745;
        else
            sigma = sigmaGlobal;
        end
        C(plage) = attenuer(detail, sigma, methode, regle, n);
        position = position + longueur;
    end
    coefficientsDebruites = C;
    xd = waverec(C, L, ondelette);
    if ~estLigne
        xd = xd(:);
    end
end

function d = attenuer(d, sigma, methode, regle, n)
    if sigma <= 0
        return
    end
    switch methode
        case 'blockjs'
            d = blocJamesStein(d, sigma, n);
        case 'universalthreshold'
            d = wthresh(d, lettre(regle), sigma * sqrt(2 * log(n)));
        case 'sure'
            d = wthresh(d, lettre(regle), sigma * thselect(d / sigma, 'rigrsure'));
        case 'minimax'
            d = wthresh(d, lettre(regle), sigma * thselect(d / sigma, 'minimaxi'));
        case 'bayes'
            % BayesShrink : seuil sigma^2 / sigma_signal, l'écart type du
            % signal étant ce qui reste de la variance une fois le bruit
            % retiré. Quand le bruit domine, tout le niveau tombe.
            variance = max(mean(d .^ 2) - sigma ^ 2, 0);
            if variance <= 0
                d = zeros(size(d));
            else
                d = wthresh(d, lettre(regle), sigma ^ 2 / sqrt(variance));
            end
        case 'fdr'
            d = tauxFaussesDecouvertes(d, sigma, 0.05, lettre(regle));
        otherwise
            error('wavelet:wdenoise:MethodeInconnue', ...
                  'Méthode inconnue : %s.', methode);
    end
end

function c = lettre(regle)
    if strncmp(regle, 'h', 1)
        c = 'h';
    else
        c = 's';
    end
end

function d = blocJamesStein(d, sigma, n)
%BLOCJAMESSTEIN Seuillage par blocs de Cai : on garde ou on rétrécit un
%   bloc entier selon son énergie, au lieu de décider coefficient par
%   coefficient. La constante 4.50524 est la racine de
%   lambda - log(lambda) = 3.
    lambda = 4.50524;
    taille = max(1, floor(log(max(n, 3))));
    for debut = 1:taille:numel(d)
        fin = min(debut + taille - 1, numel(d));
        bloc = d(debut:fin);
        energie = sum(bloc .^ 2);
        if energie > 0
            facteur = max(0, 1 - lambda * taille * sigma ^ 2 / energie);
        else
            facteur = 0;
        end
        d(debut:fin) = bloc * facteur;
    end
end

function d = tauxFaussesDecouvertes(d, sigma, q, sorh)
%TAUXFAUSSESDECOUVERTES Seuil d'Abramovich et Benjamini : on ordonne les
%   coefficients par significativité décroissante et on retient le plus
%   grand rang dont la valeur p reste sous k*q/m.
    m = numel(d);
    if m == 0
        return
    end
    z = abs(d) / sigma;
    p = 2 * (1 - repartitionNormale(z));
    [pTrie, ordre] = sort(p);
    seuilIndice = 0;
    for k = 1:m
        if pTrie(k) <= k * q / m
            seuilIndice = k;
        end
    end
    if seuilIndice == 0
        d = zeros(size(d));
        return
    end
    seuil = sigma * z(ordre(seuilIndice));
    d = wthresh(d, sorh, seuil);
end

function p = repartitionNormale(z)
    p = 0.5 * (1 + erf(z / sqrt(2)));
end
