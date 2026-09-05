function [meilleur, valeur, drapeau, sortie] = ga(fonction, nVariables, A, b, ...
                                                 Aeq, beq, bas, haut, ...
                                                 nonlineaires, options)
%GA Algorithme génétique à codage réel.
%   [X,F] = GA(FONCTION,N) minimise FONCTION de N variables.
%   [X,F] = GA(FONCTION,N,A,B) impose A X <= B.
%   [X,F] = GA(FONCTION,N,A,B,AEQ,BEQ) ajoute AEQ X = BEQ.
%   [X,F] = GA(FONCTION,N,A,B,AEQ,BEQ,BAS,HAUT) borne les variables.
%   [X,F] = GA(...,NONLIN,OPTIONS) ajoute des contraintes non linéaires et
%   des options. L'ordre des arguments est celui de MATLAB ; les
%   arguments intermédiaires peuvent rester vides.
%
%   [X,F,DRAPEAU,SORTIE] = GA(...) rend en outre un indicateur de
%   convergence et le compte des générations.
%
%   L'algorithme n'emploie aucune dérivée : il fait évoluer une population
%   par sélection, croisement et mutation. C'est ce qui le rend applicable
%   quand la fonction est bruitée, discontinue, ou seulement calculable —
%   et c'est aussi pourquoi il ne garantit rien.
%
%   Les contraintes sont traitées par pénalisation : une solution qui les
%   viole reçoit un score dégradé, proportionnel à la violation. C'est la
%   méthode la plus simple, et elle suffit tant que les contraintes ne
%   sont pas serrées au point que les solutions admissibles soient rares.
%
%   Options reconnues, dans une structure ou par OPTIMOPTIONS :
%      PopulationSize   50 par défaut
%      Generations      100
%      MutationRate     0.1
%
%   Exemple :
%      [x, f] = ga(@(v) sum(v .^ 2), 2, [], [], [], [], [-5 -5], [5 5]);
%      norm(x) < 0.1
%
%   Voir aussi PARTICLESWARM, SIMULANNEALBND, PATTERNSEARCH, GAMULTIOBJ.
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7, bas = []; end
    if nargin < 8, haut = []; end
    if nargin < 9, nonlineaires = []; end
    if nargin < 10 || isempty(options)
        options = struct();
    end
    if isempty(bas), bas = -10 * ones(1, nVariables); end
    if isempty(haut), haut = 10 * ones(1, nVariables); end
    % Les contraintes entrent dans le score par pénalisation : une
    % solution inadmissible est notée d'autant plus mal qu'elle s'écarte.
    fonctionBrute = fonction;
    fonction = @(x) fonctionBrute(x) + ...
        1e6 * matlibre_ga_violation(x, A, b, Aeq, beq, nonlineaires);
    taille = champOuDefaut(options, 'PopulationSize', 50);
    generations = champOuDefaut(options, 'Generations', 100);
    mutation = champOuDefaut(options, 'MutationRate', 0.1);
    bas = bas(:).';
    haut = haut(:).';
    population = repmat(bas, taille, 1) + rand(taille, nVariables) .* ...
                 repmat(haut - bas, taille, 1);
    scores = zeros(taille, 1);
    for k = 1:taille
        scores(k) = fonction(population(k, :));
    end
    for g = 1:generations
        [scores, ordre] = sort(scores);
        population = population(ordre, :);
        elite = max(2, round(taille / 5));
        nouvelle = population(1:elite, :);
        while size(nouvelle, 1) < taille
            a = population(randi([1 elite]), :);
            b = population(randi([1 elite]), :);
            alpha = rand(1, nVariables);
            enfant = alpha .* a + (1 - alpha) .* b;
            masque = rand(1, nVariables) < mutation;
            enfant(masque) = bas(masque) + rand(1, sum(masque)) .* ...
                             (haut(masque) - bas(masque));
            nouvelle(end+1, :) = enfant;
        end
        population = nouvelle(1:taille, :);
        for k = 1:taille
            scores(k) = fonction(population(k, :));
        end
    end
    [valeur, k] = min(scores);
    meilleur = population(k, :);
    % Le score rendu est celui de la fonction, non celui pénalisé : la
    % pénalisation sert à choisir, pas à mesurer.
    valeur = fonctionBrute(meilleur);
    if nargout > 2
        drapeau = 1;
    end
    if nargout > 3
        sortie = struct('generations', generations, 'funccount', ...
                        taille * (generations + 1), ...
                        'message', 'nombre de générations atteint');
    end
end

function v = champOuDefaut(s, nom, defaut)
    if isstruct(s) && isfield(s, nom)
        v = s.(nom);
    else
        v = defaut;
    end
end
