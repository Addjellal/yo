function [image, coefficientsDebruites, coefficientsOrigine] = wdenoise2(x, varargin)
%WDENOISE2 Débruitage d'une image par seuillage des coefficients.
%   XD = WDENOISE2(X) débruite l'image X en la décomposant sur bior4.4,
%   au niveau le plus profond que sa taille permette, puis en seuillant
%   les détails par la règle bayésienne empirique.
%
%   XD = WDENOISE2(X,NIVEAU) impose le niveau.
%
%   XD = WDENOISE2(...,'Wavelet',NOM) change d'ondelette,
%   'DenoisingMethod',M la règle du seuil — 'Bayes' (défaut),
%   'UniversalThreshold', 'SURE' ou 'Minimax' —, 'ThresholdRule',R le
%   seuillage — 'Soft' (défaut) ou 'Hard' —, 'NoiseEstimate',E
%   l'estimation du bruit — 'LevelIndependent' (défaut) ou
%   'LevelDependent'.
%
%   [XD,CD,CO] = WDENOISE2(...) rend aussi les coefficients débruités et
%   ceux d'origine, au format de WAVEDEC2.
%
%   Une image couleur est traitée plan par plan.
%
%   Exemple :
%      propre = double(magic(64));
%      bruite = propre + 3 * randn(64);
%      xd = wdenoise2(bruite);
%      norm(xd - propre, 'fro') < norm(bruite - propre, 'fro')   % vrai
%
%   Voir aussi WDENOISE, WDENCMP, WTHCOEF2, WNOISEST, WTHRESH.
    x = double(x);
    if size(x, 3) > 1
        image = zeros(size(x));
        for plan = 1:size(x, 3)
            image(:, :, plan) = wdenoise2(x(:, :, plan), varargin{:});
        end
        coefficientsDebruites = [];
        coefficientsOrigine = [];
        return
    end
    nom = 'bior4.4';
    methode = 'bayes';
    regle = 's';
    parNiveau = false;
    niveaux = [];
    debut = 1;
    if ~isempty(varargin) && isnumeric(varargin{1})
        niveaux = round(varargin{1});
        debut = 2;
    end
    k = debut;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'wavelet',         nom = char(varargin{k+1});
            case 'denoisingmethod', methode = lower(char(varargin{k+1}));
            case 'thresholdrule'
                r = lower(char(varargin{k+1}));
                regle = r(1);
            case 'noiseestimate'
                parNiveau = strcmpi(char(varargin{k+1}), 'LevelDependent');
            otherwise
                error('wavelet:wdenoise2:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(niveaux)
        niveaux = max(1, min(wmaxlev(min(size(x)), nom), 5));
    end
    [C, S] = wavedec2(x, niveaux, nom);
    coefficientsOrigine = C;
    niveauMax = size(S, 1) - 2;
    % L'écart type du bruit se lit sur les détails du premier niveau :
    % ils sont presque tous du bruit, et la médiane résiste aux rares
    % coefficients qui portent le signal.
    sigmaGlobal = ecartType(C, S, 1);
    position = prod(S(1, :));
    for k = 1:niveauMax
        n = prod(S(k + 1, :));
        niveau = niveauMax - k + 1;
        if parNiveau
            sigma = ecartType(C, S, niveau);
        else
            sigma = sigmaGlobal;
        end
        for famille = 1:3
            plage = position + (1:n);
            C(plage) = seuiller(C(plage), sigma, methode, regle);
            position = position + n;
        end
    end
    coefficientsDebruites = C;
    image = waverec2(C, S, nom);
end

function sigma = ecartType(C, S, niveau)
%ECARTTYPE Écart type du bruit, lu sur les trois détails d'un niveau.
    detail = [];
    for famille = 1:3
        detail = [detail, detcoef2Vecteur(C, S, niveau, famille)];   %#ok<AGROW>
    end
    sigma = median(abs(detail)) / 0.6745;
end

function bloc = detcoef2Vecteur(C, S, niveau, famille)
    niveauMax = size(S, 1) - 2;
    position = prod(S(1, :));
    for k = 1:niveauMax
        n = prod(S(k + 1, :));
        if niveauMax - k + 1 == niveau
            bloc = C(position + (famille - 1) * n + (1:n));
            return
        end
        position = position + 3 * n;
    end
    bloc = [];
end

function d = seuiller(d, sigma, methode, regle)
%SEUILLER Un bloc de détails, seuillé selon la règle demandée.
    if sigma <= 0 || isempty(d)
        return
    end
    n = numel(d);
    switch methode
        case 'bayes'
            % BayesShrink : le seuil est sigma^2 / sigma_signal, où
            % l'écart type du signal se déduit de celui du bloc en
            % retranchant la variance du bruit.
            variance = max(mean(d .^ 2) - sigma ^ 2, 0);
            if variance <= 0
                seuil = max(abs(d));
            else
                seuil = sigma ^ 2 / sqrt(variance);
            end
        case 'universalthreshold'
            seuil = sigma * sqrt(2 * log(n));
        case 'sure'
            seuil = sigma * thselect(d / sigma, 'rigrsure');
        case 'minimax'
            seuil = sigma * thselect(d / sigma, 'minimaxi');
        otherwise
            error('wavelet:wdenoise2:Methode', ...
                  'Méthode inconnue : %s.', methode);
    end
    d = wthresh(d, regle, seuil);
end
