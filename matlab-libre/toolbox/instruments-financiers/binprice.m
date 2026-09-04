function [coursArbre, valeurArbre] = binprice(cours, exercice, taux, duree, pas, volatilite, drapeau, tauxDividende, dividendes, datesDetachement)
%BINPRICE Prix d'une option américaine par arbre binomial.
%   [S,V] = BINPRICE(COURS,EXERCICE,TAUX,DUREE,PAS,VOLATILITE,DRAPEAU)
%   rend l'arbre des cours et celui des valeurs de l'option. DRAPEAU vaut
%   1 pour un achat, 0 pour une vente. L'exercice est américain : la
%   valeur d'un nœud est le maximum entre le gain immédiat et la valeur
%   d'attente.
%
%   BINPRICE(...,TAUXDIVIDENDE) ajoute un rendement de dividende continu.
%   BINPRICE(...,DIVIDENDES,DATES) traite des dividendes en espèces : la
%   valeur actuelle des dividendes à venir est retirée du cours avant de
%   bâtir l'arbre, puis rendue nœud par nœud.
%
%   L'arbre est celui de Cox, Ross et Rubinstein : la hausse vaut
%   l'exponentielle de la volatilité par la racine du pas, la baisse son
%   inverse, ce qui fait se rejoindre les branches et laisse un nombre de
%   nœuds proportionnel au carré du nombre de pas, non à sa puissance.
%
%   Exemple :
%      [s, v] = binprice(100, 95, 0.05, 1, 1/50, 0.2, 1);
%      v(1, 1)                        % prix de l'option
%
%   Voir aussi CRRTREE, CRRPRICE, BLSPRICE, OPTSTOCKBYBLS.
    if nargin < 7 || isempty(drapeau),       drapeau = 1;       end
    if nargin < 8 || isempty(tauxDividende), tauxDividende = 0; end
    if nargin < 9,  dividendes = [];        end
    if nargin < 10, datesDetachement = [];  end
    n = max(round(duree / pas), 1);
    dt = duree / n;
    hausse = exp(volatilite * sqrt(dt));
    baisse = 1 / hausse;
    probabilite = (exp((taux - tauxDividende) * dt) - baisse) / (hausse - baisse);
    if probabilite < 0 || probabilite > 1
        error('finstr:binprice:Probabilite', ...
              ['Le pas est trop grand pour cette volatilité : la ' ...
               'probabilité risque-neutre sort de [0, 1].']);
    end
    % Dividendes en espèces : leur valeur actuelle sort du cours, puis
    % revient nœud par nœud. C'est le modèle dit du dividende séquestré,
    % qui garde l'arbre recombinant.
    dividendes = double(dividendes(:));
    temps = double(datesDetachement(:));
    valeurDividendes = zeros(n + 1, 1);
    for k = 0:n
        instant = k * dt;
        garde = temps > instant & temps <= duree;
        valeurDividendes(k + 1) = sum(dividendes(garde) .* ...
                                      exp(-taux * (temps(garde) - instant)));
    end
    base = cours - valeurDividendes(1);
    coursArbre = zeros(n + 1, n + 1);
    for k = 0:n
        rangs = (0:k).';
        coursArbre(1:(k + 1), k + 1) = base * hausse .^ (k - 2 * rangs) + ...
                                       valeurDividendes(k + 1);
    end
    valeurArbre = zeros(n + 1, n + 1);
    if drapeau
        gain = @(s) max(s - exercice, 0);
    else
        gain = @(s) max(exercice - s, 0);
    end
    valeurArbre(:, n + 1) = gain(coursArbre(:, n + 1));
    escompte = exp(-taux * dt);
    for k = (n - 1):-1:0
        suivant = valeurArbre(1:(k + 2), k + 2);
        attente = escompte * (probabilite * suivant(1:end-1) + ...
                              (1 - probabilite) * suivant(2:end));
        valeurArbre(1:(k + 1), k + 1) = max(attente, gain(coursArbre(1:(k + 1), k + 1)));
    end
end
