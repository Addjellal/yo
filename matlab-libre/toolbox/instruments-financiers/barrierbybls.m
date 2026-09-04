function prix = barrierbybls(courbe, actif, typeOption, exercice, reglement, echeance, typeBarriere, barriere, remise)
%BARRIERBYBLS Prix d'une option à barrière, formule fermée.
%   P = BARRIERBYBLS(COURBE,ACTIF,TYPE,EXERCICE,REGLEMENT,ECHEANCE,
%   TYPEBARRIERE,BARRIERE,REMISE) rend le prix d'une option qui
%   s'active ou s'annule quand le cours touche la barrière.
%
%   TYPEBARRIERE vaut 'UI' entrante par le haut, 'UO' sortante par le
%   haut, 'DI' entrante par le bas, 'DO' sortante par le bas. REMISE est
%   versée si l'option ne s'active pas, ou dès qu'elle s'annule.
%
%   La formule est celle de Merton, Reiner et Rubinstein : elle décompose
%   le gain en six morceaux dont chacun a une forme fermée. La somme
%   d'une entrante et d'une sortante de mêmes paramètres, à remise nulle,
%   redonne l'option ordinaire — c'est ce qui la vérifie.
%
%   Exemple :
%      barrierbybls(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025', 'DO', 90, 0)
%
%   Voir aussi OPTSTOCKBYBLS, LOOKBACKBYBLS, ASIANBYKV.
    if nargin < 9 || isempty(remise), remise = 0; end
    if ischar(typeOption) || isstring(typeOption), typeOption = {char(typeOption)}; end
    if ischar(typeBarriere) || isstring(typeBarriere), typeBarriere = {char(typeBarriere)}; end
    exercice = double(exercice(:));
    barriere = double(barriere(:));
    remise = double(remise(:));
    echeance = matlibre_dates(echeance);
    echeance = echeance(:);
    nombre = max([numel(typeOption), numel(exercice), numel(barriere), numel(echeance)]);
    prix = zeros(nombre, 1);
    for k = 1:nombre
        genre = lower(char(typeOption{min(k, numel(typeOption))}));
        forme = upper(char(typeBarriere{min(k, numel(typeBarriere))}));
        K = exercice(min(k, numel(exercice)));
        H = barriere(min(k, numel(barriere)));
        R = remise(min(k, numel(remise)));
        fin = echeance(min(k, numel(echeance)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, fin);
        prix(k) = une(S, K, H, R, r, r - q, T, sigma, genre, forme);
    end
end

function valeur = une(S, K, H, R, r, b, T, sigma, genre, forme)
    % Barrière déjà franchie au départ : la sortante est morte et ne vaut
    % que sa remise, l'entrante est née et vaut l'option ordinaire. La
    % formule ci-dessous ne couvre que le cas où la barrière est encore
    % devant.
    dejaFranchie = (forme(1) == 'D' && H >= S) || (forme(1) == 'U' && H <= S);
    if dejaFranchie
        [achat, vente] = matlibre_bls_general(S, K, r, b, T, sigma);
        if forme(2) == 'O'
            valeur = R;
        elseif strcmp(genre, 'put')
            valeur = vente;
        else
            valeur = achat;
        end
        return
    end
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    racine = sigma * sqrt(T);
    mu = (b - sigma ^ 2 / 2) / sigma ^ 2;
    lambda = sqrt(mu ^ 2 + 2 * r / sigma ^ 2);
    x1 = log(S / K) / racine + (1 + mu) * racine;
    x2 = log(S / H) / racine + (1 + mu) * racine;
    y1 = log(H ^ 2 / (S * K)) / racine + (1 + mu) * racine;
    y2 = log(H / S) / racine + (1 + mu) * racine;
    z = log(H / S) / racine + lambda * racine;
    if strcmp(genre, 'put')
        phi = -1;
    else
        phi = 1;
    end
    if forme(1) == 'D'
        eta = 1;
    else
        eta = -1;
    end
    escompte = exp((b - r) * T);
    actualise = exp(-r * T);
    rapport = H / S;
    A = phi * S * escompte * N(phi * x1) - phi * K * actualise * N(phi * x1 - phi * racine);
    B = phi * S * escompte * N(phi * x2) - phi * K * actualise * N(phi * x2 - phi * racine);
    C = phi * S * escompte * rapport ^ (2 * (mu + 1)) * N(eta * y1) - ...
        phi * K * actualise * rapport ^ (2 * mu) * N(eta * y1 - eta * racine);
    D = phi * S * escompte * rapport ^ (2 * (mu + 1)) * N(eta * y2) - ...
        phi * K * actualise * rapport ^ (2 * mu) * N(eta * y2 - eta * racine);
    E = R * actualise * (N(eta * x2 - eta * racine) - ...
                         rapport ^ (2 * mu) * N(eta * y2 - eta * racine));
    F = R * (rapport ^ (mu + lambda) * N(eta * z) + ...
             rapport ^ (mu - lambda) * N(eta * z - 2 * eta * lambda * racine));
    superieur = K > H;
    switch forme
        case 'DI'
            if strcmp(genre, 'put')
                if superieur, valeur = B - C + D + E; else, valeur = A + E; end
            else
                if superieur, valeur = C + E; else, valeur = A - B + D + E; end
            end
        case 'UI'
            if strcmp(genre, 'put')
                if superieur, valeur = A - B + D + E; else, valeur = C + E; end
            else
                if superieur, valeur = A + E; else, valeur = B - C + D + E; end
            end
        case 'DO'
            if strcmp(genre, 'put')
                if superieur, valeur = A - B + C - D + F; else, valeur = F; end
            else
                if superieur, valeur = A - C + F; else, valeur = B - D + F; end
            end
        case 'UO'
            if strcmp(genre, 'put')
                if superieur, valeur = B - D + F; else, valeur = A - C + F; end
            else
                if superieur, valeur = F; else, valeur = A - B + C - D + F; end
            end
        otherwise
            error('finstr:barrier:Type', ...
                  'La barrière vaut ''UI'', ''UO'', ''DI'' ou ''DO'', pas ''%s''.', forme);
    end
end
