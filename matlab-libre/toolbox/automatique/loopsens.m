function s = loopsens(G, K)
%LOOPSENS Toutes les fonctions de sensibilité d'une boucle.
%   S = LOOPSENS(G,K) rend, dans une structure, les six transmittances
%   d'une boucle à retour unitaire où G est le procédé et K le correcteur :
%
%      S.Si   sensibilité en entrée,      inv(I + K*G)
%      S.Ti   complémentaire en entrée,   I - Si
%      S.So   sensibilité en sortie,      inv(I + G*K)
%      S.To   complémentaire en sortie,   I - So
%      S.PSi  procédé fois sensibilité,   G*Si
%      S.CSo  correcteur fois sensibilité, K*So
%      S.Lo   boucle ouverte en sortie,   G*K
%      S.Li   boucle ouverte en entrée,   K*G
%      S.Poles pôles de la boucle fermée
%      S.Stable vrai si la boucle est stable
%
%   Ces six-là sont les seules que l'on ait à regarder : elles disent le
%   rejet des perturbations, le suivi de consigne, l'effort de commande et
%   la robustesse. Les tracer toutes, c'est ce que fait un ingénieur avant
%   de valider un correcteur.
%
%   Exemples :
%      L = loopsens(tf(2, [1 1]), tf(10, [1 0]));
%      L.Stable                         % vrai
%      abs(dcgain(L.So))  < 1e-9        % l'integrateur annule l'erreur
%      abs(dcgain(L.To) - 1) < 1e-9     % et fait suivre la consigne
%
%   Voir aussi FEEDBACK, SIGMA, MARGIN, HINFNORM, STABILITYMARGIN.
    G = ss(G);
    K = ss(K);
    [ny, nu] = size(G);
    s = struct();
    s.Lo = G * K;
    s.Li = K * G;
    s.So = feedback(ss(eye(ny)), s.Lo);
    s.Si = feedback(ss(eye(nu)), s.Li);
    s.To = feedback(s.Lo, ss(eye(ny)));
    s.Ti = feedback(s.Li, ss(eye(nu)));
    % « G * Si » et « K * So » se calculent par FEEDBACK, non par un
    % produit : le produit garde les poles de G et de K en modes caches,
    % et un procede instable rendait donc une PSi instable, alors que la
    % boucle, elle, l'est.
    s.PSi = feedback(G, K);
    s.CSo = feedback(K, G);
    s.Poles = pole(s.So);
    if isempty(s.Poles)
        s.Stable = true;
    else
        s.Stable = max(real(s.Poles)) < 0;
    end
end
