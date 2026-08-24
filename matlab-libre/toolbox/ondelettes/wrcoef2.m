function y = wrcoef2(genre, C, S, nom, niveau)
%WRCOEF2 Reconstruit une composante d'une décomposition d'image.
%   Y = WRCOEF2('a',C,S,NOM,N) reconstruit l'approximation, 'h', 'v' ou
%   'd' le détail correspondant, à la taille de l'image d'origine.
    if nargin < 4 || isempty(nom), nom = 'haar'; end
    niveauMax = size(S, 1) - 2;
    if nargin < 5 || isempty(niveau), niveau = niveauMax; end
    Cmodifie = zeros(size(C));
    genre = lower(char(genre));
    if genre == 'a'
        Cmodifie(1:prod(S(1, :))) = C(1:prod(S(1, :)));
    else
        position = prod(S(1, :));
        for k = niveauMax:-1:1
            taille = S(niveauMax - k + 2, :);
            n = prod(taille);
            if k == niveau
                switch genre
                    case 'h', decalage = 0;
                    case 'v', decalage = n;
                    otherwise, decalage = 2 * n;
                end
                plage = position + decalage + (1:n);
                Cmodifie(plage) = C(plage);
            end
            position = position + 3 * n;
        end
    end
    y = waverec2(Cmodifie, S, nom);
end
