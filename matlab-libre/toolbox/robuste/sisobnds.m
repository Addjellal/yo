function bornes = sisobnds(genre, G, specification, w)
%SISOBNDS Bornes de robustesse dans le plan du correcteur.
%   B = SISOBNDS(TYPE,G,SPEC,W) rend, pour chaque pulsation de W, la
%   contrainte que le correcteur doit respecter pour tenir la
%   spécification SPEC sur le procédé G. C'est l'outil du réglage
%   quantitatif : on trace ces bornes dans le plan de Nichols, puis on
%   façonne la boucle pour passer au-dessus.
%
%   TYPE choisit la spécification :
%      1  stabilité robuste : |T| sous SPEC ;
%      2  performance : |S| sous SPEC ;
%      3  rejet de perturbation en entrée : |G*S| sous SPEC ;
%      7  suivi de consigne : |T| entre deux bornes.
%
%   B porte, par pulsation, le gain de boucle minimal qui satisfait la
%   contrainte : |L| >= B, ce qui se lit directement sur un diagramme de
%   Bode.
%
%   MatLibre rend la borne sur le module de la boucle ouverte, non le
%   contour complet dans le plan de Nichols que trace la boîte à outils
%   QFT de MATLAB : c'est ce qui suffit à façonner une boucle, et cela ne
%   demande pas le balayage en phase.
%
%   Exemples :
%      G = ss(tf(1, [1 1]));
%      w = logspace(-1, 2, 20);
%      b = sisobnds(2, G, 0.1, w);       % erreur sous 10 %
%      loglog(w, b);                      % le gain de boucle minimal
%
%   Voir aussi LOOPSYN, MIXSYN, MAKEWEIGHT, NICHOLS, LOOPMARGIN.
    if nargin < 4 || isempty(w)
        w = logspace(-2, 2, 50);
    end
    w = w(:)';
    H = freqresp(ss(G), w);
    module = zeros(1, numel(w));
    for k = 1:numel(w)
        if ndims(H) == 3
            module(k) = max(svd(H(:, :, k)));
        else
            module(k) = abs(H(k));
        end
    end
    if isscalar(specification)
        specification = repmat(specification, 1, numel(w));
    else
        specification = specification(:)';
    end
    bornes = zeros(1, numel(w));
    for k = 1:numel(w)
        s = specification(k);
        switch genre
            case 1
                % |T| <= s : |L| <= s/(1-s) quand s < 1, sinon rien.
                if s >= 1
                    bornes(k) = Inf;
                else
                    bornes(k) = s / (1 - s);
                end
            case 2
                % |S| <= s : |L| >= 1/s - 1.
                bornes(k) = max(1 / s - 1, 0);
            case 3
                % |G*S| <= s : |L| >= |G|/s - 1.
                bornes(k) = max(module(k) / s - 1, 0);
            case 7
                % Suivi : |T| >= s, soit |L| >= s/(1-s).
                if s >= 1
                    bornes(k) = Inf;
                else
                    bornes(k) = s / (1 - s);
                end
            otherwise
                error('Robust:sisobnds:BadType', ...
                      'The specification type must be 1, 2, 3 or 7.');
        end
    end
end
