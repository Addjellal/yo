function [prix, flux, dates] = floatbyzero(courbe, ecart, reglement, echeance, frequence, base, nominal, regleFinMois)
%FLOATBYZERO Prix de la branche variable d'un échange de taux.
%   P = FLOATBYZERO(COURBE,ECART,REGLEMENT,ECHEANCE,FREQUENCE) actualise
%   les intérêts d'une branche indexée sur le taux à terme, majoré de
%   ECART points de base.
%
%   Sans écart, la branche variable vaut la différence des facteurs
%   d'actualisation de la première et de la dernière date, multipliée par
%   le nominal : les taux à terme sont précisément ceux qui rendent cette
%   égalité vraie. C'est ce qui fait qu'une branche variable cote au pair
%   à chaque fixation.
%
%   Exemple :
%      floatbyzero(courbe, 0, '01-Jan-2024', '01-Jan-2029', 4)
%
%   Voir aussi FIXEDBYZERO, SWAPBYZERO.
    if nargin < 5 || isempty(frequence),    frequence = 1;    end
    if nargin < 6 || isempty(base),         base = courbe.Basis; end
    if nargin < 7 || isempty(nominal),      nominal = 100;    end
    if nargin < 8 || isempty(regleFinMois), regleFinMois = 1; end
    reglement = matlibre_dates(reglement);
    echeance = matlibre_dates(echeance);
    dates = matlibre_echeancier(reglement, echeance, frequence, regleFinMois).';
    facteurs = matlibre_courbe_escompte(courbe, dates);
    facteurDepart = matlibre_courbe_escompte(courbe, reglement);
    precedents = [facteurDepart(:).', facteurs(1:end-1).'];
    flux = zeros(1, numel(dates));
    precedent = reglement;
    for k = 1:numel(dates)
        duree = yearfrac(precedent, dates(k), base);
        tauxTerme = (precedents(k) / facteurs(k) - 1) / duree;
        flux(k) = nominal * (tauxTerme + ecart / 10000) * duree;
        precedent = dates(k);
    end
    prix = sum(flux(:) .* facteurs(:));
end
