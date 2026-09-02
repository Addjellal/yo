function [rapport, pire, info] = robgain(sys, gainMaximal, options)
%ROBGAIN Marge de performance robuste.
%   [R,V] = ROBGAIN(SYS,GMAX) cherche de combien on peut dilater le
%   domaine des paramètres avant que la norme H-infini de SYS ne dépasse
%   GMAX. R porte LowerBound et UpperBound ; V donne les valeurs qui
%   font franchir la borne.
%
%   Là où ROBSTAB demande que la boucle reste stable, ROBGAIN demande
%   qu'elle reste performante : c'est la question qu'on se pose quand la
%   stabilité ne fait pas de doute mais que le gain, lui, peut se
%   dégrader.
%
%   Un rayon supérieur à un dit que la performance tient sur tout le
%   domaine déclaré.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      z = ureal('z', 0.2, 'Range', [0.05 0.4]);
%      G = uss([0 1; -k -z], [0; 1], [1 0], 0);
%      wcgain(G).LowerBound              % le pire gain sur le domaine
%      robgain(G, 15)                    % tient-il sous 15 ?
%
%   Voir aussi ROBSTAB, WCGAIN, WCSENS, MUSSV.
    if nargin < 3
        options = struct();
    end
    [parametres, evaluer] = matlibre_incertitudes(sys);
    if isempty(parametres)
        gain = matlibre_gain_ou_zero(evaluer(struct()));
        if gain <= gainMaximal
            rapport = struct('LowerBound', Inf, 'UpperBound', Inf);
        else
            rapport = struct('LowerBound', 0, 'UpperBound', 0);
        end
        pire = struct();
        info = struct('NominalGain', gain);
        return
    end
    pireGain = @(rayon) matlibre_pire_gain_sur_pave(parametres, evaluer, rayon, options);
    [gainUn, valeursUn] = pireGain(1);
    if gainUn > gainMaximal
        bas = 0;
        haut = 1;
    else
        bas = 1;
        haut = 1;
        for k = 1:20
            haut = haut * 2;
            if pireGain(haut) > gainMaximal
                break
            end
            bas = haut;
        end
        if pireGain(haut) <= gainMaximal
            rapport = struct('LowerBound', Inf, 'UpperBound', Inf);
            pire = struct();
            info = struct('NominalGain', gainUn, 'Values', valeursUn);
            return
        end
    end
    valeursPires = valeursUn;
    for iteration = 1:40
        milieu = (bas + haut) / 2;
        [g, v] = pireGain(milieu);
        if g > gainMaximal
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
    rapport = struct('LowerBound', rayon, 'UpperBound', rayon);
    pire = valeursPires;
    info = struct('NominalGain', gainUn, 'Values', valeursPires);
end
