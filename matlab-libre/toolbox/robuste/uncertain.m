function b = uncertain(objet)
%UNCERTAIN L'objet porte-t-il de l'incertitude ?
%   B = UNCERTAIN(U) rend vrai si U dépend d'au moins un paramètre
%   incertain, faux sinon. Un UMAT ou un USS bâti sur des nombres
%   ordinaires est certain, quoique de classe incertaine : c'est ce que
%   cette fonction permet de distinguer.
%
%   Exemples :
%      k = ureal('k', 4);
%      uncertain(k)                       % vrai
%      uncertain(umat([1 2; 3 4]))        % faux
%      uncertain(ss(-1, 1, 1, 0))         % faux
%
%   Voir aussi UREAL, UMAT, USS, GETNOMINAL, USUBS.
    parametres = matlibre_incertitudes(objet);
    b = ~isempty(parametres);
end
