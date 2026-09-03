function bruit = wgn(m, n, puissance, imp, varargin)
%WGN Bruit blanc gaussien de puissance donnée.
%   Y = WGN(M,N,P) rend une matrice M par N de bruit blanc gaussien de
%   puissance P décibels par rapport au watt, sur une impédance d'un ohm.
%
%   Y = WGN(M,N,P,IMP) donne l'impédance en ohms.
%   Y = WGN(...,'linear') lit P en watts au lieu de décibels ;
%   'dBW' (défaut), 'dBm' et 'dBW' choisissent l'unité.
%   Y = WGN(...,'complex') rend un bruit complexe, la puissance étant
%   également partagée entre les deux voies.
%
%   Exemple :
%      y = wgn(1, 100000, 0);         % puissance un watt
%      abs(10 * log10(mean(y .^ 2)))  % voisin de zéro
%
%   Voir aussi AWGN, RANDN, RANDERR.
    if nargin < 3, error('MATLAB:minrhs', 'Not enough input arguments.'); end
    if nargin < 4 || isempty(imp), imp = 1; end
    complexe = false;
    unite = 'dbw';
    arguments_ = varargin;
    if nargin >= 4 && (ischar(imp) || isstring(imp))
        arguments_ = [{imp}, arguments_];
        imp = 1;
    end
    for k = 1:numel(arguments_)
        mot = lower(char(arguments_{k}));
        switch mot
            case 'complex', complexe = true;
            case 'real',    complexe = false;
            case {'dbw', 'dbm', 'linear'}, unite = mot;
            otherwise
                error('comm:wgn:Option', 'Option inconnue : %s.', mot);
        end
    end
    switch unite
        case 'dbw',    watts = 10 ^ (puissance / 10);
        case 'dbm',    watts = 10 ^ ((puissance - 30) / 10);
        case 'linear', watts = puissance;
    end
    if watts < 0
        error('comm:wgn:Puissance', 'La puissance ne peut pas être négative.');
    end
    % La puissance sur une impédance R vaut v^2/R : l'écart type de la
    % tension est donc racine de P fois R.
    ecartType = sqrt(watts * imp);
    if complexe
        bruit = (randn(m, n) + 1i * randn(m, n)) * ecartType / sqrt(2);
    else
        bruit = randn(m, n) * ecartType;
    end
end
