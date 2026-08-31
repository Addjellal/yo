function present = matlibre_contient_variable(texte, nom)
%MATLIBRE_CONTIENT_VARIABLE Vrai si le nom apparaît comme variable seule.
%   Fonction interne : elle n'existe pas dans MATLAB. Elle sert à
%   MATLIBRE_POIGNEE_DEPUIS_TEXTE, qui doit distinguer le « y » de
%   « x + y » de celui de « ylabel ».
    present = false;
    n = numel(nom);
    k = 1;
    while k + n - 1 <= numel(texte)
        if strcmp(texte(k:k + n - 1), nom)
            avantOk = (k == 1) || ~estLettreOuChiffre(texte(k - 1));
            apresOk = (k + n > numel(texte)) || ~estLettreOuChiffre(texte(k + n));
            if avantOk && apresOk
                present = true;
                return;
            end
        end
        k = k + 1;
    end
end

function vrai = estLettreOuChiffre(c)
%ESTLETTREOUCHIFFRE Un caractère qui peut faire partie d'un nom.
    vrai = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || ...
           (c >= '0' && c <= '9') || c == '_';
end
