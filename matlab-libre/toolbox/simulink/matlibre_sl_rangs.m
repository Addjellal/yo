function [rangs, retours] = matlibre_sl_rangs(modele)
%MATLIBRE_SL_RANGS Range les blocs en couches, de la source vers la sortie.
%   [RANGS,RETOURS] = MATLIBRE_SL_RANGS(MODELE) rend le numéro de couche
%   de chaque bloc et la liste des liens de rebouclage.
%
%   Un schéma bouclé n'a pas d'ordre : le rangement se fait sur la partie
%   sans circuit, et les liens qui referment une boucle sont mis à part
%   pour être tracés en retour. C'est ce qui donne au schéma sa lecture
%   de gauche à droite, la contre-réaction passant par-dessous.
%
%   Le rang d'un bloc est la longueur du plus long chemin qui y mène :
%   prendre le plus court tasserait les blocs contre leur source et
%   ferait se croiser les liaisons.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('c');
%      m = add_block(m, 'constant', 'u', 'Value', 1);
%      m = add_block(m, 'gain', 'k', 'Gain', 2);
%      m = add_line(m, 'u', 'k');
%      matlibre_sl_rangs(m)            % [0 1]
%
%   Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION.
    n = numel(modele.blocs);
    rangs = zeros(1, n);
    retours = [];
    if n == 0 || isempty(modele.liens)
        return
    end
    liens = modele.liens;

    % Les liens de rebouclage se repèrent par un parcours en profondeur :
    % un arc qui retombe sur un bloc encore ouvert referme un circuit.
    couleur = zeros(1, n);          % 0 neuf, 1 ouvert, 2 fini
    estRetour = false(size(liens, 1), 1);
    for depart = 1:n
        if couleur(depart) == 0
            [couleur, estRetour] = descendre(depart, liens, couleur, estRetour);
        end
    end
    retours = liens(estRetour, :);
    avant = liens(~estRetour, :);

    % Le rang est la longueur du plus long chemin. Sur la partie sans
    % circuit, n relaxations suffisent.
    for tour = 1:n
        change = false;
        for k = 1:size(avant, 1)
            source = avant(k, 1);
            cible = avant(k, 2);
            if rangs(cible) < rangs(source) + 1
                rangs(cible) = rangs(source) + 1;
                change = true;
            end
        end
        if ~change
            break
        end
    end
end

function [couleur, estRetour] = descendre(depart, liens, couleur, estRetour)
    couleur(depart) = 1;
    for k = 1:size(liens, 1)
        if liens(k, 1) ~= depart
            continue
        end
        suivant = liens(k, 2);
        if couleur(suivant) == 1
            estRetour(k) = true;
        elseif couleur(suivant) == 0
            [couleur, estRetour] = descendre(suivant, liens, couleur, estRetour);
        end
    end
    couleur(depart) = 2;
end
