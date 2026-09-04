function jeu = instadd(varargin)
%INSTADD Ajoute des instruments à un jeu.
%   JEU = INSTADD('Bond',TAUX,REGLEMENT,ECHEANCE,...) crée un jeu et y
%   met des obligations. INSTADD(JEU,'OptStock',...) ajoute à un jeu
%   existant.
%
%   Les types reconnus sont 'Bond', 'CashFlow', 'Fixed', 'Float', 'Swap',
%   'OptStock', 'Barrier', 'Lookback', 'Asian', 'Cap', 'Floor' et
%   'Swaption'. Les arguments suivent l'ordre des champs du type, et les
%   champs omis prennent NaN.
%
%   Un jeu d'instruments sert à valoriser un portefeuille entier d'un
%   coup : INTENVPRICE prend le jeu et la courbe, et rend un prix par
%   instrument.
%
%   Exemple :
%      jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
%      jeu = instadd(jeu, 'Bond', 0.04, '01-Jan-2024', '01-Jan-2027');
%
%   Voir aussi INSTDISP, INSTGET, INSTSELECT, INSTLENGTH, INTENVPRICE.
    debut = 1;
    if ~isempty(varargin) && isstruct(varargin{1})
        jeu = varargin{1};
        debut = 2;
    else
        jeu = matlibre_jeu_vide();
    end
    if numel(varargin) < debut
        return
    end
    type = char(varargin{debut});
    [champs, classes] = matlibre_modele_instrument(type);
    if isempty(champs)
        error('finstr:instadd:Type', 'Type d''instrument inconnu : %s.', type);
    end
    donnees = varargin((debut + 1):end);
    jeu = matlibre_jeu_ajouter(jeu, type, champs, classes, donnees);
end
