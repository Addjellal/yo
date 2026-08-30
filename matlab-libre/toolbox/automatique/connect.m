function sys = connect(varargin)
%CONNECT Assemble un schéma-bloc en reliant les signaux par leur nom.
%   SYS = CONNECT(BLOC1,BLOC2,...,ENTREES,SORTIES) relie les blocs : une
%   entrée nommée « u » est branchée sur la sortie nommée « u », d'où
%   qu'elle vienne. ENTREES et SORTIES nomment ce qui reste ouvert — les
%   entrées et les sorties du modèle assemblé.
%
%   Chaque bloc doit nommer ses voies, par ses propriétés InputName et
%   OutputName ; SUMBLK fabrique les points de sommation. Un nom qui n'est
%   ni une sortie de bloc ni une entrée du schéma est signalé : c'est
%   presque toujours une faute de frappe.
%
%   CONNECT est la façon moderne d'écrire ce que SYSIC écrivait avec des
%   variables. Les deux mènent au même modèle.
%
%   Exemples :
%      G = ss(tf(2, [1 1]));  G.InputName = 'u';  G.OutputName = 'y';
%      K = ss(tf(10, [1 0])); K.InputName = 'e';  K.OutputName = 'u';
%      S = sumblk('e = r - y');
%      T = connect(G, K, S, 'r', 'y');
%      max(abs(pole(T) - pole(feedback(series(K, G), 1)))) < 1e-9
%      % Plusieurs sorties d'un coup : la boucle fermée et la commande.
%      TU = connect(G, K, S, 'r', {'y', 'u'});
%      size(TU)                   % 2 sorties, 1 entree
%
%   Voir aussi SUMBLK, SYSIC, APPEND, FEEDBACK, SERIES, LFT.
    if numel(varargin) < 3
        error('MATLAB:narginchk:notEnoughInputs', ...
              'CONNECT needs blocks, then the input and output names.');
    end
    entreesDemandees = matlibre_liste_noms(varargin{end-1});
    sortiesDemandees = matlibre_liste_noms(varargin{end});
    blocs = varargin(1:end-2);
    if isempty(blocs)
        error('Control:connect:NoBlock', 'At least one block is needed.');
    end

    % Les blocs, leurs voies et leurs noms.
    modeles = cell(1, numel(blocs));
    nomsEntrees = {};
    nomsSorties = {};
    nbEntrees = zeros(1, numel(blocs));
    nbSorties = zeros(1, numel(blocs));
    for k = 1:numel(blocs)
        m = ss(blocs{k});
        modeles{k} = m;
        [nbSorties(k), nbEntrees(k)] = size(m);
        e = matlibre_liste_noms(m.InputName);
        s = matlibre_liste_noms(m.OutputName);
        if numel(e) ~= nbEntrees(k) || numel(s) ~= nbSorties(k)
            error('Control:connect:NoNames', ...
                  ['Block %d does not name all of its channels : set InputName and ' ...
                   'OutputName, or use SUMBLK.'], k);
        end
        nomsEntrees = [nomsEntrees; e(:)];    %#ok<AGROW>
        nomsSorties = [nomsSorties; s(:)];    %#ok<AGROW>
    end

    % Les sources : les sorties des blocs, puis les entrées du schéma qui
    % ne sont produites par personne.
    sources = nomsSorties;
    for k = 1:numel(entreesDemandees)
        if ~any(strcmp(sources, entreesDemandees{k}))
            sources{end+1} = entreesDemandees{k};   %#ok<AGROW>
        end
    end
    doublons = sources;
    for k = 1:numel(doublons)
        if sum(strcmp(sources, doublons{k})) > 1
            error('Control:connect:Duplicate', ...
                  'The signal ''%s'' is produced by more than one block.', doublons{k});
        end
    end

    % Ce qui entre dans chaque bloc, et ce qui sort du schéma.
    M1 = zeros(numel(nomsEntrees), numel(sources));
    for k = 1:numel(nomsEntrees)
        rang = find(strcmp(sources, nomsEntrees{k}), 1);
        if isempty(rang)
            error('Control:connect:Unknown', ...
                  ['The input ''%s'' is driven by nothing : it is neither an output of ' ...
                   'a block nor an input of the diagram.'], nomsEntrees{k});
        end
        M1(k, rang) = 1;
    end
    M2 = zeros(numel(sortiesDemandees), numel(sources));
    for k = 1:numel(sortiesDemandees)
        rang = find(strcmp(sources, sortiesDemandees{k}), 1);
        if isempty(rang)
            error('Control:connect:Unknown', ...
                  'The output ''%s'' is produced by nothing.', sortiesDemandees{k});
        end
        M2(k, rang) = 1;
    end
    % Les entrées du schéma sont les dernières sources ; ce qui vient
    % d'elles ne passe pas par la boucle.
    nu = sum(nbEntrees);
    ny = sum(nbSorties);
    externes = numel(sources) - ny;
    if externes < 0
        externes = 0;
    end

    A = modeles{1};
    for k = 2:numel(modeles)
        A = append(A, modeles{k});
    end
    % La matrice d'aiguillage envoie [sorties des blocs ; entrées du
    % schéma] vers [sorties du schéma ; entrées des blocs] ; LFT referme
    % la boucle sur les blocs. On range donc les colonnes dans l'ordre
    % qu'attend le produit étoile : les entrées du schéma d'abord.
    permutation = [ny + (1:externes), 1:ny];
    aiguillage = ss([M2(:, permutation); M1(:, permutation)]);
    sys = lft(aiguillage, A, nu, ny);
    sys.InputName = entreesDemandees(:);
    sys.OutputName = sortiesDemandees(:);
end
