function [a, b, c, d] = dlinmod(modele, Ts, x, u, para)
%DLINMOD Linéarise un modèle et l'échantillonne à la période TS.
%   [A,B,C,D] = DLINMOD(MODELE,TS) linéarise le modèle comme LINMOD, puis
%   discrétise le résultat par bloqueur d'ordre zéro : l'entrée est tenue
%   constante entre deux instants d'échantillonnage.
%   [A,B,C,D] = DLINMOD(MODELE,TS,X,U) choisit le point de
%   fonctionnement ; PARA joue le même rôle que dans LINMOD.
%   SYS = DLINMOD(...) rend la structure à champs a, b, c, d.
%
%   La discrétisation est exacte, non approchée : Ad et Bd sortent d'une
%   seule exponentielle de matrice, celle de [A B ; 0 0]*TS, dont le bloc
%   supérieur droit vaut l'intégrale de exp(A t) B — ce qui évite d'avoir
%   à inverser A, qui est souvent singulière.
%
%   TS nul rend la linéarisation continue elle-même, comme dans MATLAB.
%
%   Exemple :
%      m = new_system('premier');
%      m = add_block(m, 'inport', 'u', 'Port', 1);
%      m = add_block(m, 'sum', 's', 'Signs', '+-');
%      m = add_block(m, 'integrator', 'x');
%      m = add_block(m, 'outport', 'y', 'Port', 1);
%      m = add_line(m, 'u', 's', 1);
%      m = add_line(m, 'x', 's', 2);
%      m = add_line(m, 's', 'x');
%      m = add_line(m, 'x', 'y');
%      [Ad, Bd] = dlinmod(m, 0.5);
%      abs(Ad - exp(-0.5)) < 1e-12          % le pole continu -1
%
%   Voir aussi LINMOD, TRIM, C2D, SIM.
    if nargin < 3, x = []; end
    if nargin < 4, u = []; end
    if nargin < 5, para = []; end
    [ac, bc, cc, dc] = linmod(modele, x, u, para);
    if isempty(Ts) || Ts == 0
        [a, b, c, d] = rendre(ac, bc, cc, dc, nargout);
        return
    end
    if ~isscalar(Ts) || Ts < 0
        error('Simulink:Commands:DlinmodPeriode', ...
              'La periode d''echantillonnage doit etre un nombre positif.');
    end
    n = size(ac, 1);
    m = size(bc, 2);
    if n == 0
        [a, b, c, d] = rendre(ac, bc, cc, dc, nargout);
        return
    end
    bloc = [ac, bc; zeros(m, n + m)] * Ts;
    exponentielle = expm(bloc);
    ad = exponentielle(1:n, 1:n);
    bd = exponentielle(1:n, n+1:n+m);
    [a, b, c, d] = rendre(ad, bd, cc, dc, nargout);
end

function [a, b, c, d] = rendre(ad, bd, cd, dd, combien)
    if combien <= 1
        systeme = struct('a', ad, 'b', bd, 'c', cd, 'd', dd);
        a = systeme;
        b = [];
        c = [];
        d = [];
        return
    end
    a = ad;
    b = bd;
    c = cd;
    d = dd;
end
