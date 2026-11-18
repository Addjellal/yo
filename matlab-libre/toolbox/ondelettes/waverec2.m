function x = waverec2(C, S, varargin)
%WAVEREC2 Reconstruction d'une image à partir de sa décomposition.
%   X = WAVEREC2(C,S,'wname') est la réciproque de WAVEDEC2, c'est-à-dire
%   APPCOEF2(C,S,'wname',0) ; WAVEREC2(C,S,Lo_R,Hi_R) avec des filtres
%   donnés. L'ondelette et le mode de DWTMODE doivent être ceux de la
%   décomposition.
%
%   Exemple :
%      [C, S] = wavedec2(magic(8), 2, 'haar');
%      max(max(abs(waverec2(C, S, 'haar') - magic(8)))) < 1e-10
%
%   Voir aussi WAVEDEC2, APPCOEF2, WRCOEF2.
    if isempty(varargin)
        varargin = {'haar'};
    end
    x = appcoef2(C, S, varargin{:}, 0);
end
