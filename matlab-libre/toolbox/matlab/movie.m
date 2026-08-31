function movie(varargin)
%MOVIE Rejoue une animation (acceptée, sans effet).
%   MOVIE(F) rejoue, dans MATLAB, les vues capturées par GETFRAME.
%   MOVIE(F,N) la rejoue N fois ; MOVIE(F,N,FPS) fixe la cadence.
%
%   Les figures de MatLibre sont rendues une fois pour toutes, et non
%   animées : l'appel est accepté pour qu'un programme tourne sans
%   retouche, et ne joue rien. La dernière vue reste affichée, ce qui est
%   ce qu'une animation laisse quand on l'imprime.
%
%   Exemple :
%      for k = 1:10
%          plot(sin((1:100) / 10 + k));
%          F(k) = getframe;
%      end
%      movie(F, 2);          % accepte, sans effet
%
%   Voir aussi GETFRAME, COMET, DRAWNOW, ANIMATEDLINE.
    if isempty(varargin)
        error('MATLAB:movie:NotEnoughInputs', 'MOVIE needs a frame array.');
    end
end
