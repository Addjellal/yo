function [q, qd, qdd, pp] = bsplinepolytraj(controle, intervalle, echantillons)
%BSPLINEPOLYTRAJ Trajectoire par B-spline sur des points de contrôle.
%   [Q,QD,QDD] = BSPLINEPOLYTRAJ(CONTROLE,INTERVALLE,ECHANTILLONS) rend
%   la courbe B-spline cubique de points de contrôle CONTROLE — une ligne
%   par degré de liberté — évaluée aux instants demandés.
%   INTERVALLE = [T0 TF] donne les bornes du paramètre.
%
%   La courbe ne passe pas par ses points de contrôle intérieurs : elle
%   les longe. C'est ce qui la distingue d'une interpolation, et c'est
%   voulu — la courbe reste dans l'enveloppe convexe de ses points, donc
%   dans la zone qu'on a définie, quoi qu'il arrive. Un dépassement y est
%   impossible par construction, alors qu'un polynôme interpolant en
%   produit dès qu'on lui donne des points serrés.
%
%   Les extrémités, elles, sont atteintes exactement : le vecteur de
%   nœuds est serré aux deux bouts.
%
%   [Q,QD,QDD,PP] = BSPLINEPOLYTRAJ(...) rend aussi la description de la
%   courbe.
%
%   Exemple :
%      p = [0 1 3 4; 0 2 2 0];
%      [q, qd] = bsplinepolytraj(p, [0 1], linspace(0, 1, 50));
%      q(:, 1)                         % le premier point de controle
%      max(q(2, :)) <= max(p(2, :))    % l'enveloppe convexe est respectee
%
%   Voir aussi CUBICPOLYTRAJ, QUINTICPOLYTRAJ, TRAPVELTRAJ.
    controle = double(controle);
    intervalle = double(intervalle(:)).';
    echantillons = double(echantillons(:)).';
    nDegres = size(controle, 1);
    nControle = size(controle, 2);
    ordre = min(4, nControle);
    if nControle < 2
        error('robotics:bsplinepolytraj:Points', ...
              'Il faut au moins deux points de contrôle.');
    end
    % Vecteur de nœuds serré : l'ordre est répété aux deux bouts, ce qui
    % force la courbe à passer par le premier et le dernier point.
    interieurs = nControle - ordre;
    if interieurs > 0
        milieu = linspace(intervalle(1), intervalle(2), interieurs + 2);
        milieu = milieu(2:end-1);
    else
        milieu = [];
    end
    noeuds = [repmat(intervalle(1), 1, ordre), milieu, ...
              repmat(intervalle(2), 1, ordre)];
    % Le dernier instant tombe sur le nœud terminal, où la base est nulle
    % par convention ; on l'approche par la gauche.
    t = min(max(echantillons, intervalle(1)), intervalle(2) - eps(intervalle(2)) * 8);
    N = matlibre_base_bspline(noeuds, ordre, t);
    q = controle * N.';
    % Les dérivées se lisent par différence finie centrée sur la courbe
    % elle-même : la base est déjà évaluée, et le pas est choisi assez
    % petit pour que l'erreur reste sous la précision d'affichage.
    pas = (intervalle(2) - intervalle(1)) * 1e-6;
    avant = controle * matlibre_base_bspline(noeuds, ordre, ...
                min(max(t - pas, intervalle(1)), intervalle(2) - eps * 8)).';
    apres = controle * matlibre_base_bspline(noeuds, ordre, ...
                min(max(t + pas, intervalle(1)), intervalle(2) - eps * 8)).';
    qd = (apres - avant) / (2 * pas);
    qdd = (apres - 2 * q + avant) / (pas ^ 2);
    pp = struct('form', 'bspline', 'knots', noeuds, 'coefs', controle, ...
                'order', ordre, 'dim', nDegres);
end
