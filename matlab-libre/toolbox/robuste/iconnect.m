function objet = iconnect(varargin)
%ICONNECT Assemblage d'un schéma par des équations (forme ancienne).
%   M = ICONNECT crée un objet d'assemblage vide. On lui donne ensuite
%   ses entrées, ses sorties et ses équations, puis M.System rend le
%   modèle assemblé.
%
%   Cette forme est celle des versions anciennes de la boîte à outils.
%   MatLibre assemble les schémas par SYSIC — la forme que les scripts de
%   synthèse H-infini emploient, où l'on nomme les blocs et l'on écrit
%   les entrées de chacun — et par CONNECT, qui relie par les noms des
%   voies. Ce sont ces deux-là qu'il faut employer ; ICONNECT existe pour
%   que l'appel ne casse pas, et dit ce qu'il faut faire à la place.
%
%   Exemples :
%      % Ce qu'il faut ecrire a la place : CONNECT relie par les noms
%      G = ss(tf(1, [1 1]));  G.InputName = 'u';  G.OutputName = 'y';
%      K = ss(tf(2, 1));      K.InputName = 'e';  K.OutputName = 'u';
%      S = sumblk('e = r - y');
%      boucle = connect(G, K, S, 'r', 'y');
%      abs(dcgain(boucle) - 2/3) < 1e-9
%
%   Voir aussi SYSIC, CONNECT, SUMBLK, APPEND, ICSIGNAL.
    error('Robust:iconnect:Unsupported', ...
          ['MatLibre assembles block diagrams with SYSIC (named blocks and ' ...
           'their inputs) or CONNECT (named channels), not with ICONNECT.']);
end
