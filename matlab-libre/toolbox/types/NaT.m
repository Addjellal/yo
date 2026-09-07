function t = NaT(varargin)
%NAT Date manquante (« Not-a-Time »).
%   T = NAT construit un scalaire manquant ; NAT(N) une matrice N x N,
%   NAT(M,N) une matrice M x N.
%
%   Exemple :
%      t = NaT();
%      isnat(t)                    % 1 : la date manquante des datetime
%
%   Voir aussi DATETIME, ISNAT.
    if isempty(varargin)
        d = [1 1];
    elseif numel(varargin) == 1
        if isscalar(varargin{1})
            d = [varargin{1} varargin{1}];
        else
            d = varargin{1};
        end
    else
        d = cell2mat(varargin);
    end
    t = datetime.avec(nan(d), 'dd-MMM-uuuu HH:mm:ss', '');
end
