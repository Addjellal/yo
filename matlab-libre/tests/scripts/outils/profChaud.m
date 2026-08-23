function s = profChaud(n)
%PROFCHAUD Fonction d'essai du profileur : appelle une sous-fonction n fois.
    s = 0;
    for k = 1:n
        s = s + profInterne(k);
    end
end
