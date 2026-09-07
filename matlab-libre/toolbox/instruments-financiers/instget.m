function varargout = instget(jeu, varargin)
%INSTGET Données d'un jeu d'instruments.
%   [A,B,...] = INSTGET(JEU,'FieldList',{'CouponRate','Maturity'}) rend
%   une sortie par champ demandé. 'Type' limite à un type d'instrument,
%   'Index' à des numéros donnés.
%
%   Un instrument dont le type ne porte pas le champ demandé rend NaN.
%
%   Exemple :
%      jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
%      jeu = instadd(jeu, 'Bond', 0.06, '01-Jan-2024', '01-Jan-2034');
%      [taux, echeance] = instget(jeu, 'FieldList', {'CouponRate','Maturity'})
%
%   Voir aussi INSTGETCELL, INSTSELECT, INSTFIELDS, INSTDISP.
    [donnees, noms] = instgetcell(jeu, varargin{:});
    if nargout <= 1 && numel(noms) > 1
        varargout{1} = donnees;
        return
    end
    for k = 1:max(nargout, 1)
        if k <= numel(donnees)
            varargout{k} = donnees{k};
        else
            varargout{k} = [];
        end
    end
end
