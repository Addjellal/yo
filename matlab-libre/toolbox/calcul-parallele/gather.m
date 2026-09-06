function y = gather(x)
%GATHER Rapatrie un tableau distribué.
%   Y = GATHER(X) ramène un tableau distribué dans l'espace de travail
%   local. Sur une seule machine, c'est l'identité.
%
%   GATHER annule exactement DISTRIBUTED, sur un tableau vide comme sur du
%   texte. C'est le contrat, et il tient quel que soit le contenu.
%
%   Sur un vrai pool, c'est l'appel qui coûte : il rassemble sur une seule
%   machine ce qui était réparti. Le placer dans une boucle est la façon
%   la plus sûre de perdre tout le bénéfice du parallélisme.
%
%   Exemple :
%      gather(distributed([]))         % []
%      gather(distributed('texte'))    % 'texte'
%
%   Voir aussi DISTRIBUTED, PARARRAYFUN.
    y = x;
end
