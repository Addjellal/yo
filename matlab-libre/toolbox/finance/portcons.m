function contraintes = portcons(varargin)
%PORTCONS Assemble un jeu de contraintes de portefeuille.
%   C = PORTCONS('Default',N) rend les contraintes usuelles : poids
%   positifs et somme égale à un.
%
%   Les types se suivent et s'ajoutent :
%      'Default',N                 budget un, poids positifs
%      'PortValue',VALEUR,N        budget donné, poids positifs
%      'AssetLims',MIN,MAX,N       bornes par actif
%      'GroupLims',GROUPES,MIN,MAX bornes par groupe
%      'Custom',A,B                contraintes quelconques A*w <= B
%
%   Exemple :
%      portcons('Default', 3, 'AssetLims', [0 0 0], [0.5 0.5 0.5])
%
%   Voir aussi PCPVAL, PCALIMS, PCGLIMS, PORTOPT, FRONTCON.
    contraintes = [];
    k = 1;
    while k <= numel(varargin)
        type = lower(char(varargin{k}));
        switch type
            case 'default'
                bloc = pcpval(1, varargin{k+1});
                k = k + 2;
            case 'portvalue'
                bloc = pcpval(varargin{k+1}, varargin{k+2});
                k = k + 3;
            case 'assetlims'
                if k + 3 <= numel(varargin) && isnumeric(varargin{k+3}) && ...
                        isscalar(varargin{k+3})
                    bloc = pcalims(varargin{k+1}, varargin{k+2}, varargin{k+3});
                    k = k + 4;
                else
                    bloc = pcalims(varargin{k+1}, varargin{k+2});
                    k = k + 3;
                end
            case 'grouplims'
                bloc = pcglims(varargin{k+1}, varargin{k+2}, varargin{k+3});
                k = k + 4;
            case 'custom'
                bloc = [double(varargin{k+1}), double(varargin{k+2}(:))];
                k = k + 3;
            otherwise
                error('finance:portcons:Type', ...
                      'Type de contrainte inconnu : %s.', type);
        end
        contraintes = [contraintes; bloc];   %#ok<AGROW>
    end
end
