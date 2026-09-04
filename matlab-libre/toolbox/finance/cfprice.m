function prix = cfprice(flux, dates, reglement, rendement, base, composition)
%CFPRICE Prix d'une série de flux, à partir d'un rendement.
%   P = CFPRICE(FLUX,DATES,REGLEMENT,RENDEMENT) actualise chaque flux
%   depuis sa date jusqu'à la date de règlement. La composition vaut 2
%   par défaut, la base 0.
%
%   Exemple :
%      cfprice([5 5 105], {'01-Feb-2025','01-Feb-2026','01-Feb-2027'}, ...
%              '01-Feb-2024', 0.06)
%
%   Voir aussi CFYIELD, CFDUR, CFCONV, BNDPRICE.
    if nargin < 5 || isempty(base),         base = 0;         end
    if nargin < 6 || isempty(composition),  composition = 2;  end
    numeros = matlibre_dates(dates);
    reglement = matlibre_dates(reglement);
    fractions = zeros(size(numeros));
    for k = 1:numel(numeros)
        fractions(k) = yearfrac(reglement, numeros(k), base);
    end
    prix = sum(double(flux(:)) .* ...
               matlibre_escompte(rendement, fractions(:), composition));
end
