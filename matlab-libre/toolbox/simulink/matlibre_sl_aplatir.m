function modele = matlibre_sl_aplatir(modele)
%MATLIBRE_SL_APLATIR Déplie les sous-systèmes d'un modèle.
%   MODELE = MATLIBRE_SL_APLATIR(MODELE) rend le même modèle, où chaque
%   bloc de type « subsystem » a été remplacé par les blocs qu'il
%   contient. Un modèle sans sous-système est rendu tel quel.
%
%   C'est ainsi qu'un sous-système se simule : non pas comme un bloc à
%   part, mais comme le schéma qu'il abrège. SIM, LINMOD, TRIM et
%   MATLIBRE_SL_PROGRAMME appellent tous cette fonction d'abord, si bien
%   qu'aucun d'eux n'a besoin de savoir qu'un sous-système existe.
%
%   Le dépliage garde trois choses. Les blocs intérieurs prennent le nom
%   « sousSysteme/bloc », comme dans Simulink, et se retrouvent donc
%   nommés dans le relevé. Le bloc du sous-système lui-même ne
%   disparaît pas : il reste, en passe-plat à autant de ports qu'il a de
%   sorties, chaque OUTPORT intérieur alimentant la sortie de même rang
%   — un relevé pris sur le sous-système reste donc celui de sa première
%   sortie, et un lien qui partait de sa deuxième sortie part toujours de
%   la sortie de l'OUTPORT de rang 2. Et les entrées se raccordent par
%   leur rang : le lien qui arrivait sur la deuxième entrée du bloc
%   arrive sur le bloc INPORT intérieur dont le paramètre Port vaut 2.
%
%   Les types sont ramenés à leur nom MatLibre par le catalogue : un
%   bloc intérieur posé sous son nom Simulink (« In1 », « SubSystem »)
%   se déplie comme les autres. Les liens rendus ont quatre colonnes —
%   source, destination, entrée, sortie.
%
%   Les sous-systèmes s'emboîtent : un sous-système qui en contient un
%   autre est déplié jusqu'au bout.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      interne = new_system('doubleur');
%      interne = add_block(interne, 'inport', 'e', 'Port', 1);
%      interne = add_block(interne, 'gain', 'deux', 'Gain', 2);
%      interne = add_block(interne, 'outport', 's', 'Port', 1);
%      interne = add_line(add_line(interne, 'e', 'deux'), 'deux', 's');
%      m = add_block(new_system('dehors'), 'constant', 'un', 'Value', 3);
%      m = add_block(m, 'subsystem', 'boite', 'Model', interne);
%      m = add_line(m, 'un', 'boite');
%      numel(matlibre_sl_aplatir(m).blocs)      % 5 : un, boite, e, deux, s
%
%   Voir aussi SIM, ADD_BLOCK, MATLIBRE_SL_ORDRE.
    modele = matlibre_sl_modele(modele);
    modele.liens = matlibre_sl_liens(modele);
    for j = 1:numel(modele.blocs)
        modele.blocs{j}.type = typeCanonique(modele.blocs{j}.type);
    end
    % Un modèle ordinaire ne paie rien : le dépliage ne coûte que le
    % parcours qui constate qu'il n'y a rien à déplier.
    garde = 0;
    while true
        k = premier(modele);
        if k == 0
            return
        end
        garde = garde + 1;
        if garde > 1000
            error('Simulink:Commands:SousSystemeRecursif', ...
                  ['Le depliage des sous-systemes ne s''arrete pas : un ' ...
                   'sous-systeme se contient lui-meme, directement ou non.']);
        end
        modele = deplier(modele, k);
    end
end

% Le nom MatLibre d'un type, quelle que soit la façon dont on l'a écrit.
% Un type inconnu reste tel quel : c'est la compilation qui le refusera,
% en nommant le bloc par son chemin.
function t = typeCanonique(type)
    try
        entree = matlibre_sl_catalogue('type', type);
        t = entree.type;
    catch
        t = char(type);
    end
end

function k = premier(modele)
    k = 0;
    for j = 1:numel(modele.blocs)
        if strcmp(modele.blocs{j}.type, 'subsystem')
            k = j;
            return
        end
    end
end

