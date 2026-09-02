function [echantillons, valeurs] = usample(objet, nombre)
%USAMPLE Tire au hasard des valeurs des paramètres incertains.
%   [S,V] = USAMPLE(U) tire une valeur de chaque paramètre, uniformément
%   dans son intervalle, et rend l'objet obtenu ainsi que la structure
%   des valeurs tirées.
%
%   [S,V] = USAMPLE(U,N) fait N tirages. S est alors un tableau de
%   cellules de N objets, V un tableau de structures de N éléments.
%
%   C'est le moyen le plus direct de voir ce que l'incertitude fait : on
%   trace vingt réponses tirées au hasard, et l'on voit d'un coup si le
%   nuage reste acceptable.
%
%   Un paramètre complexe — UCOMPLEX — est tiré uniformément dans son
%   disque ; un bloc dynamique — ULTIDYN — est tiré comme un modèle du
%   premier ordre de gain au plus égal à sa borne.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
%      [modeles, tirages] = usample(G, 20);
%      hold on
%      for j = 1:20, bode(modeles{j}); end
%      hold off
%
%      usample(k, 5)
%
%   Voir aussi USUBS, GETNOMINAL, WCGAIN, ROBSTAB, UREAL, USS.
    if nargin < 2 || isempty(nombre)
        nombre = 1;
    end
    [parametres, evaluer] = matlibre_incertitudes(objet);
    tirages = cell(1, nombre);
    modeles = cell(1, nombre);
    for j = 1:nombre
        v = struct();
        for k = 1:numel(parametres)
            v.(parametres{k}.Name) = matlibre_tirer_atome(parametres{k});
        end
        tirages{j} = v;
        modeles{j} = evaluer(v);
    end
    if nombre == 1
        echantillons = modeles{1};
        valeurs = tirages{1};
        return
    end
    echantillons = modeles;
    valeurs = tirages;
end
