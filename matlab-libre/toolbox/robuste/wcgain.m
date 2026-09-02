function [pire, valeurs, info] = wcgain(sys, options)
%WCGAIN Pire gain d'un modèle incertain.
%   [G,V] = WCGAIN(SYS) cherche, dans le domaine des paramètres, la
%   combinaison qui donne à SYS la plus grande norme H-infini. G porte
%   trois champs :
%      LowerBound   le pire gain trouvé ;
%      UpperBound   le même, MatLibre ne calculant pas de majorant ;
%      CriticalFrequency  la pulsation où il est atteint.
%   V est la structure des valeurs de paramètres qui le donnent.
%
%   [G,V,INFO] = WCGAIN(SYS) rend en outre le gain nominal et le rapport
%   entre le pire et le nominal — la dégradation que l'incertitude
%   coûte.
%
%   WCGAIN(SYS,OPTIONS) accepte une structure portant Tirages, le nombre
%   de tirages au hasard.
%
%   La recherche essaie tous les sommets du pavé des paramètres, puis des
%   tirages, puis affine par une descente locale. Pour une dépendance
%   monotone — le cas ordinaire —, le pire cas est à un sommet et la
%   valeur rendue est exacte. Sinon, elle minore le pire cas : MatLibre
%   le dit plutôt que d'annoncer une garantie qu'il n'a pas. MATLAB, qui
%   garde la forme LFT, calcule au contraire un majorant par mu.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      z = ureal('z', 0.2, 'Range', [0.05 0.4]);
%      G = uss([0 1; -k -z], [0; 1], [1 0], 0);
%      [g, v] = wcgain(G);
%      g.LowerBound                   % le pire gain
%      v.z                            % 0.05 : le moins amorti
%
%   Voir aussi ROBSTAB, WCNORM, WCSENS, USAMPLE, HINFNORM, USS.
    if nargin < 2
        options = struct();
    end
    [parametres, evaluer] = matlibre_incertitudes(sys);
    cout = @(v) matlibre_gain_ou_zero(evaluer(v));
    [borne, valeurs] = matlibre_balayer_incertitude(parametres, cout, options);
    % La pulsation du pire cas.
    [~, pulsation] = hinfnorm(ss(evaluer(valeurs)));
    pire = struct('LowerBound', borne, 'UpperBound', borne, ...
                  'CriticalFrequency', pulsation);
    nominal = matlibre_gain_ou_zero(evaluer(umat.valeursNominales(parametres)));
    if nominal > 0
        degradation = borne / nominal;
    else
        degradation = Inf;
    end
    info = struct('NominalGain', nominal, 'Degradation', degradation, ...
                  'Sensitivity', struct());
end
