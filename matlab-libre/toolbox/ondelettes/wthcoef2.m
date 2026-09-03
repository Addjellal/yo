function Cnouveau = wthcoef2(genre, C, S, niveaux, parametre, sorh)
%WTHCOEF2 Annule, atténue ou seuille les coefficients d'une image.
%   NC = WTHCOEF2('h',C,S) annule tous les détails horizontaux ; 'v' et
%   'd' font de même pour les verticaux et les diagonaux, 'a' pour
%   l'approximation.
%   NC = WTHCOEF2(GENRE,C,S,N) n'agit que sur les niveaux nommés par N.
%   NC = WTHCOEF2(GENRE,C,S,N,P) multiplie le niveau N(i) par P(i).
%   NC = WTHCOEF2('t',C,S,N,T,SORH) seuille les trois détails du niveau
%   N(i) au seuil T(i), par seuillage dur ('h', défaut) ou doux ('s').
%
%   Exemple :
%      [c, s] = wavedec2(magic(16), 2, 'db2');
%      nc = wthcoef2('h', c, s, 1);         % le détail horizontal fin part
%      nc = wthcoef2('t', c, s, 1:2, 5, 's');
%
%   Voir aussi WTHCOEF, WTHRESH, WDENCMP, WAVEDEC2.
    Cnouveau = C;
    genre = lower(char(genre));
    genre = genre(1);
    niveauMax = size(S, 1) - 2;
    if genre == 'a'
        Cnouveau(1:prod(S(1, :))) = 0;
        return
    end
    if nargin < 4 || isempty(niveaux)
        niveaux = 1:niveauMax;
    end
    niveaux = niveaux(:)';
    if nargin < 5, parametre = []; end
    if nargin < 6 || isempty(sorh), sorh = 'h'; end
    if genre == 't'
        familles = 1:3;
    else
        familles = trouverFamille(genre);
    end
    for indice = 1:numel(niveaux)
        niveau = niveaux(indice);
        if niveau < 1 || niveau > niveauMax
            error('wavelet:wthcoef2:Niveau', 'Niveau hors de la décomposition.');
        end
        for famille = familles
            plage = plageDe(S, niveau, famille);
            if genre == 't'
                seuil = valeurAu(parametre, indice, 0);
                Cnouveau(plage) = wthresh(Cnouveau(plage), sorh, seuil);
            elseif isempty(parametre)
                Cnouveau(plage) = 0;
            else
                Cnouveau(plage) = Cnouveau(plage) * valeurAu(parametre, indice, 1);
            end
        end
    end
end

function famille = trouverFamille(genre)
    switch genre
        case 'h', famille = 1;
        case 'v', famille = 2;
        case 'd', famille = 3;
        otherwise
            error('wavelet:wthcoef2:Genre', ...
                  'Le genre doit être ''a'', ''h'', ''v'', ''d'' ou ''t''.');
    end
end

function plage = plageDe(S, niveau, famille)
%PLAGEDE Indices d'un bloc de détail dans le vecteur de coefficients.
%   Le vecteur va du niveau le plus grossier au plus fin : le niveau K
%   occupe donc la ligne (niveauMax - K + 2) de S.
    niveauMax = size(S, 1) - 2;
    position = prod(S(1, :));
    for k = 1:niveauMax
        n = prod(S(k + 1, :));
        courant = niveauMax - k + 1;
        if courant == niveau
            debut = position + (famille - 1) * n;
            plage = debut + (1:n);
            return
        end
        position = position + 3 * n;
    end
    error('wavelet:wthcoef2:Niveau', 'Niveau hors de la décomposition.');
end

function v = valeurAu(parametre, indice, defaut)
    if isempty(parametre)
        v = defaut;
    elseif isscalar(parametre)
        v = parametre;
    else
        v = parametre(indice);
    end
end
