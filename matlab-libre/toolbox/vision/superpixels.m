function [L, nombreObtenu] = superpixels(A, nombre, varargin)
%SUPERPIXELS Découpe une image en régions homogènes de taille voisine.
%   [L,N] = SUPERPIXELS(A,NOMBRE) rend une matrice d'étiquettes qui
%   partage l'image en environ NOMBRE régions, et le nombre de régions
%   obtenu. Chaque région rassemble des pixels voisins et de couleur
%   proche : c'est un regroupement par les k-moyennes dans l'espace formé
%   de la couleur et de la position, la recherche étant limitée au
%   voisinage de chaque centre — ce qui rend le coût linéaire.
%
%   Options et valeurs par défaut :
%     'Compactness'    10 ; grand, il donne des régions carrées, petit,
%                      il colle aux contours
%     'NumIterations'  10
%     'Method'         'slic0' — la compacité s'ajuste par région — ou
%                      'slic', qui la garde fixe
%     'IsInputLab'     false ; l'image couleur est convertie en L*a*b*,
%                      où une distance vaut une différence perçue
%
%   Les régions rendues sont connexes : les morceaux détachés sont
%   rattachés à la région voisine, et les trop petits fondus dedans.
%
%   Exemple :
%      A = zeros(60, 60); A(:, 31:end) = 1;
%      [L, n] = superpixels(A, 16);
%      % le contour vertical n'est traversé par aucune région
%      all(L(:, 30) ~= L(:, 31))
%
%   Voir aussi LABELOVERLAY, BWLABEL, LABEL2RGB, PCSEGDIST.
    compacite = 10;
    iterations = 10;
    methode = 'slic0';
    dejaLab = false;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'compactness',   compacite = double(varargin{k + 1});
            case 'numiterations', iterations = round(double(varargin{k + 1}));
            case 'method',        methode = lower(char(varargin{k + 1}));
            case 'isinputlab',    dejaLab = logical(varargin{k + 1});
            otherwise
                error('vision:superpixels:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    caracteristiques = matlibre_espace_couleur(A, dejaLab);
    [h, l, plans] = size(caracteristiques);
    nombre = max(1, round(nombre));
    pas = sqrt(h * l / nombre);
    [centresX, centresY] = matlibre_grille_centres(h, l, pas);
    K = numel(centresX);
    centresCouleur = zeros(K, plans);
    [X, Y] = meshgrid(1:l, 1:h);
    % Le centre est glissé sur le pixel le moins contrasté de son carré
    % de trois : posé sur un contour, il le couperait en deux.
    contraste = matlibre_contraste_local(caracteristiques);
    for k = 1:K
        [centresY(k), centresX(k)] = ...
            matlibre_creux_local(contraste, centresY(k), centresX(k));
        for p = 1:plans
            centresCouleur(k, p) = caracteristiques(centresY(k), centresX(k), p);
        end
    end
    poidsCouleur = repmat(compacite ^ 2, K, 1);
    L = zeros(h, l);
    for tour = 1:iterations
        distanceMin = inf(h, l);
        L = zeros(h, l);
        ecartCouleurMax = zeros(K, 1);
        for k = 1:K
            lignes = max(1, round(centresY(k) - pas)):min(h, round(centresY(k) + pas));
            colonnes = max(1, round(centresX(k) - pas)):min(l, round(centresX(k) + pas));
            if isempty(lignes) || isempty(colonnes)
                continue
            end
            ecartCouleur = zeros(numel(lignes), numel(colonnes));
            for p = 1:plans
                bloc = caracteristiques(lignes, colonnes, p) - centresCouleur(k, p);
                ecartCouleur = ecartCouleur + bloc .^ 2;
            end
            ecartEspace = (X(lignes, colonnes) - centresX(k)) .^ 2 + ...
                          (Y(lignes, colonnes) - centresY(k)) .^ 2;
            distance = ecartCouleur + poidsCouleur(k) * ecartEspace / pas ^ 2;
            bloc = distanceMin(lignes, colonnes);
            meilleur = distance < bloc;
            bloc(meilleur) = distance(meilleur);
            distanceMin(lignes, colonnes) = bloc;
            etiquettes = L(lignes, colonnes);
            etiquettes(meilleur) = k;
            L(lignes, colonnes) = etiquettes;
            ecarts = ecartCouleur(meilleur);
            if ~isempty(ecarts)
                ecartCouleurMax(k) = max(ecarts);
            end
        end
        % Un pixel qu'aucune fenêtre n'a atteint prend l'étiquette du
        % centre le plus proche, sans quoi il resterait au fond.
        orphelins = L == 0;
        if any(orphelins(:))
            L = matlibre_rattacher_orphelins(L, orphelins, centresX, centresY);
        end
        [centresX, centresY, centresCouleur] = ...
            matlibre_recentrer(caracteristiques, L, K, centresX, centresY, centresCouleur);
        if strcmp(methode, 'slic0')
            % Chaque région se voit accorder la compacité qui équilibre
            % couleur et distance chez elle : c'est ce qui distingue
            % slic0 de slic, où la compacité est la même partout. Le
            % poids ne redescend jamais sous la compacité demandée, sans
            % quoi une région uniforme perdrait tout terme de distance et
            % s'étendrait jusqu'au bord de sa fenêtre.
            poidsCouleur = max(poidsCouleur, ecartCouleurMax);
        end
    end
    [L, nombreObtenu] = matlibre_regions_connexes(L, round(pas ^ 2 / 4));
end
