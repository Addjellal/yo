function sortie = complexify(entree, rayon, nom)
%COMPLEXIFY Ajoute une petite incertitude complexe à un paramètre réel.
%   U = COMPLEXIFY(P,R) rend le paramètre P entouré d'une incertitude
%   complexe de rayon R : U = P + R*delta, où delta est complexe de
%   module au plus un.
%
%   U = COMPLEXIFY(P,R,'nom') nomme le bloc complexe ajouté.
%
%   À quoi cela sert : le mu réel est discontinu — une perturbation
%   infinitésimale des données peut faire sauter sa valeur — et l'analyse
%   d'un modèle purement réel est donc numériquement fragile. Ajouter une
%   pincée de complexe régularise le problème, au prix d'un léger
%   pessimisme. C'est le remède classique, et R vaut d'ordinaire quelques
%   centièmes.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      kc = complexify(k, 0.05);
%      usample(kc, 3)
%
%   Voir aussi UREAL, UCOMPLEX, MUSSV, ROBSTAB, WCGAIN.
    if nargin < 2 || isempty(rayon)
        rayon = 0.05;
    end
    base = umat(entree);
    if nargin < 3 || isempty(nom)
        noms = Names(base);
        if isempty(noms)
            nom = 'complexifie';
        else
            nom = [noms{1} 'c'];
        end
    end
    sortie = base + ucomplex(char(nom), 0, 'Radius', rayon);
end
