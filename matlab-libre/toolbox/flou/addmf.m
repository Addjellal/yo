function fis = addmf(fis, genre, indice, nom, type, parametres)
%ADDMF Ajoute une fonction d'appartenance à une variable.
%   FIS = ADDMF(FIS,GENRE,INDICE,NOM,TYPE,PARAMETRES) ajoute à la variable
%   numéro INDICE — d'entrée si GENRE vaut 'input', de sortie sinon — une
%   fonction d'appartenance nommée NOM, de forme TYPE ('trimf', 'trapmf',
%   'gaussmf', 'gbellmf', 'sigmf') et de paramètres PARAMETRES.
%
%   Une fonction d'appartenance est ce qui remplace le seuil : au lieu de
%   décider qu'au-delà de 25 degrés il fait chaud, elle donne à chaque
%   température un degré d'appartenance à « chaud », entre zéro et un. Un
%   même point appartient donc à plusieurs ensembles à la fois, et c'est
%   ce recouvrement qui rend continue la sortie du contrôleur : sans lui,
%   la commande sauterait au franchissement de chaque seuil.
%
%   Les fonctions d'une même variable doivent se recouvrir sans laisser de
%   trou, faute de quoi aucune règle ne se déclenche dans l'intervalle
%   découvert et la sortie est indéterminée.
%
%   Exemple :
%      fis = mamfis('Name', 'exemple');
%      fis = addInput(fis, [0 40], 'Name', 'temperature');
%      fis = addmf(fis, 'input', 1, 'chaud', 'gaussmf', [5 30]);
%
%   Voir aussi ADDINPUT, ADDOUTPUT, ADDRULE, GAUSSMF, TRIMF.
    mf = struct();
    mf.nom = nom;
    mf.type = type;
    mf.parametres = parametres;
    if strcmpi(genre, 'input')
        v = fis.entrees{indice};
        v.mf{end+1} = mf;
        fis.entrees{indice} = v;
    else
        v = fis.sorties{indice};
        v.mf{end+1} = mf;
        fis.sorties{indice} = v;
    end
end
