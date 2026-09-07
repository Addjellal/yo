function options = bvpset(varargin)
%BVPSET Réglages de BVP4C.
%   OPTIONS = BVPSET('Nom',VALEUR,...) construit la structure de réglages.
%   Reconnus : 'RelTol' (1e-6), 'AbsTol' (1e-6), 'NMax' (nombre maximal
%   d'itérations de Newton, 50), 'Stats'.
%   OPTIONS = BVPSET(ANCIENNES,'Nom',VALEUR,...) part d'une structure.
%
%   Exemple :
%      o = bvpset('RelTol', 1e-8);
%      o.RelTol                        % 1e-08
%      o2 = bvpset(o, 'NMax', 100);
%      o2.RelTol                       % 1e-08 : l'ancienne valeur est gardee
%
%   Voir aussi BVP4C, BVPINIT, ODESET.
    options = struct('RelTol', 1e-6, 'AbsTol', 1e-6, 'NMax', 50, 'Stats', 'off');
    k = 1;
    if ~isempty(varargin) && isstruct(varargin{1})
        anciennes = varargin{1};
        noms = fieldnames(anciennes);
        for j = 1:numel(noms)
            options.(noms{j}) = anciennes.(noms{j});
        end
        k = 2;
    end
    while k + 1 <= numel(varargin)
        nom = char(varargin{k});
        connus = fieldnames(options);
        j = find(strcmpi(connus, nom), 1);
        if isempty(j)
            error('MATLAB:bvpset:UnknownOption', 'Option inconnue : %s.', nom);
        end
        options.(connus{j}) = varargin{k + 1};
        k = k + 2;
    end
end
