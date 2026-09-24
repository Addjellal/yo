function h = open_system(modele)
%OPEN_SYSTEM Ouvre un modèle et en dessine le schéma-bloc.
%   OPEN_SYSTEM(MODELE) trace le schéma : un bloc par élément, sa forme
%   disant ce qu'il fait, et les liaisons fléchées entre eux.
%   H = OPEN_SYSTEM(MODELE) rend en plus la poignée de la figure.
%
%   Les blocs sont rangés en couches, de la source vers la sortie, et
%   ordonnés dans chaque couche pour croiser le moins de liaisons
%   possible. Une contre-réaction passe sous le schéma : tracée en ligne
%   droite, elle traverserait les blocs qu'elle enjambe.
%
%   Le schéma est reconstruit à partir du modèle à chaque appel : il n'y
%   a pas de position enregistrée, et donc rien à déplacer à la souris.
%   MATLAB ouvre un éditeur, MatLibre rend une figure — on voit le
%   schéma, on ne le modifie pas là.
%
%   Le modèle est inscrit au registre de la session : GCS le nomme,
%   BDISLOADED répond vrai, et CLOSE_SYSTEM le ferme avec sa figure.
%   OPEN_SYSTEM(NOM) rouvre un modèle déjà inscrit, ou exécute le
%   fichier NOM.m qui le rend.
%
%   Exemple :
%      m = new_system('boucle');
%      m = add_block(m, 'constant', 'consigne', 'Value', 1);
%      m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
%      m = add_block(m, 'gain', 'correcteur', 'Gain', 2);
%      m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
%      m = add_line(m, 'consigne', 'erreur', 1);
%      m = add_line(m, 'sortie', 'erreur', 2);
%      m = add_line(m, 'erreur', 'correcteur');
%      m = add_line(m, 'correcteur', 'sortie');
%      open_system(m);
%      close_system(m);
%
%   Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, CLOSE_SYSTEM, GCS, SIM.
    if nargin < 1
        error('MATLAB:minrhs', 'OPEN_SYSTEM attend un modèle.');
    end
    if ischar(modele) || isstring(modele)
        modele = matlibre_sl_modele(modele);
    end
    if ~isstruct(modele) || ~isfield(modele, 'blocs')
        error('Simulink:openSystem:Modele', ...
              ['OPEN_SYSTEM attend le modèle que rend NEW_SYSTEM ; les ' ...
               'fichiers .slx de MathWorks, dont le format n''est pas ' ...
               'public, ne se lisent pas.']);
    end

    % Une seule mise en place, partagée avec l'éditeur du bureau : c'est
    % ainsi qu'un bloc déplacé à la souris se retrouve au même endroit
    % dans la figure.
    geometrie = matlibre_sl_geometrie(modele);
    n = numel(geometrie.blocs);
    hauteur = geometrie.hauteur;

    % Les bornes du schéma se connaissent avant de tracer, et c'est ce
    % qui permet de tailler la toile à sa mesure. Sur une toile fixe,
    % « axis equal » laissait un bandeau vide au-dessus et au-dessous
    % d'un schéma en long, et serrait les étiquettes dès que les couches
    % se multipliaient : la même largeur pour deux blocs et pour douze.
    marge = 0.9;
    nbRetours = 0;
    for k = 1:numel(geometrie.liens)
        if geometrie.liens(k).retour
            nbRetours = nbRetours + 1;
        end
    end
    if n > 0
        gauches = [geometrie.blocs.gauche];
        droites = [geometrie.blocs.droite];
        hauts = [geometrie.blocs.haut];
        bas = [geometrie.blocs.bas];
        % Le tracé a l'ordonnée vers le haut, la géométrie vers le bas.
        centresY = -(hauts + bas) / 2;
        basSchema = min([centresY, 0]) - hauteur * 1.4 - ...
                    max(0, nbRetours - 1) * hauteur * 0.7;
        bornesX = [min(gauches) - marge, max(droites) + marge];
        bornesY = [basSchema - marge, max(centresY) + hauteur / 2 + marge];
    else
        bornesX = [-1, 1];
        bornesY = [-1, 1];
    end
    [toileL, toileH] = matlibre_sl_toile(diff(bornesX), diff(bornesY));
    figure('Position', [100, 100, toileL, toileH]);
    hold on;
    for k = 1:n
        b = geometrie.blocs(k);
        matlibre_sl_forme(modele.blocs{k}, (b.gauche + b.droite) / 2, ...
                          -(b.haut + b.bas) / 2, b.droite - b.gauche, ...
                          b.bas - b.haut);
    end

    if n > 0 && ~isempty(geometrie.liens)
        % Chaque retour a sa propre profondeur : à la même hauteur, deux
        % contre-réactions se confondraient en un seul trait, et l'on ne
        % saurait plus laquelle va où.
        basRetours = min([-(hauts + bas) / 2, 0]) - hauteur * 1.4;
        profondeur = hauteur * 0.7;
        rangRetour = 0;
        for k = 1:numel(geometrie.liens)
            lien = geometrie.liens(k);
            source = geometrie.blocs(lien.source);
            cible = geometrie.blocs(lien.cible);
            depart = [source.droite, -(source.haut + source.bas) / 2 + ...
                      decalageSortie(source, lien.sortie)];
            arrivee = [cible.gauche, ...
                       -(cible.haut + cible.bas) / 2 + ...
                       decalagePort(cible, lien.port)];
            niveau = basRetours;
            if lien.retour
                niveau = basRetours - rangRetour * profondeur;
                rangRetour = rangRetour + 1;
            end
            matlibre_sl_fil(depart, arrivee, lien.retour, niveau);
        end
    end

    hold off;
    axis equal;
    axis off;
    if n > 0
        % Le cadrage suit le schéma : « axis equal » garde les proportions,
        % et des bornes serrées évitent de noyer un petit schéma dans du
        % vide. La marge du bas laisse la place aux noms et aux retours.
        xlim(bornesX);
        ylim(bornesY);
    end
    title(modele.nom);
    poignee = gcf;
    matlibre_sl_ouverts('inscrire', modele.nom, modele, poignee);
    if nargout > 0
        h = poignee;
    end
end

function d = decalagePort(bloc, port)
% Les entrées d'une sommation se répartissent sur son bord gauche, dans
% l'ordre des signes : sans cela, deux liaisons arriveraient au même
% point et l'on ne saurait plus laquelle est retranchée.
    d = 0;
    if ~strcmp(bloc.type, 'sum')
        return
    end
    signes = bloc.signes;
    if numel(signes) < 2 || port < 1 || port > numel(signes)
        return
    end
    hauteur = bloc.bas - bloc.haut;
    d = hauteur * (0.28 - 0.56 * (port - 1) / (numel(signes) - 1));
end

% Les sorties se répartissent sur le bord droit comme les entrées sur le
% bord gauche : les fils d'un Demux partent chacun de leur port.
function d = decalageSortie(bloc, sortie)
    d = 0;
    if bloc.sorties <= 1
        return
    end
    part = (min(max(sortie, 1), bloc.sorties) - 1) / (bloc.sorties - 1);
    d = (bloc.bas - bloc.haut) * (0.28 - 0.56 * part);
end
