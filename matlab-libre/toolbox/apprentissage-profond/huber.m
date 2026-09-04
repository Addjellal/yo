function perte = huber(predit, cible, varargin)
%HUBER Perte quadratique près de zéro, linéaire au loin.
%   P = HUBER(Y,T) vaut la moitié du carré de l'écart tant que celui-ci
%   reste sous le point de transition, et devient linéaire au-delà, en se
%   raccordant sans rupture de pente.
%
%   Elle joint les deux qualités : la courbure de la perte quadratique
%   près de la solution, qui fait converger vite, et la robustesse de la
%   perte absolue au loin, qui empêche une observation aberrante de tout
%   emporter.
%
%   Options et valeurs par défaut :
%     'TransitionPoint'       1, le seuil de passage
%     'Reduction'             'sum', ou 'none'
%     'NormalizationFactor'   'batch-size', 'all-elements' ou 'none'
%     'DataFormat'            le format, quand Y n'en porte pas
%
%   Exemple :
%      huber(dlarray([0.5 5], 'CB'), [0 0])      % (0.125 + 4.5) / 2
%
%   Voir aussi L1LOSS, L2LOSS, MSE.
    seuil = 1;
    reste = {};
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'transitionpoint')
            seuil = double(varargin{k + 1});
        else
            reste{end + 1} = varargin{k};       %#ok<AGROW>
            reste{end + 1} = varargin{k + 1};   %#ok<AGROW>
        end
        k = k + 2;
    end
    [reduction, facteur, format] = matlibre_dl_options_perte(predit, reste);
    ecart = predit - cible;
    amplitude = abs(ecart);
    % La partie basse est écrite avec un minimum et la haute avec le
    % reste : les deux morceaux se raccordent, et l'expression reste
    % dérivable par la bande.
    basse = min(amplitude, seuil);
    haute = amplitude - basse;
    perte = matlibre_dl_reduire_perte(0.5 * basse .^ 2 + seuil * haute, ...
                                      reduction, facteur, format);
end
