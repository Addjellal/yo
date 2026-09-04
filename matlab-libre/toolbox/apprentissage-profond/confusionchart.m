function [matrice, classes] = confusionchart(vraies, predites, varargin)
%CONFUSIONCHART Matrice de confusion, affichée.
%   CONFUSIONCHART(VRAIES,PREDITES) dessine la matrice qui croise les
%   classes réelles et les classes prédites : la diagonale porte les
%   bonnes réponses, et chaque case hors diagonale dit quelle classe a été
%   prise pour quelle autre. C'est ce que la seule justesse ne dit pas.
%
%   [M,C] = CONFUSIONCHART(...) rend la matrice et la liste des classes
%   sans rien dessiner.
%
%   CONFUSIONCHART(M,C) accepte aussi une matrice déjà calculée et la
%   liste des classes.
%
%   Options et valeurs par défaut :
%     'Normalization'   'absolute', ou 'row-normalized' pour lire des
%                       taux de rappel par ligne
%     'Title'           le titre de la figure
%
%   Exemple :
%      confusionchart({'a','b','a'}, {'a','b','b'});
%
%   Voir aussi CONFUSIONMAT, ONEHOTDECODE, ANALYZENETWORK.
    normalisation = 'absolute';
    titre = 'Matrice de confusion';
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'normalization', normalisation = lower(char(varargin{k + 1}));
            case 'title',         titre = char(varargin{k + 1});
        end
    end
    if isnumeric(vraies) && ~isvector(vraies) && (iscell(predites) || iscategorical(predites))
        matrice = double(vraies);
        classes = predites;
    else
        [matrice, classes] = confusionmat(vraies, predites);
    end
    if iscategorical(classes)
        classes = cellstr(classes);
    elseif isnumeric(classes)
        classes = cellstr(num2str(classes(:)));
    end
    if strcmp(normalisation, 'row-normalized')
        totaux = sum(matrice, 2);
        totaux(totaux == 0) = 1;
        matrice = matrice ./ totaux;
    end
    if nargout > 0
        return
    end
    matlibre_dessiner_confusion(matrice, classes, titre);
end
