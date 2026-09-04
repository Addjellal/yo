function [prix, tauxEchange, prixFixe, prixVariable] = swapbyzero(courbe, tauxBranches, reglement, echeance, frequences, base, nominal, regleFinMois)
%SWAPBYZERO Prix d'un échange de taux, sur une courbe zéro-coupon.
%   [P,T] = SWAPBYZERO(COURBE,[TAUXFIXE ECART],REGLEMENT,ECHEANCE) rend
%   la valeur de l'échange pour le payeur de taux variable — la branche
%   fixe reçue moins la branche variable payée — et le taux d'échange qui
%   annulerait cette valeur.
%
%   Ce taux d'échange est le taux fixe du marché : celui pour lequel
%   personne ne paie rien à l'entrée. Il se lit directement sur la
%   courbe, comme la valeur de la branche variable divisée par la somme
%   des facteurs d'actualisation pondérés.
%
%   FREQUENCES vaut [fixe variable], 1 et 1 par défaut.
%
%   Exemple :
%      [p, t] = swapbyzero(courbe, [0.04 0], '01-Jan-2024', '01-Jan-2029')
%
%   Voir aussi FIXEDBYZERO, FLOATBYZERO, BONDBYZERO.
    if nargin < 5 || isempty(frequences),   frequences = [1 1]; end
    if nargin < 6 || isempty(base),         base = courbe.Basis; end
    if nargin < 7 || isempty(nominal),      nominal = 100;    end
    if nargin < 8 || isempty(regleFinMois), regleFinMois = 1; end
    if isscalar(frequences)
        frequences = [frequences frequences];
    end
    tauxBranches = double(tauxBranches);
    if isscalar(tauxBranches)
        tauxBranches = [tauxBranches 0];
    end
    tauxFixe = tauxBranches(1);
    ecart = tauxBranches(2);
    prixFixe = fixedbyzero(courbe, tauxFixe, reglement, echeance, frequences(1), ...
                           base, nominal, regleFinMois);
    prixVariable = floatbyzero(courbe, ecart, reglement, echeance, frequences(2), ...
                               base, nominal, regleFinMois);
    prix = prixFixe - prixVariable;
    % Le taux d'échange annule la valeur : il vaut la branche variable
    % divisée par la valeur d'un point de base fixe.
    unite = fixedbyzero(courbe, 1, reglement, echeance, frequences(1), ...
                        base, nominal, regleFinMois);
    tauxEchange = prixVariable / unite;
end
