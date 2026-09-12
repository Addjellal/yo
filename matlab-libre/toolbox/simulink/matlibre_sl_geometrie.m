function geometrie = matlibre_sl_geometrie(modele)
%MATLIBRE_SL_GEOMETRIE Où se place chaque bloc, et par où passe chaque lien.
%   G = MATLIBRE_SL_GEOMETRIE(MODELE) rend une structure décrivant le
%   schéma : pour chaque bloc son nom, son type, son étiquette, ses signes
%   et son cadre ; pour chaque lien ses deux bouts, son port d'arrivée et
%   s'il referme une boucle.
%
%   C'est la géométrie que partagent les deux façons de montrer un
%   schéma : OPEN_SYSTEM la trace dans une figure, l'éditeur du bureau la
%   peint sur sa toile et s'en sert pour savoir où l'on a cliqué. Une
%   seule mise en place, donc, et deux dessins qui s'accordent.
%
%   Un bloc qui porte un paramètre POSITION garde la place qu'on lui a
%   donnée — c'est ainsi qu'un schéma déplacé à la souris se retient.
%   POSITION vaut [gauche haut droite bas], comme dans Simulink. Les
%   autres sont placés par couches, de la source vers la sortie.
%
%   Les champs rendus :
%     G.blocs(k).nom, .type, .etiquette, .signes
%     G.blocs(k).noms, .valeurs                  ses réglages, en texte
%     G.blocs(k).gauche, .haut, .droite, .bas    le cadre du bloc
%     G.blocs(k).pose                            vrai si POSITION le fixait
%     G.liens(k).source, .cible, .port, .retour
%     G.largeur, G.hauteur                       la taille d'un bloc par défaut
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('c');
%      m = add_block(m, 'constant', 'u', 'Value', 1);
%      m = add_block(m, 'gain', 'k', 'Gain', 2);
%      m = add_line(m, 'u', 'k');
%      g = matlibre_sl_geometrie(m);
%      g.blocs(2).gauche > g.blocs(1).gauche      % le gain est a droite
%
%   Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION, MATLIBRE_SL_RANGS.
    if ~isstruct(modele) || ~isfield(modele, 'blocs')
        error('Simulink:geometrie:Modele', ...
              'MATLIBRE_SL_GEOMETRIE attend un modele bati par NEW_SYSTEM.');
    end
    n = numel(modele.blocs);
    [rangs, retours] = matlibre_sl_rangs(modele);
    [x, y, largeur, hauteur] = matlibre_sl_disposition(modele, rangs);

    geometrie = struct();
    geometrie.nom = modele.nom;
    geometrie.largeur = largeur;
    geometrie.hauteur = hauteur;
    blocs = struct('nom', {}, 'type', {}, 'etiquette', {}, 'signes', {}, ...
                   'gauche', {}, 'haut', {}, 'droite', {}, 'bas', {}, ...
                   'pose', {}, 'noms', {}, 'valeurs', {});
    for k = 1:n
        bloc = modele.blocs{k};
        pose = false;
        if isfield(bloc.parametres, 'Position')
            cadre = double(bloc.parametres.Position);
            if numel(cadre) == 4
                pose = true;
            end
        end
        if ~pose
            % [gauche haut droite bas], comme dans Simulink : l'axe des
            % ordonnees y descend, celui du trace monte. On garde ici la
            % convention de Simulink, et le trace la retourne.
            demiL = demiLargeur(bloc.type, largeur, hauteur);
            cadre = [x(k) - demiL, -y(k) - hauteur / 2, ...
                     x(k) + demiL, -y(k) + hauteur / 2];
        end
        % Les réglages, écrits tels qu'un programme les relira : c'est ce
        % que la boîte de dialogue montre, et ce qu'elle renvoie.
        champs = fieldnames(bloc.parametres);
        noms = {};
        valeurs = {};
        for j = 1:numel(champs)
            if strcmp(champs{j}, 'Position')
                continue   % la place se règle à la souris, non au clavier
            end
            noms{end + 1} = champs{j};                          %#ok<AGROW>
            valeurs{end + 1} = ecrireReglage(bloc.parametres.(champs{j}));  %#ok<AGROW>
        end
        blocs(end + 1) = struct('nom', bloc.nom, 'type', bloc.type, ...
                                'etiquette', matlibre_sl_etiquette(bloc), ...
                                'signes', matlibre_sl_signes(bloc), ...
                                'gauche', cadre(1), 'haut', cadre(2), ...
                                'droite', cadre(3), 'bas', cadre(4), ...
                                'pose', pose, 'noms', {noms}, ...
                                'valeurs', {valeurs});   %#ok<AGROW>
    end
    geometrie.blocs = blocs;

    liens = struct('source', {}, 'cible', {}, 'port', {}, 'retour', {});
    for l = 1:size(modele.liens, 1)
        source = modele.liens(l, 1);
        cible = modele.liens(l, 2);
        port = modele.liens(l, 3);
        estRetour = ~isempty(retours) && ...
            any(retours(:, 1) == source & retours(:, 2) == cible & ...
                retours(:, 3) == port);
        liens(end + 1) = struct('source', source, 'cible', cible, ...
                                'port', port, 'retour', estRetour);   %#ok<AGROW>
    end
    geometrie.liens = liens;
end

% Un réglage tel qu'on le relira : le texte tel quel — c'est une
% expression, et l'écrire entre apostrophes la ferait lire deux fois —,
% les nombres par MAT2STR.
function t = ecrireReglage(v)
    if ischar(v) || isstring(v)
        t = char(v);
    elseif isnumeric(v) || islogical(v)
        t = mat2str(v);
    else
        t = ['<' class(v) '>'];
    end
end

function d = demiLargeur(type, largeur, hauteur)
% Une sommation est ronde : son cadre est carré, de la hauteur des autres.
    if strcmp(type, 'sum')
        d = hauteur / 2;
    else
        d = largeur / 2;
    end
end
