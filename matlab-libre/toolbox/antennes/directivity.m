function D = directivity(theta, diagramme)
%DIRECTIVITY Directivité estimée à partir d'un diagramme en puissance.
%   D = DIRECTIVITY(THETA,DIAGRAMME) rend le rapport entre l'intensité
%   maximale et l'intensité moyenne sur toute la sphère, en supposant le
%   diagramme de révolution autour de l'axe polaire.
%
%   Une antenne ne crée pas de puissance : elle la répartit. La
%   directivité mesure exactement cela — combien de fois plus de puissance
%   part dans la meilleure direction que si tout était rayonné
%   uniformément. Une antenne isotrope a donc une directivité de un, par
%   définition, et c'est à elle que le « i » de dBi renvoie.
%
%   Le calcul intègre en sin(theta) d theta : c'est l'élément d'angle
%   solide, et l'oublier fausse tout.
%
%   Exemple :
%      theta = linspace(1e-6, pi - 1e-6, 20001);
%      directivity(theta, ones(size(theta)))       % 1 : isotrope
%      directivity(theta, dipolePattern(theta, 0.5))   % 1.64
%
%   Voir aussi BEAMWIDTH, DIPOLEPATTERN, FRIIS.
    U = diagramme .^ 2;
    integrale = trapz(theta, U .* sin(theta)) * 2 * pi;
    D = 4 * pi * max(U) / integrale;
end
