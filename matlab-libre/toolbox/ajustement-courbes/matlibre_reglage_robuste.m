function reglage = matlibre_reglage_robuste(nom)
%MATLIBRE_REGLAGE_ROBUSTE Fonction de poids d'un ajustement robuste.
%   R = MATLIBRE_REGLAGE_ROBUSTE(NOM) rend le genre et la constante de
%   réglage. 'Bisquare' annule le poids des résidus au-delà de quatre
%   écarts robustes ; 'LAR' minimise la somme des écarts absolus, ce qui
%   revient à pondérer par l'inverse de l'écart.
%
%   Exemple :
%      matlibre_reglage_robuste('bisquare')
%
%   Voir aussi MATLIBRE_POIDS_ROBUSTES, FITOPTIONS.
    switch lower(char(nom))
        case {'bisquare', 'on'}
            reglage = struct('genre', 'bisquare', 'constante', 4.685);
        case 'lar'
            reglage = struct('genre', 'lar', 'constante', 1);
        otherwise
            error('curvefit:robuste:Nom', 'Méthode robuste inconnue : %s.', char(nom));
    end
end
