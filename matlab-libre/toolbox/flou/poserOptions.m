function options = poserOptions(options, nomFonction, varargin)
%POSEROPTIONS Applique des couples nom-valeur à une structure d'options.
%   Un nom qui n'est pas déjà un champ est refusé : c'est ce qui
%   distingue une faute de frappe d'un réglage.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if numel(varargin) == 1 && isstruct(varargin{1})
        fournies = varargin{1};
        noms = fieldnames(fournies);
        for k = 1:numel(noms)
            options = poserUn(options, nomFonction, noms{k}, fournies.(noms{k}));
        end
        return
    end
    if mod(numel(varargin), 2) ~= 0
        error('fuzzy:options:Couples', ...
              '%s attend des couples nom-valeur.', nomFonction);
    end
    for k = 1:2:numel(varargin)
        options = poserUn(options, nomFonction, char(varargin{k}), varargin{k+1});
    end
end

function options = poserUn(options, nomFonction, nom, valeur)
    champs = fieldnames(options);
    for k = 1:numel(champs)
        if strcmpi(champs{k}, nom)
            options.(champs{k}) = valeur;
            return
        end
    end
    error('fuzzy:options:Inconnue', ...
          '%s ne connaît pas l''option ''%s''.', nomFonction, nom);
end
