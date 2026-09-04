function sortie = matlibre_bande(action, varargin)
%MATLIBRE_BANDE Bande d'enregistrement de la dérivation automatique.
%   MATLIBRE_BANDE('ouvrir') vide la bande et commence à enregistrer.
%   MATLIBRE_BANDE('fermer') arrête l'enregistrement.
%   N = MATLIBRE_BANDE('ajouter',OPERATION,PARENTS,DONNEES) ajoute un
%   nœud et rend son numéro, ou zéro si la bande est fermée.
%   NOEUDS = MATLIBRE_BANDE('lire') rend tous les nœuds enregistrés.
%   V = MATLIBRE_BANDE('actif') dit si l'enregistrement est en cours.
%
%   Chaque opération sur un DLARRAY ajoute un nœud qui retient de quoi
%   elle est issue et ce qu'il faut pour la dériver. Comme les nœuds sont
%   ajoutés dans l'ordre du calcul, les parcourir à l'envers suffit à
%   propager la dérivée : c'est la dérivation en mode inverse, qui donne
%   toutes les dérivées partielles d'un scalaire pour le prix d'un seul
%   parcours.
%
%   Exemple :
%      matlibre_bande('ouvrir');
%      x = dlarray(3);
%      y = x * x;
%      matlibre_bande('nombre')     % trois nœuds
%      matlibre_bande('fermer');
%
%   Voir aussi DLARRAY, DLFEVAL, DLGRADIENT.
    persistent noeuds actif nombre
    if isempty(actif)
        actif = false;
        noeuds = {};
        nombre = 0;
    end
    sortie = [];
    switch action
        case 'ouvrir'
            noeuds = cell(1, 1024);
            nombre = 0;
            actif = true;
        case 'fermer'
            actif = false;
        case 'vider'
            noeuds = {};
            nombre = 0;
            actif = false;
        case 'actif'
            sortie = actif;
        case 'nombre'
            sortie = nombre;
        case 'ajouter'
            if ~actif
                sortie = 0;
                return
            end
            nombre = nombre + 1;
            if nombre > numel(noeuds)
                % Doubler plutôt qu'agrandir d'un : sinon le coût du
                % recopiage devient quadratique en nombre d'opérations.
                noeuds = [noeuds, cell(1, numel(noeuds) + 1)];
            end
            noeud.operation = varargin{1};
            noeud.parents = varargin{2};
            noeud.donnees = varargin{3};
            noeuds{nombre} = noeud;
            sortie = nombre;
        case 'lire'
            sortie = noeuds(1:nombre);
        otherwise
            error('nnet:bande:Action', 'Action inconnue : %s.', action);
    end
end
