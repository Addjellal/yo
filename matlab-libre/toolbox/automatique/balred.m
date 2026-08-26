function [sysr, g] = balred(sys, ordre, methode)
%BALRED Réduction d'ordre par troncature équilibrée.
%   SYSR = BALRED(SYS,N) équilibre le modèle puis élimine les états dont
%   la valeur singulière de Hankel est la plus faible, jusqu'à n'en
%   garder que N. Le gain statique est conservé.
%
%   SYSR = BALRED(SYS,N,'del') tronque au lieu de résiduer.
%   [SYSR,G] = BALRED(...) rend aussi les valeurs singulières de Hankel du
%   modèle de départ : l'erreur de réduction est bornée par le double de
%   leur somme au-delà du rang N.
%
%   Exemple :
%      g = ss([-1 0; 0 -100], [1; 1], [1 1], 0);
%      r = balred(g, 1);
%      abs(dcgain(r) - dcgain(g)) < 1e-10   % vrai
%
%   Voir aussi BALREAL, MODRED, HSVD.
    if nargin < 3 || isempty(methode), methode = 'mdc'; end
    [sysb, g] = balreal(sys);
    n = numel(g);
    ordre = round(double(ordre));
    if ordre >= n
        sysr = sysb;
        return
    end
    if ordre < 0
        error('control:balred:BadOrder', 'L''ordre demandé doit être positif.');
    end
    sysr = modred(sysb, (ordre + 1):n, methode);
end
