function matlibre_sl_forme(bloc, x, y, largeur, hauteur)
%MATLIBRE_SL_FORME Dessine un bloc, selon ce qu'il fait.
%   MATLIBRE_SL_FORME(BLOC,X,Y,L,H) trace le bloc centré en (X,Y).
%
%   La forme dit la fonction avant que le texte ne la nomme : un gain est
%   un triangle, une sommation un cercle, une source porte l'allure de
%   son signal. C'est la convention des schémas-blocs, et elle se lit
%   plus vite qu'une liste de rectangles étiquetés.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure;
%      matlibre_sl_forme(struct('type', 'gain', 'nom', 'k', ...
%                               'parametres', struct('Gain', 3)), 0, 0, 1.7, 1);
%
%   Voir aussi OPEN_SYSTEM, MATLIBRE_SL_FIL.
    remplissage = [1 1 1];
    contour = [0.15 0.15 0.15];
    switch bloc.type
        case 'gain'
            % Un triangle pointant vers la droite, comme dans un schéma.
            patch([x - largeur/2, x - largeur/2, x + largeur/2], ...
                  [y - hauteur/2, y + hauteur/2, y], remplissage, ...
                  'EdgeColor', contour);
            texte(x - largeur/8, y, matlibre_sl_etiquette(bloc));
        case 'sum'
            % Un cercle, et les signes autour de lui.
            rectangle('Position', [x - hauteur/2, y - hauteur/2, hauteur, hauteur], ...
                      'Curvature', 1, 'FaceColor', remplissage, 'EdgeColor', contour);
            % Les signes vont dedans, près du bord d'où arrive chaque
            % entrée : posés dehors, la pointe de flèche les recouvrait.
            signes = matlibre_sl_signes(bloc);
            for k = 1:numel(signes)
                place = y + hauteur * (0.24 - 0.48 * (k - 1) / max(1, numel(signes) - 1));
                if numel(signes) == 1
                    place = y;
                end
                text(x - hauteur * 0.24, place, signes(k), ...
                     'HorizontalAlignment', 'center', 'FontSize', 10);
            end
        case {'inport', 'outport'}
            % Les bornes du modèle : un pentagone pointé vers le sens du
            % signal, comme dans Simulink. On voit d'un coup d'œil par où
            % le modèle est alimenté et par où il rend.
            demiL = largeur / 2;
            demiH = hauteur / 2;
            pointe = demiL * 0.45;
            if strcmp(bloc.type, 'inport')
                abscisses = [x - demiL, x + demiL - pointe, x + demiL, ...
                             x + demiL - pointe, x - demiL];
                ordonnees = [y - demiH, y - demiH, y, y + demiH, y + demiH];
            else
                abscisses = [x - demiL + pointe, x + demiL, x + demiL, ...
                             x - demiL + pointe, x - demiL];
                ordonnees = [y - demiH, y - demiH, y + demiH, y + demiH, y];
            end
            patch(abscisses, ordonnees, remplissage, 'EdgeColor', contour);
            texte(x, y, matlibre_sl_etiquette(bloc));
        case 'subsystem'
            % Un rectangle a double trait. Simulink distingue ainsi ce
            % qui s'ouvre de ce qui se calcule sur place : le second
            % trait dit qu'il y a un schema dessous.
            rectangle('Position', [x - largeur/2, y - hauteur/2, largeur, hauteur], ...
                      'FaceColor', remplissage, 'EdgeColor', contour);
            marge = min(largeur, hauteur) * 0.10;
            rectangle('Position', [x - largeur/2 + marge, y - hauteur/2 + marge, ...
                                   largeur - 2*marge, hauteur - 2*marge], ...
                      'EdgeColor', contour);
            texte(x, y, matlibre_sl_etiquette(bloc));
        otherwise
            rectangle('Position', [x - largeur/2, y - hauteur/2, largeur, hauteur], ...
                      'FaceColor', remplissage, 'EdgeColor', contour);
            allure = matlibre_sl_allure(bloc, x, y, largeur, hauteur);
            if ~allure
                texte(x, y, matlibre_sl_etiquette(bloc));
            end
    end
    % Le nom du bloc va dessous, hors du cadre : c'est là que Simulink le
    % met, et cela laisse l'intérieur à ce que le bloc calcule.
    text(x, y - hauteur * 0.85, bloc.nom, 'HorizontalAlignment', 'center', ...
         'FontSize', 9);
end

function texte(x, y, contenu)
    text(x, y, contenu, 'HorizontalAlignment', 'center', 'FontSize', 11);
end
