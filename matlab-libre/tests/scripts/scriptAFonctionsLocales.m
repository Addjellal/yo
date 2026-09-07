% scriptAFonctionsLocales.m — un script qui porte ses propres fonctions.
%
% Depuis R2016b, un script peut definir des fonctions locales apres ses
% instructions. Elles ne sont visibles que de lui : ni l'appelant ni le
% reste de la session ne les voit. Ce fichier sert a verifier que le
% script est bien reconnu comme tel — la presence de fonctions ne le
% transforme pas en fichier de fonction — et que ses locales recoivent
% leurs arguments.
marqueLocale = doubler(21);
marqueChainee = decrire('essai');

function n = doubler(x)
    n = 2 * x;
end

function s = decrire(mot)
    s = [mot ' : ' num2str(longueur(mot))];
end

function n = longueur(mot)
    n = numel(mot);
end
