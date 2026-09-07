function mustBeInRange(a, bas, haut, varargin)
%MUSTBEINRANGE Exige une valeur dans un intervalle.
%   MUSTBEINRANGE(A,BAS,HAUT) refuse tout élément hors de [BAS,HAUT],
%   bornes comprises.
%   MUSTBEINRANGE(A,BAS,HAUT,'exclude-lower') ouvre la borne basse ;
%   'exclude-upper' ouvre la haute ; 'exclusive' ouvre les deux.
%
%   Le choix des bornes ouvertes ou fermées n'est pas un détail : une
%   probabilité vit dans [0,1] fermé, un taux d'apprentissage dans ]0,1[
%   ouvert — zéro n'apprend rien et un diverge.
%
%   Exemple :
%      mustBeInRange(0.5, 0, 1);                        % passe
%      mustBeInRange(0, 0, 1);                          % passe : borne fermee
%      mustBeInRange(0.5, 0, 1, 'exclusive');           % passe
%
%   Voir aussi MUSTBEGREATERTHAN, MUSTBELESSTHAN, MUSTBEPOSITIVE.
    basOuvert = false;
    hautOuvert = false;
    for k = 1:numel(varargin)
        switch lower(char(varargin{k}))
            case 'exclude-lower', basOuvert = true;
            case 'exclude-upper', hautOuvert = true;
            case 'exclusive',     basOuvert = true; hautOuvert = true;
            case 'inclusive'
            otherwise
                error('MATLAB:validators:mustBeInRange', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    v = a(:);
    if basOuvert, dessus = all(v > bas); else, dessus = all(v >= bas); end
    if hautOuvert, dessous = all(v < haut); else, dessous = all(v <= haut); end
    matlibre_valider(dessus && dessous, 'MATLAB:validators:mustBeInRange', ...
                     'La valeur doit être entre %g et %g.', bas, haut);
end
