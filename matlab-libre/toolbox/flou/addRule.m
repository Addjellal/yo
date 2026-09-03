function fis = addRule(fis, regles)
%ADDRULE Ajoute des règles à un système flou.
%   FIS = ADDRULE(FIS,R) où R est une matrice, une ligne par règle :
%   [mfEntree1 ... mfEntreeN mfSortie1 ... mfSortieM POIDS OPERATEUR],
%   l'opérateur valant 1 pour « et » et 2 pour « ou ». Un zéro en place
%   d'une modalité veut dire « peu importe ».
%
%   FIS = ADDRULE(FIS,TEXTE) accepte aussi les règles écrites, une par
%   ligne d'un tableau de cellules :
%
%      "si service est faible alors pourboire est petit"
%
%   Les mots reconnus sont « si »/'if', « et »/'and', « ou »/'or',
%   « alors »/'then', « est »/'is' et « non »/'not'.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'service', 'NumMFs', 2);
%      fis = addOutput(fis, [0 30], 'Name', 'pourboire', 'NumMFs', 2);
%      fis = addRule(fis, {'si service est mf1 alors pourboire est mf1', ...
%                          'si service est mf2 alors pourboire est mf2'});
%      size(fis.regles, 1)            % 2
%
%   Voir aussi ADDRULE, SHOWRULE, EVALFIS, ADDINPUT.
    if ischar(regles) || isstring(regles) || iscell(regles)
        regles = lireRegles(fis, regles);
    end
    fis = addrule(fis, double(regles));
end

function matrice = lireRegles(fis, textes)
%LIREREGLES Traduit des règles écrites en la matrice qu'EVALFIS attend.
    if ischar(textes) || isstring(textes)
        textes = {char(textes)};
    end
    nEntrees = numel(fis.entrees);
    nSorties = numel(fis.sorties);
    matrice = zeros(numel(textes), nEntrees + nSorties + 2);
    for k = 1:numel(textes)
        matrice(k, :) = lireUneRegle(fis, char(textes{k}), nEntrees, nSorties);
    end
end

function ligne = lireUneRegle(fis, texte, nEntrees, nSorties)
    ligne = zeros(1, nEntrees + nSorties + 2);
    ligne(end - 1) = 1;        % poids
    ligne(end) = 1;            % « et » par défaut
    mots = strsplit(lower(strtrim(texte)));
    mots = mots(~cellfun(@isempty, mots));
    apresAlors = false;
    negation = false;
    k = 1;
    while k <= numel(mots)
        mot = mots{k};
        switch mot
            case {'si', 'if'}
                k = k + 1;
                continue
            case {'alors', 'then'}
                apresAlors = true;
                k = k + 1;
                continue
            case {'et', 'and'}
                ligne(end) = 1;
                k = k + 1;
                continue
            case {'ou', 'or'}
                ligne(end) = 2;
                k = k + 1;
                continue
            case {'non', 'not'}
                negation = true;
                k = k + 1;
                continue
            case {'est', 'is'}
                k = k + 1;
                continue
        end
        % Un mot qui n'est pas un mot-clé nomme une variable ; le suivant
        % qui n'en est pas un nomme sa modalité.
        [entree, indice] = trouverVariable(fis, mot);
        [modalite, k] = lireModalite(fis, mots, k + 1, entree, indice);
        if entree
            colonne = indice;
        else
            colonne = nEntrees + indice;
        end
        if negation
            ligne(colonne) = -modalite;
            negation = false;
        else
            ligne(colonne) = modalite;
        end
        apresAlors = apresAlors;   %#ok<ASGSL>
    end
end

function [modalite, k] = lireModalite(fis, mots, k, entree, indice)
    motsCles = {'est', 'is', 'non', 'not'};
    while k <= numel(mots) && any(strcmp(mots{k}, motsCles))
        k = k + 1;
    end
    if k > numel(mots)
        error('fuzzy:addRule:Modalite', 'Une règle nomme une variable sans modalité.');
    end
    variables = variablesDe(fis, entree);
    liste = variables{indice}.mf;
    modalite = 0;
    for m = 1:numel(liste)
        if strcmp(lower(liste{m}.nom), mots{k})
            modalite = m;
            break
        end
    end
    if modalite == 0
        error('fuzzy:addRule:Inconnue', ...
              'La variable ''%s'' n''a pas de modalité ''%s''.', ...
              variables{indice}.nom, mots{k});
    end
    k = k + 1;
end
