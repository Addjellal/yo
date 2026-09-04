function options = fitoptions(varargin)
%FITOPTIONS Réglages d'un ajustement.
%   OPT = FITOPTIONS() rend les réglages par défaut.
%   OPT = FITOPTIONS('Method',M,...) impose la méthode et les réglages.
%   OPT = FITOPTIONS(FT) rend les réglages qui conviennent au modèle FT :
%   la méthode s'en déduit, et les bornes que le modèle impose à ses
%   coefficients y figurent déjà.
%   OPT = FITOPTIONS(OPT,'Nom',VALEUR,...) modifie des réglages existants.
%
%   Champs et valeurs par défaut :
%     Method            déduite du modèle
%     Robust            'off' ; 'Bisquare' ou 'LAR' pondèrent à la baisse
%                       les points les plus éloignés, à chaque tour, ce
%                       qui empêche quelques valeurs aberrantes d'emporter
%                       l'ajustement
%     StartPoint        [] ; déduit des données quand il manque
%     Lower, Upper      [] ; bornes des coefficients
%     Weights           [] ; poids des observations
%     Exclude           [] ; masque des points à écarter
%     Normalize         'off' ; centre et réduit l'abscisse avant
%                       d'ajuster, ce qui conditionne les polynômes de
%                       degré élevé
%     MaxIter           400
%     TolFun, TolX      1e-8
%     SmoothingParam    [] ; entre 0 — une droite — et 1 — l'interpolation
%     Span              0.25 ; la part des points que voit un lissage local
%
%   Exemple :
%      opt = fitoptions('Method', 'NonlinearLeastSquares', 'StartPoint', [1 1]);
%
%   Voir aussi FIT, FITTYPE, SETOPTIONS.
    options = matlibre_options_defaut();
    debut = 1;
    if numel(varargin) >= 1 && isa(varargin{1}, 'fittype')
        options = matlibre_options_modele(varargin{1});
        debut = 2;
    elseif numel(varargin) >= 1 && isstruct(varargin{1})
        options = varargin{1};
        debut = 2;
    elseif numel(varargin) >= 1 && ischar(varargin{1}) && mod(numel(varargin), 2) == 1
        % Un premier argument seul est un nom de méthode.
        options.Method = char(varargin{1});
        debut = 2;
    end
    for k = debut:2:numel(varargin) - 1
        nom = matlibre_option_canonique(char(varargin{k}));
        options.(nom) = varargin{k + 1};
    end
end
