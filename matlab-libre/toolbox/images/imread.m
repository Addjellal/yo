function x = imread(nomFichier)
%IMREAD Lit une image aux formats PGM/PPM en texte (P2 et P3).
    texte = fileread(nomFichier);
    jetons = strsplit(strtrim(regexprep(texte, '#[^\n]*', ' ')));
    valeurs = [];
    for k = 1:numel(jetons)
        j = strtrim(jetons{k});
        if isempty(j)
            continue;
        end
        valeurs(end+1) = str2double(j);
    end
    entete = jetons{1};
    l = valeurs(2);
    h = valeurs(3);
    maxi = valeurs(4);
    donnees = valeurs(5:end);
    if strcmp(entete, 'P3')
        x = zeros(h, l, 3);
        indice = 1;
        for i = 1:h
            for j = 1:l
                x(i,j,1) = donnees(indice) / maxi;
                x(i,j,2) = donnees(indice+1) / maxi;
                x(i,j,3) = donnees(indice+2) / maxi;
                indice = indice + 3;
            end
        end
    else
        x = zeros(h, l);
        indice = 1;
        for i = 1:h
            for j = 1:l
                x(i,j) = donnees(indice) / maxi;
                indice = indice + 1;
            end
        end
    end
end
