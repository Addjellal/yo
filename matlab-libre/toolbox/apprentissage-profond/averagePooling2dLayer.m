function c = averagePooling2dLayer(taille, varargin)
%AVERAGEPOOLING2DLAYER Sous-échantillonnage par la moyenne.
%   C = AVERAGEPOOLING2DLAYER(TAILLE) découpe l'entrée en fenêtres de
%   TAILLE et remplace chacune par sa moyenne. TAILLE scalaire vaut pour
%   une fenêtre carrée. Par défaut le pas égale la taille : les fenêtres
%   ne se recouvrent pas et la carte est réduite d'autant.
%
%   C = AVERAGEPOOLING2DLAYER(TAILLE,'Stride',PAS) impose le pas, et
%   'Name' le nom de la couche.
%
%   Moyenner ou prendre le maximum ne dit pas la même chose. La moyenne
%   conserve le niveau général de la région et efface les pointes : elle
%   floute. Le maximum ne retient que la réponse la plus forte : il
%   répond « ce motif est présent quelque part ici », sans dire où. D'où
%   l'usage : moyenne quand l'intensité d'ensemble compte, maximum quand
%   c'est la présence d'un motif qui compte.
%
%   Exemple :
%      couche = averagePooling2dLayer(2);
%      couche = averagePooling2dLayer([3 3], 'Stride', 2);
%
%   Voir aussi MAXPOOLING2DLAYER, GLOBALAVERAGEPOOLING2DLAYER, AVGPOOL.
    if numel(taille) < 2, taille = [taille taille]; end
    pas = taille;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'stride')
            pas = varargin{k + 1};
            if numel(pas) < 2, pas = [pas pas]; end
        end
    end
    c = struct('type', 'avgpool', 'taille', taille(:)', 'pas', pas(:)', 'nom', matlibre_couche_nom(varargin));
end
