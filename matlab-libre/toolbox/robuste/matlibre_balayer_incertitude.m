function [pire, valeursPires, tous] = matlibre_balayer_incertitude(parametres, cout, options)
%MATLIBRE_BALAYER_INCERTITUDE Cherche le pire cas dans le domaine des paramètres.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   WCGAIN, ROBSTAB et leurs voisines s'en servent. La recherche se fait
%   en trois temps :
%
%     1. les sommets du pavé — pour une dépendance monotone, le pire cas
%        y est, et c'est le cas le plus fréquent ;
%     2. des tirages au hasard, qui attrapent ce qui n'est pas monotone ;
%     3. une descente locale coordonnée par coordonnée depuis le meilleur
%        point trouvé, qui affine.
%
%   Le résultat est donc une borne inférieure du pire cas, exacte pour
%   une dépendance monotone. MATLAB, qui garde la forme LFT, calcule à la
%   place une borne supérieure par mu ; les deux encadrent la vérité par
%   des côtés opposés.
%
%   OPTIONS.Tirages fixe le nombre de tirages, OPTIONS.Rayon multiplie
%   l'étendue de chaque paramètre — c'est ce dont ROBSTAB se sert pour
%   chercher le rayon de robustesse.
    if nargin < 3 || isempty(options)
        options = struct();
    end
    tirages = 200;
    if isfield(options, 'Tirages') && ~isempty(options.Tirages)
        tirages = options.Tirages;
    end
    rayon = 1;
    if isfield(options, 'Rayon') && ~isempty(options.Rayon)
        rayon = options.Rayon;
    end
    n = numel(parametres);
    if n == 0
        valeursPires = struct();
        pire = cout(valeursPires);
        tous = pire;
        return
    end

    % Les bornes, dilatees du rayon demande.
    bas = zeros(1, n);
    haut = zeros(1, n);
    noms = cell(1, n);
    for k = 1:n
        noms{k} = parametres{k}.Name;
        nominal = parametres{k}.Nominal;
        bas(k) = nominal + rayon * (parametres{k}.Range(1) - nominal);
        haut(k) = nominal + rayon * (parametres{k}.Range(2) - nominal);
    end

    meilleur = -Inf;
    meilleurPoint = (bas + haut) / 2;
    evaluer = @(point) cout(matlibre_point_vers_valeurs(noms, point));

    % 1. Les sommets, quand ils ne sont pas trop nombreux.
    if n <= 12
        for masque = 0:2 ^ n - 1
            point = zeros(1, n);
            reste = masque;
            for k = 1:n
                if mod(reste, 2) == 0
                    point(k) = bas(k);
                else
                    point(k) = haut(k);
                end
                reste = floor(reste / 2);
            end
            valeur = evaluer(point);
            if valeur > meilleur
                meilleur = valeur;
                meilleurPoint = point;
            end
        end
    end
    % Le point nominal, toujours essaye.
    nominalPoint = zeros(1, n);
    for k = 1:n
        nominalPoint(k) = parametres{k}.Nominal;
    end
    valeur = evaluer(nominalPoint);
    if valeur > meilleur
        meilleur = valeur;
        meilleurPoint = nominalPoint;
    end

    % 2. Les tirages.
    for essai = 1:tirages
        point = bas + (haut - bas) .* rand(1, n);
        valeur = evaluer(point);
        if valeur > meilleur
            meilleur = valeur;
            meilleurPoint = point;
        end
    end

    % 3. La descente coordonnee par coordonnee.
    pas = (haut - bas) / 4;
    for tour = 1:40
        change = false;
        for k = 1:n
            for direction = [1, -1]
                candidat = meilleurPoint;
                candidat(k) = min(haut(k), max(bas(k), ...
                                               candidat(k) + direction * pas(k)));
                valeur = evaluer(candidat);
                if valeur > meilleur
                    meilleur = valeur;
                    meilleurPoint = candidat;
                    change = true;
                end
            end
        end
        if ~change
            pas = pas / 2;
            if max(pas ./ max(haut - bas, eps)) < 1e-6
                break
            end
        end
    end

    pire = meilleur;
    valeursPires = matlibre_point_vers_valeurs(noms, meilleurPoint);
    tous = meilleur;
end
