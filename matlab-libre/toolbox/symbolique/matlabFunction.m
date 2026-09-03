function poignee = matlabFunction(expression, varargin)
%MATLABFUNCTION Poignée de fonction à partir d'une expression symbolique.
%   F = MATLABFUNCTION(E) rend une poignée qui évalue E numériquement,
%   ses arguments étant les variables de E par ordre alphabétique.
%   F = MATLABFUNCTION(E,'Vars',{X,Y}) impose l'ordre des arguments.
%
%   C'est le pont entre le calcul formel et le calcul numérique : on
%   dérive ou simplifie en symbolique, puis on évalue par milliers.
%
%   Exemple :
%      syms x
%      f = matlabFunction(diff(x ^ 3));
%      f(2)                           % 12
%
%   Voir aussi SYM, DIFF, SUBS, DOUBLE, STR2FUNC.
    arbre = matlibre_sym_arbre(expression);
    noms = unique(matlibre_sym_noms(arbre));
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'vars'
                donnees = varargin{k+1};
                if ~iscell(donnees)
                    donnees = {donnees};
                end
                noms = cell(1, numel(donnees));
                for j = 1:numel(donnees)
                    noms{j} = matlibre_sym_nom(donnees{j});
                end
            case 'file'
                error('symbolic:matlabFunction:Fichier', ...
                      ['MatLibre ne rend qu''une poignée ; l''écriture ' ...
                       'dans un fichier n''est pas gérée.']);
            otherwise
                error('symbolic:matlabFunction:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    corps = matlibre_sym_ecrire(arbre, 0);
    % Les opérateurs deviennent des opérateurs terme à terme : la
    % poignée doit accepter un vecteur, comme celle de MATLAB.
    corps = strrep(corps, '*', '.*');
    corps = strrep(corps, '/', './');
    corps = strrep(corps, '^', '.^');
    if isempty(noms)
        texte = ['@() ' corps];
    else
        texte = ['@(' strjoin(noms, ', ') ') ' corps];
    end
    poignee = str2func(texte);
end
