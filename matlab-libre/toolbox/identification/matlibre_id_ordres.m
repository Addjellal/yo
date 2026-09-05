function ordres = matlibre_id_ordres(donnes, defaut)
%MATLIBRE_ID_ORDRES Ordres d'un modèle polynomial, complétés.
%   O = MATLIBRE_ID_ORDRES(DONNES,DEFAUT) rend [na nb nc nd nf nk] en
%   complétant ce qui manque par les valeurs par défaut de la famille.
%
%   Exemple :
%      matlibre_id_ordres([2 2 1], [0 0 0 0 0 1])      % 2 2 1 0 0 1
%
%   Voir aussi POLYEST, ARX, ARMAX, OE, BJ.
    ordres = defaut;
    donnes = round(double(donnes(:)).');
    n = min(numel(donnes), numel(ordres));
    ordres(1:n) = donnes(1:n);
    if numel(donnes) > 0 && numel(donnes) < numel(ordres)
        % Le retard, quand il est donné, l'est en dernier : c'est la
        % convention de MATLAB, où « [na nb nk] » se lit sans ambiguïté.
        ordres(6) = donnes(end);
        if numel(donnes) == numel(defaut)
            ordres(6) = donnes(6);
        end
    end
end
