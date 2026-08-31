function h = findobj(varargin)
%FINDOBJ Cherche des objets graphiques par leurs propriétés.
%   H = FINDOBJ rend toutes les courbes de l'axe courant.
%
%   H = FINDOBJ('Type','line') ne rend que les courbes ; 'text' ne rend
%   que les textes.
%
%   H = FINDOBJ('Nom',VALEUR) ne garde que les objets dont la propriété
%   nommée vaut VALEUR — par exemple FINDOBJ('Color','#D95319') ou
%   FINDOBJ('LineWidth',2).
%
%   H = FINDOBJ(AX,...) cherche dans l'axe AX plutôt que dans l'axe
%   courant.
%
%   MATLAB cherche dans tout l'arbre des objets graphiques, figures
%   comprises ; MatLibre s'en tient au contenu d'un axe, qui est ce que
%   son modèle porte.
%
%   Exemples :
%      plot(1:10, 'r'); hold on; plot((1:10).^2, 'b'); hold off
%      rouges = findobj('Color', '#D95319');
%      set(rouges, 'LineWidth', 3);
%
%      textes = findobj('Type', 'text');
%
%   Voir aussi GCA, GCF, GET, SET, GCO, ALLCHILD.
    entrees = varargin;
    cible = [];
    if ~isempty(entrees) && ~(ischar(entrees{1}) || isstring(entrees{1}))
        cible = entrees{1};
        entrees = entrees(2:end);
    end
    if isempty(cible)
        cible = gca();
    end
    enfants = get(cible, 'Children');
    garde = true(numel(enfants), 1);
    k = 1;
    while k + 1 <= numel(entrees)
        nom = char(entrees{k});
        attendue = entrees{k + 1};
        for i = 1:numel(enfants)
            if ~garde(i)
                continue;
            end
            valeur = get(enfants(i), nom);
            garde(i) = memeValeur(valeur, attendue);
        end
        k = k + 2;
    end
    h = enfants(garde);
end

function pareil = memeValeur(a, b)
%MEMEVALEUR Compare une propriété lue à la valeur cherchée.
    if (ischar(a) || isstring(a)) && (ischar(b) || isstring(b))
        pareil = strcmpi(char(a), char(b));
    elseif isnumeric(a) && isnumeric(b)
        pareil = isequal(size(a), size(b)) && all(abs(a(:) - b(:)) < 1e-12);
    else
        pareil = isequal(a, b);
    end
end
