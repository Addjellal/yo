function [dictionnaire, longueurMoyenne] = huffmandict(symboles, probabilites, base, variante)
%HUFFMANDICT Dictionnaire de Huffman.
%   DICT = HUFFMANDICT(SYMBOLES,P) construit le code de Huffman des
%   symboles donnés, de probabilités P. DICT est une cellule à deux
%   colonnes : le symbole, puis son mot de code, vecteur de chiffres.
%
%   [DICT,L] = HUFFMANDICT(...) rend en outre la longueur moyenne du
%   code, somme des P(i) fois la longueur du mot i.
%
%   HUFFMANDICT(...,N) construit un code en base N (deux par défaut).
%
%   Le code est construit en réunissant à chaque tour les deux symboles
%   les moins probables : le plus rare écope du mot le plus long. C'est
%   le code préfixe de longueur moyenne minimale, laquelle reste entre
%   l'entropie et l'entropie plus un.
%
%   Exemple :
%      [d, l] = huffmandict({'a','b','c'}, [0.5 0.25 0.25]);
%      l                              % 1.5 : l'entropie exactement
%      d{1, 2}                        % le mot du symbole le plus probable
%
%   Voir aussi HUFFMANENCO, HUFFMANDECO, QUANTIZ.
    if nargin < 3 || isempty(base), base = 2; end
    if nargin < 4, variante = ''; end   %#ok<NASGU>
    base = round(base);
    if base < 2
        error('comm:huffmandict:Base', 'La base doit valoir au moins deux.');
    end
    probabilites = double(probabilites(:)).';
    n = numel(probabilites);
    if iscell(symboles)
        listeSymboles = symboles(:);
    else
        listeSymboles = num2cell(double(symboles(:)));
    end
    if numel(listeSymboles) ~= n
        error('comm:huffmandict:Taille', ...
              'Il faut autant de probabilités que de symboles.');
    end
    if any(probabilites < 0) || abs(sum(probabilites) - 1) > 1e-6
        error('comm:huffmandict:Probabilites', ...
              'Les probabilités doivent être positives et sommer à un.');
    end
    if n == 1
        dictionnaire = {listeSymboles{1}, 0};
        longueurMoyenne = 1;
        return
    end
    % Chaque nœud porte sa probabilité et la liste des symboles qu'il
    % couvre. On réunit les moins probables jusqu'à n'en garder qu'un.
    poids = probabilites;
    feuilles = cell(1, n);
    for k = 1:n
        feuilles{k} = k;
    end
    mots = cell(1, n);
    for k = 1:n
        mots{k} = [];
    end
    % En base N, il faut que le nombre de feuilles soit congru à un
    % modulo N-1 : on ajoute des symboles fictifs de probabilité nulle.
    manque = mod(1 - n, base - 1);
    for k = 1:manque
        poids(end + 1) = 0;            %#ok<AGROW>
        feuilles{end + 1} = [];        %#ok<AGROW>
    end
    while numel(poids) > 1
        [~, ordre] = sort(poids);
        choisis = ordre(1:base);
        nouveauxSymboles = [];
        for j = 1:base
            noeud = feuilles{choisis(j)};
            for s = 1:numel(noeud)
                mots{noeud(s)} = [j - 1, mots{noeud(s)}];
            end
            nouveauxSymboles = [nouveauxSymboles, noeud];   %#ok<AGROW>
        end
        nouveauPoids = sum(poids(choisis));
        garder = true(1, numel(poids));
        garder(choisis) = false;
        poids = [poids(garder), nouveauPoids];
        restants = feuilles(garder);
        restants{end + 1} = nouveauxSymboles;   %#ok<AGROW>
        feuilles = restants;
    end
    dictionnaire = cell(n, 2);
    longueurMoyenne = 0;
    for k = 1:n
        dictionnaire{k, 1} = listeSymboles{k};
        dictionnaire{k, 2} = mots{k};
        longueurMoyenne = longueurMoyenne + probabilites(k) * numel(mots{k});
    end
end
