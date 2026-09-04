function prix = swaptionbyblk(courbe, typeOption, exercice, reglement, dateExercice, echeance, volatilite, frequence, base, nominal)
%SWAPTIONBYBLK Prix d'une option sur échange de taux, modèle de Black.
%   P = SWAPTIONBYBLK(COURBE,TYPE,EXERCICE,REGLEMENT,DATEEXERCICE,
%   ECHEANCE,VOLATILITE) rend le prix d'une option d'entrer, à la date
%   d'exercice, dans un échange de taux allant jusqu'à l'échéance. TYPE
%   vaut 'call' pour le payeur de fixe, 'put' pour le receveur.
%
%   L'option porte sur le taux d'échange à terme, dont la volatilité est
%   donnée. Le facteur d'actualisation est l'annuité de l'échange sous-
%   jacent : c'est elle qui transforme un taux en montant.
%
%   Payeur moins receveur vaut l'échange à terme lui-même, soit l'annuité
%   fois l'écart entre le taux à terme et le taux d'exercice.
%
%   Exemple :
%      swaptionbyblk(courbe, 'call', 0.04, '01-Jan-2024', '01-Jan-2026', ...
%                    '01-Jan-2031', 0.2, 2)
%
%   Voir aussi CAPBYBLK, FLOORBYBLK, BLKPRICE, SWAPBYZERO.
    if nargin < 8  || isempty(frequence), frequence = 2;    end
    if nargin < 9  || isempty(base),      base = courbe.Basis; end
    if nargin < 10 || isempty(nominal),   nominal = 100;    end
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    reglement = matlibre_dates(reglement);
    dateExercice = matlibre_dates(dateExercice);
    echeance = matlibre_dates(echeance);
    dates = matlibre_dates_reset(dateExercice, echeance, frequence);
    facteurs = matlibre_courbe_escompte(courbe, dates);
    precedentes = [dateExercice; dates(1:end-1).'];
    durees = zeros(numel(dates), 1);
    for k = 1:numel(dates)
        durees(k) = yearfrac(precedentes(k), dates(k), base);
    end
    annuite = sum(durees .* facteurs(:));
    facteurDebut = matlibre_courbe_escompte(courbe, dateExercice);
    tauxTerme = (facteurDebut(1) - facteurs(end)) / annuite;
    expiration = yearfrac(reglement, dateExercice, base);
    racine = volatilite * sqrt(expiration);
    d1 = (log(tauxTerme / exercice) + volatilite ^ 2 / 2 * expiration) / racine;
    d2 = d1 - racine;
    if strcmpi(typeOption, 'put')
        valeur = exercice * N(-d2) - tauxTerme * N(-d1);
    else
        valeur = tauxTerme * N(d1) - exercice * N(d2);
    end
    prix = nominal * annuite * valeur;
end
