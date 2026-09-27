function [modele, reference, description] = matlibre_essai_echelle(graine)
%MATLIBRE_ESSAI_ECHELLE Un réseau physique en échelle, tiré au hasard.
%   [M,H,D] = MATLIBRE_ESSAI_ECHELLE(GRAINE) rend un modèle M dont un
%   réseau de Simscape en échelle — électrique, mécanique, thermique, ou
%   électromécanique (une échelle électrique qui entraîne, par un
%   convertisseur, une échelle en rotation) —, de deux à quatre étages,
%   chacun un élément en série et un élément vers la référence, relie
%   l'entrée du modèle à sa sortie ; H, une fonction qui calcule sa
%   transmittance H(s) par les impédances complexes, sans passer par la
%   mise en équations du réseau ; D, sa description.
%
%   Les éléments sont idéaux : des inductances sans conductance parallèle,
%   des condensateurs sans résistance série. Deux inductances en série,
%   deux masses sur un même nœud, un ressort entre deux ressorts rendent
%   singulières les équations algébriques du réseau, et c'est la réduction
%   aux états libres qui les résout.
%
%   Fonction d'essai de la batterie de SIMULINK.
    rng(graine);
    domaine = randi(4);
    modele = new_system(sprintf('echelle%d', graine));
    modele = add_block(modele, 'inport', 'u');
    modele = add_block(modele, 'simulinkpsconverter', 'SP');
    modele = add_block(modele, 'pssimulinkconverter', 'PS');
    modele = add_block(modele, 'outport', 'y');
    modele = add_block(modele, 'solverconfiguration', 'S');
    modele = add_line(add_line(modele, 'u', 'SP'), 'PS', 'y');
    switch domaine
        case 1
            [genres, valeurs] = tirer(1, randi([2 4]));
            modele = add_block(modele, 'electricalreference', 'G');
            modele = add_block(modele, 'controlledvoltagesource', 'source');
            modele = add_block(modele, 'voltagesensor', 'capteur');
            modele = add_line(modele, 'source/RConn1', 'G/LConn1');
            [modele, noeud] = echelle(modele, 1, genres, valeurs, 'source/LConn1', 'G', '');
            reference = @(s) tension(s, genres, valeurs, 0);
            description = ['electrique ' texte(genres)];
        case 2
            [genres, valeurs] = tirer(2, randi([2 4]));
            modele = add_block(modele, 'mechanicaltranslationalreference', 'G');
            modele = add_block(modele, 'idealforcesource', 'source');
            modele = add_block(modele, 'idealtranslationalmotionsensor', 'capteur');
            modele = add_line(modele, 'source/RConn1', 'G/LConn1');
            [modele, noeud] = echelle(modele, 2, genres, valeurs, 'source/LConn1', 'G', '');
            reference = @(s) flux(s, genres, valeurs);
            description = ['translation ' texte(genres)];
        case 3
            [genres, valeurs] = tirer(3, randi([2 4]));
            modele = add_block(modele, 'thermalreference', 'G');
            modele = add_block(modele, 'idealheatflowsource', 'source');
            modele = add_block(modele, 'idealtemperaturesensor', 'capteur');
            modele = add_line(modele, 'source/LConn1', 'G/LConn1');
            [modele, noeud] = echelle(modele, 3, genres, valeurs, 'source/RConn1', 'G', '');
            reference = @(s) flux(s, genres, valeurs);
            description = ['thermique ' texte(genres)];
        otherwise
            % une échelle électrique qui entraîne, par le convertisseur, une
            % échelle en rotation ; la vitesse du dernier arbre est mesurée
            [genres, valeurs] = tirer(1, randi([1 3]));
            [genresM, valeursM] = tirer(4, randi([1 3]));
            K = round(0.2 + rand(), 2);
            modele = add_block(modele, 'electricalreference', 'G');
            modele = add_block(modele, 'mechanicalrotationalreference', 'GM');
            modele = add_block(modele, 'controlledvoltagesource', 'source');
            modele = add_block(modele, 'rotationalelectromechanicalconverter', 'moteur', 'K', K);
            modele = add_block(modele, 'idealrotationalmotionsensor', 'capteur');
            modele = add_line(modele, 'source/RConn1', 'G/LConn1');
            [modele, noeudE] = echelle(modele, 1, genres, valeurs, 'source/LConn1', 'G', '');
            modele = add_line(modele, 'moteur/LConn1', noeudE);
            modele = add_line(modele, 'moteur/LConn2', 'G/LConn1');
            modele = add_line(modele, 'moteur/RConn2', 'GM/LConn1');
            [modele, noeud] = echelle(modele, 4, genresM, valeursM, 'moteur/RConn1', 'GM', 'm');
            reference = @(s) electromecanique(s, genres, valeurs, genresM, valeursM, K);
            description = sprintf('electromecanique %s K=%g %s', texte(genres), K, ...
                                  texte(genresM));
    end
    modele = add_line(modele, 'SP', 'source');
    references = {'G', 'G', 'G', 'GM'};
    modele = add_line(modele, 'S/RConn1', 'G/LConn1');
    % le capteur mesure le dernier nœud par rapport à la référence
    modele = add_line(modele, 'capteur/LConn1', noeud);
    modele = add_line(modele, 'capteur/RConn1', [references{domaine} '/LConn1']);
    if domaine == 2 || domaine == 4
        modele = add_line(modele, 'capteur/1', 'PS');
    else
        modele = add_line(modele, 'capteur', 'PS');
    end
