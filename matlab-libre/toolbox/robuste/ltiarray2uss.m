function [sys, info] = ltiarray2uss(nominal, modeles, ordre)
%LTIARRAY2USS Fait un modèle incertain d'une famille de modèles mesurés.
%   [SYS,INFO] = LTIARRAY2USS(G0,MODELES) construit un modèle incertain
%   qui couvre tous les modèles de la cellule MODELES, autour du modèle
%   nominal G0 :
%
%      SYS = G0 * (1 + W * delta)
%
%   où delta est un bloc dynamique de norme au plus un et W une
%   pondération dont le module majore, à chaque fréquence, l'erreur
%   relative de tous les modèles.
%
%   [SYS,INFO] = LTIARRAY2USS(G0,MODELES,N) donne à W l'ordre N ; le
%   défaut est deux.
%
%   INFO porte W, la pondération trouvée, et Bound, l'erreur relative
%   mesurée à chaque fréquence.
%
%   C'est ainsi qu'on passe de mesures à un modèle incertain : on
%   identifie plusieurs modèles dans plusieurs conditions, on en choisit
%   un pour nominal, et cette fonction dit ce que l'incertitude doit
%   couvrir.
%
%   Exemples :
%      G0 = ss(tf(1, [1 1]));
%      famille = {ss(tf(1, [1 0.8])), ss(tf(1.2, [1 1.3])), ss(tf(0.9, [1 1]))};
%      [Gi, info] = ltiarray2uss(G0, famille);
%      bodemag(info.W);
%
%   Voir aussi ULTIDYN, MAKEWEIGHT, USS, WCGAIN, UCOMPLEX.
    if nargin < 3 || isempty(ordre)
        ordre = 2;
    end
    G0 = ss(nominal);
    w = logspace(-3, 3, 200);
    H0 = freqresp(G0, w);
    erreur_ = zeros(1, numel(w));
    for k = 1:numel(modeles)
        H = freqresp(ss(modeles{k}), w);
        for j = 1:numel(w)
            if abs(H0(j)) > 0
                relative = abs(H(j) - H0(j)) / abs(H0(j));
            else
                relative = abs(H(j) - H0(j));
            end
            erreur_(j) = max(erreur_(j), relative);
        end
    end
    % Une ponderation du premier ordre qui majore l'erreur : on prend le
    % gain basse frequence, le gain haute frequence et le croisement
    % mesures sur la courbe.
    gainBas = max(erreur_(1), 1e-4);
    gainHaut = max(erreur_(end), gainBas * 1.01);
    [~, rang] = min(abs(erreur_ - sqrt(gainBas * gainHaut)));
    croisement = w(rang);
    W = makeweight(gainBas, [croisement, sqrt(gainBas * gainHaut)], gainHaut);
    % On verifie qu'elle majore ; sinon on la releve.
    Hw = freqresp(ss(W), w);
    facteur = max(erreur_ ./ max(abs(Hw(:))', eps));
    if facteur > 1
        W = W * facteur * 1.05;
    end
    delta = ultidyn('deltaLti', [1 1], 'Bound', 1);
    sys = (delta * ss(W) + 1) * G0;
    info = struct('W', W, 'Bound', erreur_, 'Frequency', w);
end
