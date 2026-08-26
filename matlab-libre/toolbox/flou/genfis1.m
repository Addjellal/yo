function fis = genfis1(donnees, nombreMf, typeEntree, typeSortie)
%GENFIS1 Système de Sugeno par partition régulière de l'espace d'entrée.
%   FIS = GENFIS1(DONNEES) construit un système à partir d'une matrice
%   dont les dernières colonnes sont la sortie et les précédentes les
%   entrées. Chaque entrée reçoit deux fonctions d'appartenance
%   gaussiennes réparties uniformément sur son étendue, et il y a une
%   règle par combinaison.
%
%   FIS = GENFIS1(DONNEES,N) donne N fonctions par entrée, ou un vecteur
%   d'autant d'éléments qu'il y a d'entrées.
%   FIS = GENFIS1(DONNEES,N,TYPEENTREE,TYPESORTIE) choisit les types :
%   'gaussmf' par défaut à l'entrée, 'linear' à la sortie ('constant'
%   étant l'autre possibilité).
%
%   Le système obtenu ne sait rien encore : ses conclusions sont nulles.
%   C'est le point de départ d'ANFIS, qui les ajustera.
%
%   Le nombre de règles croît comme N puissance le nombre d'entrées :
%   au-delà de trois ou quatre entrées, GENFIS2 est préférable.
%
%   Exemple :
%      donnees = [(0:0.1:10)', sin(0:0.1:10)'];
%      fis = genfis1(donnees, 5);
%      numel(fis.regles(:,1))   % 5
%
%   Voir aussi GENFIS2, ANFIS, EVALFIS.
    if nargin < 2 || isempty(nombreMf), nombreMf = 2; end
    if nargin < 3 || isempty(typeEntree), typeEntree = 'gaussmf'; end
    if nargin < 4 || isempty(typeSortie), typeSortie = 'linear'; end
    donnees = double(donnees);
    nEntrees = size(donnees, 2) - 1;
    if nEntrees < 1
        error('fuzzy:genfis1:BadData', 'Il faut au moins une entrée et une sortie.');
    end
    if numel(nombreMf) == 1
        nombreMf = repmat(nombreMf, 1, nEntrees);
    end
    fis = newfis('genfis1', 'sugeno');
    for k = 1:nEntrees
        colonne = donnees(:, k);
        bas = min(colonne);
        haut = max(colonne);
        if haut == bas, haut = bas + 1; end
        fis = addvar(fis, 'input', sprintf('in%d', k), [bas haut]);
        centres = linspace(bas, haut, nombreMf(k));
        largeur = (haut - bas) / (2 * max(nombreMf(k) - 1, 1));
        for j = 1:nombreMf(k)
            fis = addmf(fis, 'input', k, sprintf('in%dmf%d', k, j), typeEntree, ...
                        parametresEntree(typeEntree, centres(j), largeur, bas, haut));
        end
    end
    colonneSortie = donnees(:, end);
    fis = addvar(fis, 'output', 'out1', [min(colonneSortie) max(colonneSortie)]);
    combinaisons = grilleIndices(nombreMf);
    nRegles = size(combinaisons, 1);
    for r = 1:nRegles
        if strcmpi(typeSortie, 'constant')
            parametres = 0;
        else
            parametres = zeros(1, nEntrees + 1);
        end
        fis = addmf(fis, 'output', 1, sprintf('out1mf%d', r), lower(char(typeSortie)), parametres);
    end
    regles = [combinaisons, (1:nRegles)', ones(nRegles, 1), ones(nRegles, 1)];
    fis = addrule(fis, regles);
end

function p = parametresEntree(type, centre, largeur, bas, haut)
    switch lower(char(type))
        case 'gaussmf'
            p = [largeur, centre];
        case 'trimf'
            p = [centre - 2 * largeur, centre, centre + 2 * largeur];
        case 'trapmf'
            p = [centre - 2 * largeur, centre - largeur, centre + largeur, centre + 2 * largeur];
        case 'gbellmf'
            p = [2 * largeur, 2, centre];
        otherwise
            p = [largeur, centre];
    end
    p = double(p);
    bas = bas; haut = haut;   %#ok<NASGU,ASGSL>
end

function grille = grilleIndices(nombreMf)
%GRILLEINDICES Toutes les combinaisons d'indices, la dernière entrée
%   variant le plus vite.
    nEntrees = numel(nombreMf);
    total = prod(nombreMf);
    grille = zeros(total, nEntrees);
    repetition = 1;
    for k = nEntrees:-1:1
        motif = repmat(reshape(repmat(1:nombreMf(k), repetition, 1), [], 1), ...
                       total / (nombreMf(k) * repetition), 1);
        grille(:, k) = motif;
        repetition = repetition * nombreMf(k);
    end
end
