function y = matlibre_dl_construire(valeur, format, noeud)
%MATLIBRE_DL_CONSTRUIRE Attache un résultat à un nœud existant.
%   Y = MATLIBRE_DL_CONSTRUIRE(VALEUR,FORMAT,NOEUD) fabrique le DLARRAY
%   qui porte VALEUR et se rattache au nœud déjà enregistré. Le
%   constructeur public, lui, crée toujours une feuille : il sert aux
%   données qui entrent dans le calcul, pas aux résultats intermédiaires.
%
%   Exemple :
%      y = matlibre_dl_construire([1 2], 'CB', 0);
%      extractdata(y)     % 1 2
%
%   Voir aussi DLARRAY, MATLIBRE_BANDE.
    y = dlarray();
    y.Valeur = valeur;
    y.Format = format;
    y.Noeud = noeud;
end