function modele = deplier(modele, k)
    bloc = modele.blocs{k};
    interne = contenu(bloc);
    interne.liens = matlibre_sl_liens(interne);
    for j = 1:numel(interne.blocs)
        interne.blocs{j}.type = typeCanonique(interne.blocs{j}.type);
    end
    n = numel(modele.blocs);
    m = numel(interne.blocs);
    entrees = parRang(interne, 'inport');
    sorties = parRang(interne, 'outport');

    % Le bloc du sous-système garde sa place dans la liste — donc son
    % rang, donc tous les liens qui le désignent —, mais devient un
    % passe-plat : chacune de ses sorties portera la valeur de l'OUTPORT
    % intérieur de même rang.
    passePlat = bloc;
    passePlat.type = 'signalconversion';
    passePlat.parametres = struct();
    if numel(sorties) > 1
        passePlat.parametres.NombreDePorts = numel(sorties);
    end
    if isfield(bloc.parametres, 'Position')
        passePlat.parametres.Position = bloc.parametres.Position;
    end
    modele.blocs{k} = passePlat;

    % Les blocs intérieurs viennent à la suite, sous le nom
    % « sousSysteme/bloc ». Ils perdent leur place : elle était donnée
    % dans le repère du sous-système, et n'a pas de sens dans celui du
    % schéma qui l'abrège.
    for j = 1:m
        enfant = interne.blocs{j};
        enfant.nom = [char(bloc.nom) '/' char(enfant.nom)];
        if isfield(enfant.parametres, 'Position')
            enfant.parametres = rmfield(enfant.parametres, 'Position');
        end
        modele.blocs{n + j} = enfant;
    end
    if ~isempty(interne.liens)
        modele.liens = [modele.liens; ...
                        [interne.liens(:, 1) + n, interne.liens(:, 2) + n, ...
                         interne.liens(:, 3:4)]];
    end

    % Les bornes d'un sous-système sont les siennes, non celles du modèle
    % qui l'abrège : dépliées telles quelles, LINMOD et TRIM les auraient
    % prises pour des entrées et des sorties du schéma entier, et rendu
    % des matrices d'un ordre trop grand. On les rend donc passe-plat —
    % l'entrée que rien n'alimente devient la constante qu'elle valait,
    % ce que SIM lui faisait déjà rendre.
    for j = 1:numel(sorties)
        modele.blocs{n + sorties(j)}.type = 'signalconversion';
        modele.blocs{n + sorties(j)}.parametres = struct();
    end
    for j = 1:numel(entrees)
        indice = n + entrees(j);
        valeur = 0;
        if isfield(modele.blocs{indice}.parametres, 'Value')
            valeur = modele.blocs{indice}.parametres.Value;
        end
        modele.blocs{indice}.type = 'constant';
        modele.blocs{indice}.parametres = struct('Value', {valeur});
    end

    % Chaque lien qui arrivait sur le bloc arrive à présent sur l'INPORT
    % de même rang, lequel cesse d'être une source pour devenir le
    % passe-plat de ce qu'on lui donne.
    for l = 1:size(modele.liens, 1)
        if modele.liens(l, 2) ~= k
            continue
        end
        port = modele.liens(l, 3);
        if port < 1 || port > numel(entrees)
            error('Simulink:Commands:SousSystemeEntreeAbsente', ...
                  ['Le sous-systeme ''%s'' recoit un lien sur son entree %d, ' ...
                   'mais il n''a que %d bloc(s) INPORT.'], ...
                  char(bloc.nom), port, numel(entrees));
        end
        interieur = n + entrees(port);
        modele.blocs{interieur}.type = 'signalconversion';
        modele.blocs{interieur}.parametres = struct();
        modele.liens(l, 2) = interieur;
        modele.liens(l, 3) = 1;
    end

    % Un lien qui part d'une sortie que le sous-système n'a pas est refusé
    % en le nommant : il ne mènerait nulle part.
    for l = 1:size(modele.liens, 1)
        if modele.liens(l, 1) == k && modele.liens(l, 4) > max(1, numel(sorties))
            error('Simulink:Commands:SousSystemeSortieAbsente', ...
                  ['Un lien part de la sortie %d du sous-systeme ''%s'', qui n''a ' ...
                   'que %d bloc(s) OUTPORT.'], modele.liens(l, 4), char(bloc.nom), ...
                  numel(sorties));
        end
    end

    % Et chaque sortie du sous-système est celle de l'OUTPORT de même rang.
    for j = 1:numel(sorties)
        modele.liens = [modele.liens; n + sorties(j), k, j, 1];
    end
end

function interne = contenu(bloc)
    if isfield(bloc.parametres, 'Model')
        interne = matlibre_sl_modele(bloc.parametres.Model);
    elseif isfield(bloc.parametres, 'Modele')
        interne = matlibre_sl_modele(bloc.parametres.Modele);
    else
        error('Simulink:Commands:SousSystemeVide', ...
              ['Le sous-systeme ''%s'' ne porte pas de modele : donnez-le ' ...
               'par ADD_BLOCK(...,''subsystem'',NOM,''Model'',SOUSMODELE).'], ...
              char(bloc.nom));
    end
end

% Les blocs d'un type donné, rangés par leur paramètre Port. Ceux qui
% n'en portent pas viennent après, dans l'ordre où ils ont été posés :
% c'est le rang qui compte, et l'ordre d'écriture en est un.
function indices = parRang(modele, type)
    indices = [];
    rangs = [];
    suivant = 0;
    for j = 1:numel(modele.blocs)
        if ~strcmp(modele.blocs{j}.type, type)
            continue
        end
        suivant = suivant + 1;
        rang = suivant;
        if isfield(modele.blocs{j}.parametres, 'Port')
            rang = double(modele.blocs{j}.parametres.Port);
        end
        indices(end + 1) = j;      %#ok<AGROW>
        rangs(end + 1) = rang;     %#ok<AGROW>
    end
    [~, ordre] = sort(rangs);
    indices = indices(ordre);
end
