function exclus = excludedata(x, y, methode, valeur)
%EXCLUDEDATA Masque des points à écarter d'un ajustement.
%   E = EXCLUDEDATA(X,Y,METHODE,VALEUR) rend un masque logique, vrai pour
%   les points à écarter. Ce masque se passe ensuite à FIT par l'option
%   'Exclude'.
%
%   Méthodes :
%     'box'       VALEUR vaut [xmin xmax ymin ymax] ; écarte ce qui est
%                 hors de la boîte
%     'domain'    VALEUR vaut [xmin xmax] ; écarte ce qui est hors de
%                 l'intervalle des abscisses
%     'range'     VALEUR vaut [ymin ymax] ; de même sur les ordonnées
%     'indices'   VALEUR donne les indices à écarter
%     'outliers'  VALEUR donne les résidus d'un premier ajustement ;
%                 écarte les points dont le résidu sort de plus d'une fois
%                 et demie l'écart interquartile hors des quartiles —
%                 la règle de Tukey, qui ne suppose rien de la loi du
%                 bruit
%
%   Exemple :
%      e = excludedata((1:10)', (1:10)', 'domain', [3 8]);
%      sum(e)      % 4 points ecartes
%
%   Voir aussi FIT, FITOPTIONS.
    x = double(x(:));
    y = double(y(:));
    n = numel(x);
    exclus = false(n, 1);
    switch lower(char(methode))
        case 'box'
            valeur = double(valeur);
            exclus = x < valeur(1) | x > valeur(2) | y < valeur(3) | y > valeur(4);
        case 'domain'
            valeur = double(valeur);
            exclus = x < valeur(1) | x > valeur(2);
        case 'range'
            valeur = double(valeur);
            exclus = y < valeur(1) | y > valeur(2);
        case 'indices'
            if islogical(valeur)
                exclus = valeur(:);
            else
                exclus(round(double(valeur))) = true;
            end
        case 'outliers'
            residus = double(valeur(:));
            quartiles = quantile(residus, [0.25 0.75]);
            interquartile = quartiles(2) - quartiles(1);
            exclus = residus < quartiles(1) - 1.5 * interquartile | ...
                     residus > quartiles(2) + 1.5 * interquartile;
        otherwise
            error('curvefit:excludedata:Methode', ...
                  'Méthode inconnue : %s.', char(methode));
    end
    exclus = reshape(logical(exclus), n, 1);
end
