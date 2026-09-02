function [pires, valeurs, info] = wcsens(G, K, options)
%WCSENS Pires sensibilités d'une boucle incertaine.
%   [S,V] = WCSENS(G,K) cherche, dans le domaine des paramètres, ce qui
%   dégrade le plus chacune des sensibilités de la boucle formée du
%   procédé incertain G et du correcteur K. S porte un champ par
%   transmittance — So, Si, To, Ti, PSi, CSo —, chacun donnant le pire
%   pic et les valeurs de paramètres qui le donnent, plus un champ
%   Stable qui dit si la boucle tient sur tout le domaine.
%
%   C'est le tableau de bord de la robustesse : un pic de sensibilité qui
%   double sur le domaine des paramètres se voit d'un coup d'œil, et l'on
%   sait quel paramètre le cause.
%
%   [S,V,INFO] = WCSENS(G,K) rend en outre les pics nominaux, pour
%   comparer.
%
%   La recherche est celle de WCGAIN ; voir cette fonction pour ce
%   qu'elle garantit.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
%      C = ss(tf([10 10], [1 0]));
%      s = wcsens(G, C);
%      s.So.PeakGain
%      s.Stable
%
%   Voir aussi WCGAIN, ROBSTAB, LOOPSENS, WCDISKMARGIN, USS.
    if nargin < 3
        options = struct();
    end
    [parametres, evaluer] = matlibre_incertitudes(G);
    Kss = ss(K);
    noms = {'So', 'Si', 'To', 'Ti', 'PSi', 'CSo'};
    pires = struct();
    valeurs = struct();
    info = struct();
    for k = 1:numel(noms)
        nom = noms{k};
        cout = @(v) matlibre_pic_sensibilite(evaluer(v), Kss, nom);
        [pic, ou] = matlibre_balayer_incertitude(parametres, cout, options);
        pires.(nom) = struct('PeakGain', pic, 'Values', ou);
        valeurs.(nom) = ou;
        boucleNominale = loopsens(ss(evaluer(umat.valeursNominales(parametres))), Kss);
        info.(nom) = hinfnorm(boucleNominale.(nom));
    end
    % La stabilite sur tout le domaine.
    coutStable = @(v) matlibre_pire_pole(feedback(ss(evaluer(v)) * Kss, ...
                                                  ss(eye(size(ss(evaluer(v)), 1)))));
    pireePole = matlibre_balayer_incertitude(parametres, coutStable, options);
    pires.Stable = pireePole < 0;
end