end

% Les étages : un élément en série (R, L, C) et un vers la référence. Le
% premier d'une échelle qu'un flux attaque n'a pas d'élément en série, et
% son élément vers la référence n'est pas un ressort.
function [genres, valeurs] = tirer(domaine, n)
    switch domaine
        case 1
            serie = {'R', 'L', 'C'};
            derivation = {'R', 'L', 'C'};
        case {2, 4}
            serie = {'R', 'L', 'C'};           % amortisseur, ressort, inerteur
            derivation = {'R', 'L', 'C'};      % amortisseur, ressort, masse ou inertie
        otherwise
            serie = {'R'};                     % conduction
            derivation = {'R', 'C'};           % conduction vers la référence, masse
    end
    genres = cell(n, 2);
    valeurs = zeros(n, 2);
    for i = 1:n
        genres{i, 1} = serie{randi(numel(serie))};
        genres{i, 2} = derivation{randi(numel(derivation))};
        valeurs(i, :) = round(10 .^ (rand(1, 2) - 0.5), 2);   % de 0.32 à 3.2
    end
    if domaine == 1
        genres{1, 1} = 'R';   % la source de tension ne touche pas un condensateur
    else
        genres{1, 1} = '';    % le flux entre dans le premier nœud
        if strcmp(genres{1, 2}, 'L')
            genres{1, 2} = 'C';
        end
    end
end

