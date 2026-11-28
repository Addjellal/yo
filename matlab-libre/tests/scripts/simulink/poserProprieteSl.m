% Poser une propriété d'un objet — une affectation, qu'une fonction
% anonyme ne peut pas écrire.
function objet = poserProprieteSl(objet, nom, valeur)
    objet.(nom) = valeur;
end
