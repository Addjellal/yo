function sortie = dwtmode(mode, silence)
%DWTMODE Mode de prolongement des bords de la transformée discrète.
%   DWTMODE affiche le mode courant.
%   DWTMODE(MODE) le change. MODE vaut 'per' (périodique), 'zpd'
%   (zéros), 'sym' (symétrie), 'spd' (prolongement affine), 'sp0'
%   (répétition du bord), 'ppd' (périodique sans ajustement de parité).
%   ST = DWTMODE('status') rend le mode courant sans rien afficher.
%   DWTMODE(MODE,'nodisp') change le mode sans l'annoncer.
%
%   MatLibre ne sait analyser qu'en périodique : DWT, WAVEDEC et leurs
%   voisines prolongent le signal par périodicité, ce qui garde le nombre
%   de coefficients égal à celui des échantillons. Le mode est donc lu et
%   conservé, mais seul 'per' est accepté ; demander autre chose lève une
%   erreur au lieu d'analyser autrement que promis.
%
%   Exemple :
%      dwtmode('status')              % 'per'
%      dwtmode('per', 'nodisp');
%
%   Voir aussi DWT, WAVEDEC, WEXTEND.
    persistent courant
    if isempty(courant)
        courant = 'per';
    end
    if nargin < 2, silence = ''; end
    muet = strcmpi(char(silence), 'nodisp');
    if nargin < 1 || isempty(mode)
        if nargout > 0
            sortie = courant;
        else
            fprintf('Mode de prolongement : %s (périodique)\n', courant);
        end
        return
    end
    mode = lower(char(mode));
    if strcmp(mode, 'status')
        if nargout > 0
            sortie = courant;
        elseif ~muet
            fprintf('Mode de prolongement : %s\n', courant);
        end
        return
    end
    connus = {'per', 'zpd', 'sym', 'symh', 'symw', 'asym', 'asymh', ...
              'asymw', 'spd', 'sp1', 'sp0', 'ppd'};
    if ~any(strcmp(mode, connus))
        error('wavelet:dwtmode:Mode', 'Mode inconnu : %s.', mode);
    end
    if ~strcmp(mode, 'per')
        error('wavelet:dwtmode:NonGere', ...
              ['MatLibre n''analyse qu''en mode périodique ; ''%s'' n''est ' ...
               'pas géré. WEXTEND, lui, connaît tous les prolongements.'], mode);
    end
    courant = mode;
    if nargout > 0
        sortie = courant;
    elseif ~muet
        fprintf('Mode de prolongement : %s\n', courant);
    end
end