function t = texte(genres)
    etages = cellfun(@(a, b) sprintf('[%s|%s]', a, b), genres(:, 1), genres(:, 2), ...
                     'UniformOutput', false);
    t = strjoin(etages', ' ');
end

function [modele, noeud] = echelle(modele, domaine, genres, valeurs, precedent, masse, prefixe)
    for i = 1:size(genres, 1)
        if ~isempty(genres{i, 1})
            nom = sprintf('%ss%d', prefixe, i);
            modele = poser(modele, domaine, genres{i, 1}, valeurs(i, 1), nom, true);
            modele = add_line(modele, precedent, [nom '/LConn1']);
            precedent = [nom '/RConn1'];
        end
        nom = sprintf('%sd%d', prefixe, i);
        modele = poser(modele, domaine, genres{i, 2}, valeurs(i, 2), nom, false);
        modele = add_line(modele, precedent, [nom '/LConn1']);
        if ~(strcmp(genres{i, 2}, 'C') && domaine ~= 1)
            % une masse, une inertie, une masse thermique n'ont qu'un port
            modele = add_line(modele, [nom '/RConn1'], [masse '/LConn1']);
        end
        noeud = [nom '/LConn1'];
        precedent = noeud;
    end
end

function modele = poser(modele, domaine, genre, valeur, nom, enSerie)
    switch domaine
        case 1
            switch genre
                case 'R'
                    modele = add_block(modele, 'resistor', nom, 'R', valeur);
                case 'L'
                    modele = add_block(modele, 'inductor', nom, 'l', valeur, 'r', 0, 'g', 0);
                otherwise
                    modele = add_block(modele, 'capacitor', nom, 'c', valeur, 'r', 0, 'g', 0);
            end
        case {2, 4}
            rotation = domaine == 4;
            types = {'translationaldamper', 'translationalspring', 'translationalinerter', ...
                     'mass', 'mass'};
            if rotation
                types = {'rotationaldamper', 'rotationalspring', 'rotationalinerter', ...
                         'inertia', 'inertia'};
            end
            switch genre
                case 'R'
                    modele = add_block(modele, types{1}, nom, 'D', 1 / valeur);
                case 'L'
                    modele = add_block(modele, types{2}, nom, 'spr_rate', 1 / valeur);
                otherwise
                    if enSerie
                        modele = add_block(modele, types{3}, nom, 'B', valeur);
                    else
                        modele = add_block(modele, types{4}, nom, types{5}, valeur);
                    end
            end
        otherwise
            if strcmp(genre, 'R')
                modele = add_block(modele, 'conductiveheattransfer', nom, 'area', 1, ...
                                   'thickness', 1, 'th_cond', 1 / valeur);
            else
                modele = add_block(modele, 'thermalmass', nom, 'mass', valeur, 'sp_heat', 1, ...
                                   'T', 0);
            end
    end
end

% --- les transmittances, par les impédances -----------------------------------
%
% R une résistance (1/D, 1/G), L une inductance (1/k), C une capacité (m, J,
% B, m c). Un étage est une impédance série puis une admittance vers la
% référence ; YPLUS, une admittance de plus au dernier nœud.

function charge = charges(s, genres, valeurs, yPlus)
    n = size(genres, 1);
    z = @(genre, v) impedance(genre, v, s);
    charge = cell(1, n);
    charge{n} = 1 ./ (1 ./ z(genres{n, 2}, valeurs(n, 2)) + yPlus);
    for i = n - 1:-1:1
        suite = z(genres{i + 1, 1}, valeurs(i + 1, 1)) + charge{i + 1};
        charge{i} = 1 ./ (1 ./ z(genres{i, 2}, valeurs(i, 2)) + 1 ./ suite);
    end
end

function h = propager(s, genres, valeurs, charge, h)
    for i = 2:size(genres, 1)
        h = h .* charge{i} ./ (impedance(genres{i, 1}, valeurs(i, 1), s) + charge{i});
    end
end

% une tension imposée à l'entrée de la première impédance série
function h = tension(s, genres, valeurs, yPlus)
    charge = charges(s, genres, valeurs, yPlus);
    h = charge{1} ./ (impedance(genres{1, 1}, valeurs(1, 1), s) + charge{1});
    h = propager(s, genres, valeurs, charge, h);
end

% un flux injecté dans le premier nœud
function h = flux(s, genres, valeurs)
    charge = charges(s, genres, valeurs, 0);
    h = propager(s, genres, valeurs, charge, charge{1});
end

% le convertisseur : la charge mécanique Zm, vue du côté électrique, est
% une impédance K^2 Zm ; la vitesse de son arbre vaut v / K
function h = electromecanique(s, genres, valeurs, genresM, valeursM, K)
    chargeM = charges(s, genresM, valeursM, 0);
    h = tension(s, genres, valeurs, 1 ./ (K ^ 2 * chargeM{1})) / K;
    h = propager(s, genresM, valeursM, chargeM, h);
end

function v = impedance(genre, valeur, s)
    switch genre
        case 'R'
            v = valeur + 0 * s;
        case 'L'
            v = s * valeur;
        otherwise
            v = 1 ./ (s * valeur);
    end
end
