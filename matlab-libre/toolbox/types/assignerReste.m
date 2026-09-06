function v = assignerReste(v, s, valeur)
%ASSIGNERRESTE Applique une suite d'accès subsasgn à une valeur ordinaire.
%   V = ASSIGNERRESTE(V,S,VALEUR) applique la suite d'indexations S à V et
%   y écrit VALEUR, en s'arrêtant quand S est épuisée.
%
%   Elle sert aux classes qui définissent SUBSASGN : après avoir traité le
%   premier niveau d'indexation, il leur reste à appliquer les suivants à
%   une valeur ordinaire. Écrire « t.Var(3) = 5 » demande cela : la classe
%   gère le « .Var », puis délègue le « (3) ».
%
%   Fonction interne aux boîtes à outils de types : elle n'existe pas dans
%   MATLAB.
%
%   Voir aussi SUBSASGN, APPLIQUERRESTE.
    if isempty(s)
        v = valeur;
        return;
    end
    switch s(1).type
        case '()'
            indices = s(1).subs;
            if numel(s) == 1
                v(indices{:}) = valeur;
            else
                sous = v(indices{:});
                v(indices{:}) = assignerReste(sous, s(2:end), valeur);
            end
        case '{}'
            indices = s(1).subs;
            if numel(s) == 1
                v{indices{:}} = valeur;
            else
                sous = v{indices{:}};
                v{indices{:}} = assignerReste(sous, s(2:end), valeur);
            end
        case '.'
            nom = s(1).subs;
            if numel(s) == 1
                v.(nom) = valeur;
            else
                sous = v.(nom);
                v.(nom) = assignerReste(sous, s(2:end), valeur);
            end
    end
end
