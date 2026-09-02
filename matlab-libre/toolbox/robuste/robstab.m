function [rapport, pire, info] = robstab(sys, options)
%ROBSTAB Marge de stabilité robuste d'un modèle incertain.
%   [R,V] = ROBSTAB(SYS) cherche de combien on peut dilater le domaine
%   des paramètres avant que SYS cesse d'être stable. R porte :
%      LowerBound   le rayon de robustesse trouvé ;
%      UpperBound   le même ;
%      DestabilizingFrequency  la pulsation du mode qui devient instable.
%   V est la structure des valeurs de paramètres qui déstabilisent, quand
%   il y en a.
%
%   Un rayon supérieur à un veut dire que le modèle reste stable sur tout
%   le domaine déclaré, avec de la marge : R = 2.3 dit qu'il faudrait
%   2.3 fois l'écart déclaré pour le mettre en défaut. Un rayon inférieur
%   à un dit qu'une combinaison du domaine déstabilise déjà.
%
%   [R,V,INFO] = ROBSTAB(SYS) rend en outre le pire pôle rencontré.
%
%   Le rayon est cherché par dichotomie : à chaque essai, on dilate le
%   pavé des paramètres et l'on cherche, par la méthode de WCGAIN, s'il
%   contient un point instable. Voir WCGAIN pour ce que cette recherche
%   garantit.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      z = ureal('z', 0.2, 'Range', [0.05 0.4]);
%      G = uss([0 1; -k -z], [0; 1], [1 0], 0);
%      r = robstab(G);
%      r.LowerBound                   % grand : rien ne destabilise
%
%      % Un amortissement qui peut devenir negatif
%      z2 = ureal('z', 0.2, 'Range', [-0.1 0.5]);
%      robstab(uss([0 1; -4 -z2], [0; 1], [1 0], 0))
%
%   Voir aussi WCGAIN, ROBGAIN, USAMPLE, MUSSV, LOOPMARGIN, USS.
    if nargin < 2
        options = struct();
    end
    [parametres, evaluer] = matlibre_incertitudes(sys);
    if isempty(parametres)
        modele = ss(evaluer(struct()));
        stable = matlibre_pire_pole(modele) < 0;
        if stable
            rapport = struct('LowerBound', Inf, 'UpperBound', Inf, ...
                             'DestabilizingFrequency', NaN);
        else
            rapport = struct('LowerBound', 0, 'UpperBound', 0, ...
                             'DestabilizingFrequency', NaN);
        end
        pire = struct();
        info = struct('WorstPole', matlibre_pire_pole(modele));
        return
    end

    % Le pire pole sur le pave dilate d'un rayon donne.
    pirePoleAuRayon = @(rayon) matlibre_pire_pole_sur_pave(parametres, evaluer, ...
                                                           rayon, options);
    [poleUn, valeursUn] = pirePoleAuRayon(1);
    if poleUn >= 0
        % Deja instable dans le domaine declare : on cherche a partir de
        % quelle fraction du domaine cela arrive.
        bas = 0;
        haut = 1;
    else
        % Stable : on dilate jusqu'a trouver l'instabilite.
        bas = 1;
        haut = 1;
        for k = 1:20
            haut = haut * 2;
            if pirePoleAuRayon(haut) >= 0
                break
            end
            bas = haut;
        end
        if pirePoleAuRayon(haut) < 0
            rapport = struct('LowerBound', Inf, 'UpperBound', Inf, ...
                             'DestabilizingFrequency', NaN);
            pire = struct();
            info = struct('WorstPole', poleUn, 'Values', valeursUn);
            return
        end
    end
    valeursPires = valeursUn;
    for iteration = 1:40
        milieu = (bas + haut) / 2;
        [p, v] = pirePoleAuRayon(milieu);
        if p >= 0
            haut = milieu;
            valeursPires = v;
        else
            bas = milieu;
        end
        if haut - bas < 1e-6 * max(1, haut)
            break
        end
    end
    rayon = (bas + haut) / 2;
    modelePire = ss(evaluer(valeursPires));
    poles = pole(modelePire);
    [~, rang] = max(real(poles));
    if isempty(rang)
        pulsation = NaN;
    else
        pulsation = abs(imag(poles(rang)));
    end
    rapport = struct('LowerBound', rayon, 'UpperBound', rayon, ...
                     'DestabilizingFrequency', pulsation);
    pire = valeursPires;
    info = struct('WorstPole', max(real(poles)), 'Values', valeursPires);
end
