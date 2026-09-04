function prix = cfbyzero(courbe, montants, dates, reglement, base)
%CFBYZERO Prix d'une série de flux, sur une courbe zéro-coupon.
%   P = CFBYZERO(COURBE,MONTANTS,DATES,REGLEMENT) actualise chaque flux
%   au taux de sa propre date, lu sur la courbe. Plusieurs séries se
%   donnent par lignes.
%
%   Exemple :
%      cfbyzero(courbe, [5 5 105], {'01-Jan-2025','01-Jan-2026','01-Jan-2027'}, ...
%               '01-Jan-2024')
%
%   Voir aussi BONDBYZERO, FIXEDBYZERO, FLOATBYZERO, SWAPBYZERO, INTENVPRICE.
    if nargin < 5 || isempty(base)
        base = courbe.Basis;
    end
    montants = double(montants);
    if isvector(montants)
        montants = montants(:).';
    end
    numeros = matlibre_dates(dates);
    if isvector(numeros)
        % Une seule suite de dates, commune à toutes les séries de flux.
        numeros = repmat(numeros(:).', size(montants, 1), 1);
    end
    if size(numeros, 2) ~= size(montants, 2)
        error('finstr:cfbyzero:Tailles', ...
              'Il faut une date par flux.');
    end
    prix = zeros(size(montants, 1), 1);
    for k = 1:size(montants, 1)
        valables = ~isnan(montants(k, :)) & montants(k, :) ~= 0;
        if ~any(valables)
            continue
        end
        facteurs = matlibre_courbe_escompte(courbe, numeros(k, valables));
        prix(k) = sum(montants(k, valables).' .* facteurs(:));
    end
end
