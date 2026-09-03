function syms(varargin)
%SYMS Déclare des variables symboliques.
%   SYMS X Y Z crée dans l'espace de travail appelant les variables
%   symboliques nommées, comme si l'on avait écrit X = SYM('X') pour
%   chacune.
%
%   C'est un raccourci : tout ce qu'il fait, SYM le fait aussi, mais une
%   ligne suffit alors pour dix variables.
%
%   Exemple :
%      syms x y
%      f = x ^ 2 + y ^ 2;
%      diff(f, x)                     % 2*x
%
%   Voir aussi SYM, SYMVAR, DIFF, SUBS.
    if isempty(varargin)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    for k = 1:numel(varargin)
        nom = char(varargin{k});
        if isempty(regexp(nom, '^[A-Za-z][A-Za-z0-9_]*$', 'once'))
            error('symbolic:syms:Nom', ...
                  '''%s'' n''est pas un nom de variable valide.', nom);
        end
        assignin('caller', nom, sym(nom));
    end
end
