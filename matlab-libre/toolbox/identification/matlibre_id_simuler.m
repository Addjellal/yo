function sortie = matlibre_id_simuler(modele, entree, arguments)
%MATLIBRE_ID_SIMULER Simule la réponse d'un modèle polynomial.
%   Z = MATLIBRE_ID_SIMULER(MODELE,ENTREE,ARGUMENTS) applique le modèle à
%   l'entrée donnée — un IDDATA ou une matrice — et rend un IDDATA
%   portant la sortie simulée.
%
%   La sortie est y = (B/(A F)) u, à quoi s'ajoute (C/(A D)) e si un bruit
%   est fourni en argument.
%
%   Exemple :
%      m = idpoly([1 -0.8], [0 0.2], 1, 1, 1, 0, 0.1);
%      z = sim(m, iddata([], ones(20, 1), 0.1));
%
%   Voir aussi PREDICT, COMPARE, IDPOLY.
    if isa(entree, 'iddata')
        u = entree.InputData;
        periode = entree.Ts;
        modeleJeu = entree;
    else
        u = double(entree);
        if isvector(u)
            u = u(:);
        end
        periode = modele.Ts;
        modeleJeu = [];
    end
    bruit = [];
    for k = 1:numel(arguments)
        if isnumeric(arguments{k}) && ~isempty(arguments{k})
            bruit = double(arguments{k}(:));
        end
    end
    if isempty(u)
        n = numel(bruit);
        deterministe = zeros(n, 1);
    else
        deterministe = filter(modele.B, conv(modele.A, modele.F), u);
    end
    y = deterministe;
    if ~isempty(bruit)
        y = y + filter(modele.C, conv(modele.A, modele.D), bruit);
    end
    if isempty(modeleJeu)
        sortie = iddata(y, u, periode);
    else
        sortie = modeleJeu;
        sortie.OutputData = y;
    end
end
