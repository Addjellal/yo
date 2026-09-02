function sys = randuss(ordre, sorties, entrees, nombreAtomes)
%RANDUSS Modèle d'état incertain tiré au hasard.
%   SYS = RANDUSS(N) crée un modèle incertain stable d'ordre N, à une
%   entrée et une sortie.
%   SYS = RANDUSS(N,P,M) lui donne P sorties et M entrées.
%   SYS = RANDUSS(N,P,M,Q) emploie Q paramètres incertains ; un par
%   défaut.
%
%   Le modèle nominal est celui que rend RSS : stable, d'ordre N.
%   L'incertitude porte sur la matrice d'état, ce qui déplace les pôles
%   sans changer la structure.
%
%   Exemples :
%      G = randuss(3);
%      pole(getNominal(G))'
%      robstab(G)
%      usample(G, 5);
%
%   Voir aussi RANDATOM, RANDUMAT, RSS, USS, ROBSTAB, WCGAIN.
    if nargin < 1 || isempty(ordre)
        ordre = 2;
    end
    if nargin < 2 || isempty(sorties)
        sorties = 1;
    end
    if nargin < 3 || isempty(entrees)
        entrees = 1;
    end
    if nargin < 4 || isempty(nombreAtomes)
        nombreAtomes = 1;
    end
    base = ss(rss(ordre, sorties, entrees));
    A = umat(base.A);
    for k = 1:nombreAtomes
        atome = ureal(sprintf('d%d', k), 0, 'Range', [-0.2 0.2]);
        A = A + atome * randn(ordre, ordre) * 0.2;
    end
    sys = uss(A, base.B, base.C, base.D, base.Ts);
end
