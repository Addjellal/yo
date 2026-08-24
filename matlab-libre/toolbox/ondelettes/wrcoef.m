function y = wrcoef(genre, C, L, nom, niveau)
%WRCOEF Reconstruit une composante d'une décomposition monodimensionnelle.
%   Y = WRCOEF('a',C,L,NOM,N) reconstruit l'approximation du niveau N à
%   la longueur du signal d'origine, les autres coefficients étant mis à
%   zéro. 'd' reconstruit le détail.
%
%   Exemple :
%      [c, l] = wavedec(1:8, 2, 'haar');
%      a2 = wrcoef('a', c, l, 'haar', 2);
    if nargin < 4 || isempty(nom), nom = 'haar'; end
    niveauMax = numel(L) - 2;
    if nargin < 5 || isempty(niveau), niveau = niveauMax; end
    Cmodifie = zeros(size(C));
    if lower(char(genre)) == 'a'
        if niveau ~= niveauMax
            % On reconstruit l'approximation d'un niveau intermédiaire en
            % repartant du niveau le plus grossier.
            y = wrcoef('a', C, L, nom, niveauMax);
            for k = niveauMax-1:-1:niveau
                y = y + wrcoef('d', C, L, nom, k + 1);
            end
            return
        end
        Cmodifie(1:L(1)) = C(1:L(1));
    else
        position = L(1);
        for k = niveauMax:-1:1
            n = L(niveauMax - k + 2);
            if k == niveau
                Cmodifie(position + (1:n)) = C(position + (1:n));
            end
            position = position + n;
        end
    end
    y = waverec(Cmodifie, L, nom);
end
