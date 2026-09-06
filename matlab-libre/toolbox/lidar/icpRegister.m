function [R, t, erreur] = icpRegister(source, cible, iterations)
%ICPREGISTER Recalage rigide 2-D par ICP.
%   [R,T,ERREUR] = ICPREGISTER(SOURCE,CIBLE,ITERATIONS) cherche la
%   rotation R et la translation T qui superposent au mieux le nuage
%   SOURCE sur le nuage CIBLE. ERREUR est la distance moyenne finale entre
%   points appariés.
%
%   L'algorithme alterne deux étapes jusqu'à convergence : apparier chaque
%   point de la source à son plus proche voisin dans la cible, puis
%   calculer la transformation rigide optimale pour ces appariements — par
%   décomposition en valeurs singulières, qui la donne en forme fermée.
%   Chaque étape diminue l'erreur, donc l'algorithme converge ; mais rien
%   ne garantit qu'il converge vers le bon minimum.
%
%   Il lui faut donc une pose initiale pas trop fausse : ICP part de
%   l'identité, et un écart de plus de quelques dizaines de degrés le fait
%   tomber dans un minimum local. C'est sa limite connue.
%
%   Il ne peut pas non plus lever une ambiguïté que la géométrie ne
%   contient pas : sur un cercle parfait, invariant par rotation, il
%   superpose parfaitement les deux nuages en rendant une rotation
%   quelconque — parce que la question n'a pas de réponse.
%
%   La transformation rendue est toujours rigide : R'R vaut l'identité et
%   son déterminant vaut un, sans symétrie ni changement d'échelle.
%
%   Exemple :
%      forme = [cos(0:0.1:2*pi).', sin(0:0.1:2*pi).'] .* [2 1];
%      a = deg2rad(12);
%      Rv = [cos(a) -sin(a); sin(a) cos(a)];
%      [R, t] = icpRegister(forme, (Rv * forme.').' + [0.4 -0.25], 60);
%      rad2deg(atan2(R(2,1), R(1,1)))  % 12
%
%   Voir aussi FITPLANERANSAC, VOXELDOWNSAMPLE, POINTCLOUDFROMRANGES.
    if nargin < 3
        iterations = 30;
    end
    R = eye(2);
    t = [0 0];
    courant = source;
    erreur = inf;
    for k = 1:iterations
        indices = zeros(size(courant, 1), 1);
        for i = 1:size(courant, 1)
            d = sum((cible - repmat(courant(i, :), size(cible, 1), 1)) .^ 2, 2);
            [~, indices(i)] = min(d);
        end
        appariee = cible(indices, :);
        cs = mean(courant, 1);
        cc = mean(appariee, 1);
        H = (courant - repmat(cs, size(courant,1), 1)).' * ...
            (appariee - repmat(cc, size(appariee,1), 1));
        [U, ~, V] = svd(H);
        Rk = V * U.';
        tk = cc.' - Rk * cs.';
        courant = (Rk * courant.' + repmat(tk, 1, size(courant,1))).';
        R = Rk * R;
        t = (Rk * t.' + tk).';
        erreur = mean(sqrt(sum((courant - appariee) .^ 2, 2)));
    end
end
