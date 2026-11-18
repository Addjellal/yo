function x = idwt2(cA, cH, cV, cD, varargin)
%IDWT2 Reconstruction bidimensionnelle, un niveau.
%   X = IDWT2(CA,CH,CV,CD,'wname') est la réciproque de DWT2 ;
%   IDWT2(CA,CH,CV,CD,Lo_R,Hi_R) emploie des filtres donnés.
%   X = IDWT2(...,S) rend la partie centrale de taille S, ce qui retrouve
%   exactement la taille de l'image d'origine. Sans S, X a la taille
%   2*size(CA)-numel(Lo_R)+2 (2*size(CA) en mode 'per').
%   IDWT2(...,'mode',MODE) choisit le mode ; par défaut celui de DWTMODE.
%   Un détail vide compte pour zéro.
%
%   Exemple :
%      [a,h,v,d] = dwt2(magic(4), 'db2');
%      max(max(abs(idwt2(a,h,v,d,'db2',[4 4]) - magic(4))))   % nul
%
%   Voir aussi DWT2, WAVEREC2, IDWT.
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R, mode, reste] = matlibre_ondelette_arguments(varargin, 'r', 'idwt2');
    reference = cA;
    for candidat = {cH, cV, cD}
        if isempty(reference)
            reference = candidat{1};
        end
    end
    if isempty(reference)
        x = [];
        return
    end
    lf = numel(Lo_R);
    taille = [];
    if ~isempty(reste) && ~isempty(reste{1})
        taille = reste{1}(1:2);
    end
    if isempty(taille)
        if strcmp(mode, 'per')
            taille = 2 * [size(reference, 1), size(reference, 2)];
        else
            taille = 2 * [size(reference, 1), size(reference, 2)] - lf + 2;
        end
    end
    x = matlibre_upsconv2(cA, Lo_R, Lo_R, taille, mode) + ...
        matlibre_upsconv2(cH, Hi_R, Lo_R, taille, mode) + ...
        matlibre_upsconv2(cV, Lo_R, Hi_R, taille, mode) + ...
        matlibre_upsconv2(cD, Hi_R, Hi_R, taille, mode);
end
