function v = appliquerReste(v, s)
%APPLIQUERRESTE Applique une suite d'accès subsref à une valeur ordinaire.
%   V = APPLIQUERRESTE(V,S) où S est la structure décrite par la
%   documentation de subsref : champs « type » et « subs ». Les classes de
%   ce dossier s'en servent pour traiter la fin d'une chaîne d'accès une
%   fois leur propre premier accès résolu.
    for k = 1:numel(s)
        switch s(k).type
            case '()'
                indices = s(k).subs;
                v = v(indices{:});
            case '{}'
                indices = s(k).subs;
                v = v{indices{:}};
            case '.'
                v = v.(s(k).subs);
        end
    end
end
