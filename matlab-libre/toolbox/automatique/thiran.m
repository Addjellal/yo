function sys = thiran(retard, Ts)
%THIRAN Filtre passe-tout à retard fractionnaire.
%   SYS = THIRAN(RETARD,TS) approche un retard de RETARD secondes par un
%   filtre numérique passe-tout de période d'échantillonnage TS. Le
%   retard n'a pas à être un multiple de TS : la partie fractionnaire est
%   rendue par un passe-tout dont le retard de groupe est maximalement
%   plat en zéro, ce qui est la construction de Thiran.
%
%   Un passe-tout ne change aucun module : seule la phase bouge, comme
%   pour un vrai retard. C'est ce qui le distingue d'une approximation
%   par troncature, qui déforme la réponse.
%
%   Les coefficients viennent de la formule de Thiran :
%
%      a(k) = (-1)^k C(N,k) prod_{i=0..N} (D - N + i) / (D - N + k + i)
%
%   où D est le retard en périodes et N l'ordre du filtre.
%
%   Exemple :
%      sys = thiran(0.25, 0.1);         % 2,5 périodes
%      [~, ~, ~] = zpkdata(sys);
%
%   Voir aussi PADE, C2D, D2D, DELAYSS, ABSORBDELAY.
    if nargin < 2 || isempty(Ts)
        error('control:thiran:Ts', 'THIRAN demande la période d''échantillonnage.');
    end
    if Ts <= 0
        error('control:thiran:Ts', 'La période d''échantillonnage doit être positive.');
    end
    D = retard / Ts;
    if D < 0
        error('control:thiran:Retard', 'Le retard doit être positif.');
    end
    % Un retard entier est un simple décalage : rien à approcher. Le
    % quotient de deux flottants tombe rarement juste — 0,3/0,1 vaut
    % 2,9999999999999996 —, d'où la tolérance.
    entier = round(D);
    fraction = abs(D - entier);
    if fraction < 1e-9
        num = [zeros(1, entier), 1];
        sys = tf(num, 1, Ts);
        return;
    end
    % L'ordre suit la partie fractionnaire : le passe-tout de Thiran
    % veut un retard total compris entre N-1 et N.
    N = max(1, ceil(D));
    a = zeros(1, N + 1);
    for k = 0:N
        terme = (-1) ^ k * nchoosek(N, k);
        for i = 0:N
            terme = terme * (D - N + i) / (D - N + k + i);
        end
        a(k + 1) = terme;
    end
    % Le numérateur d'un passe-tout est le dénominateur retourné.
    num = a(end:-1:1);
    sys = tf(num, a, Ts);
end
