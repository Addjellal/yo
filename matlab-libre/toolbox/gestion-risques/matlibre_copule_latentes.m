function latentes = matlibre_copule_latentes(poids, correlationFacteurs, nombre, copule, degres)
%MATLIBRE_COPULE_LATENTES Variables latentes corrélées d'un modèle de crédit.
%   Chaque contrepartie reçoit une combinaison des facteurs communs et
%   d'un choc propre, dont la somme des carrés des poids vaut un : la
%   variable obtenue est donc réduite, et sa corrélation avec celle d'une
%   autre contrepartie est le produit scalaire de leurs poids de
%   facteurs.
%
%   La copule de Student remplace la normale par une normale divisée par
%   la racine d'un khi-deux : les défauts groupés y sont plus fréquents,
%   à corrélation égale.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = size(poids, 1);
    nombreFacteurs = size(poids, 2) - 1;
    if nombreFacteurs > 0
        [L, defaut] = chol(correlationFacteurs, 'lower');
        if defaut ~= 0
            L = eye(nombreFacteurs);
        end
        facteurs = randn(nombre, nombreFacteurs) * L.';
        latentes = facteurs * poids(:, 1:nombreFacteurs).' + ...
                   randn(nombre, n) .* repmat(poids(:, end).', nombre, 1);
    else
        latentes = randn(nombre, n);
    end
    if strcmpi(copule, 't')
        % Un facteur d'échelle commun à toute une réalisation : c'est lui
        % qui crée la dépendance de queue. Les seuils, eux, sont pris dans
        % la loi de Student — il n'y a donc rien à transformer ici.
        echelle = sqrt(degres ./ matlibre_khi_deux(degres, nombre));
        latentes = latentes .* repmat(echelle, 1, n);
    end
end
