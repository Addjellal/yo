function sortie = dwtmode(mode, silence)
%DWTMODE Mode de prolongement des bords de la transformée discrète.
%   DWTMODE affiche le mode courant.
%   DWTMODE(MODE) le change, pour DWT, IDWT, WAVEDEC, WAVEREC, DWT2 et
%   leurs voisines. Les modes, comme dans MATLAB :
%      'sym' ou 'symh'   symétrie en demi-point — le défaut
%      'symw'            symétrie en point entier
%      'asym' ou 'asymh' antisymétrie en demi-point
%      'asymw'           antisymétrie en point entier
%      'zpd'             zéros
%      'sp0'             répétition du bord
%      'spd' ou 'sp1'    prolongement affine (pente du bord)
%      'ppd'             périodique
%      'per'             périodique, avec le moins de coefficients
%                        possible : numel(X)/2 par niveau
%   ST = DWTMODE('status') rend le mode courant sans rien afficher ;
%   DWTMODE(MODE,'nodisp') change le mode sans l'annoncer.
%
%   Le mode vaut pour la session ; DWT(...,'mode',MODE) le change pour un
%   seul appel.
%
%   Exemple :
%      dwtmode('status', 'nodisp')      % 'sym'
%      dwtmode('per', 'nodisp');
%      [a, d] = dwt(1:8, 'db2');        % 4 coefficients chacun
%      dwtmode('sym', 'nodisp');
%
%   Voir aussi DWT, WAVEDEC, WEXTEND.
    persistent courant
    if isempty(courant)
        courant = 'sym';
    end
    if nargin < 2, silence = ''; end
    muet = strcmpi(char(silence), 'nodisp');
    if nargin < 1 || isempty(mode)
        if nargout > 0
            sortie = courant;
        else
            fprintf('Mode de prolongement des ondelettes : %s\n', courant);
        end
        return
    end
    texte = lower(char(mode));
    if strcmp(texte, 'status')
        if nargout > 0
            sortie = courant;
        elseif ~muet
            fprintf('Mode de prolongement des ondelettes : %s\n', courant);
        end
        return
    end
    courant = matlibre_mode_ondelette(texte);
    if nargout > 0
        sortie = courant;
    elseif ~muet
        fprintf('Mode de prolongement des ondelettes : %s\n', courant);
    end
end
