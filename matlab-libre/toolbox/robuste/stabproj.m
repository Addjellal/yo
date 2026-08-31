function [stable, instable] = stabproj(sys)
%STABPROJ Sépare la partie stable de la partie instable.
%   [GS,GI] = STABPROJ(SYS) découpe SYS en deux modèles dont la somme
%   redonne SYS : GS porte les pôles à partie réelle strictement
%   négative, GI les autres. Le terme direct est mis dans GS.
%
%   C'est le préalable à toute réduction d'un modèle instable : on réduit
%   GS, qui a des grammiens, et l'on garde GI tel quel, qui n'en a pas.
%   C'est aussi ce que fait STABSEP dans la boîte à outils de
%   l'automatique ; les deux rendent la même chose.
%
%   Exemples :
%      G = ss([1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
%      [stable, instable] = stabproj(G);
%      pole(instable)                % 1
%      pole(stable)                  % -10 et -100
%      norm(G - (stable + instable), Inf) < 1e-8
%
%   Voir aussi STABSEP, SLOWFAST, MODREAL, NCFMR, LNCF.
    G = ss(sys);
    poles = eig(G.A);
    if G.Ts > 0
        garde = abs(poles) < 1;
    else
        garde = real(poles) < 0;
    end
    [stable, instable] = matlibre_scinder_modes(G, poles, garde);
end
