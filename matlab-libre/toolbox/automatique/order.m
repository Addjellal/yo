function n = order(sys)
%ORDER Nombre d'états du modèle.
%   Pour un modèle d'état, c'est la dimension de A ; pour une fonction de
%   transfert, le degré du dénominateur une fois les zéros de tête
%   retirés.
%
%   Exemple :
%      order(tf(1, [1 2 1]))   % 2
%
%   Voir aussi MINREAL, SSDATA.
    if strcmp(sys.type, 'ss')
        n = size(sys.A, 1);
        return
    end
    den = sys.den;
    premier = find(abs(den) > 0, 1);
    if isempty(premier)
        n = 0;
    else
        n = numel(den) - premier;
    end
end
