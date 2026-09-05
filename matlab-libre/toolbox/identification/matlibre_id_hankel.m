function H = matlibre_id_hankel(signal, depart, blocs, colonnes)
%MATLIBRE_ID_HANKEL Matrice de Hankel par blocs d'un signal.
%   H = MATLIBRE_ID_HANKEL(SIGNAL,DEPART,BLOCS,COLONNES) empile BLOCS
%   fenêtres décalées d'un échantillon, chacune de COLONNES points, à
%   partir de DEPART.
%
%   C'est la mise en forme dont vivent les méthodes par sous-espaces : les
%   colonnes y sont autant de trajectoires courtes du même système, et
%   l'espace qu'elles engendrent est celui de l'état.
%
%   Exemple :
%      matlibre_id_hankel((1:5)', 1, 2, 3)      % [1 2 3; 2 3 4]
%
%   Voir aussi N4SID, MATLIBRE_ID_SOUS_ESPACES.
    voies = size(signal, 2);
    H = zeros(blocs * voies, colonnes);
    for b = 1:blocs
        lignes = ((b - 1) * voies + 1):(b * voies);
        debut = depart + b - 1;
        H(lignes, :) = signal(debut:(debut + colonnes - 1), :).';
    end
end
