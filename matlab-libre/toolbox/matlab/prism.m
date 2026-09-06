function carte = prism(m)
%PRISM Carte de couleurs répétant les six couleurs du prisme.
%   CARTE = PRISM() rend une carte de 256 couleurs répétant en boucle les
%   six couleurs du prisme : rouge, orange, jaune, vert, bleu, violet.
%   CARTE = PRISM(M) en rend M.
%
%   Elle est délibérément discontinue : deux niveaux voisins reçoivent des
%   couleurs sans rapport, et le motif recommence tous les six niveaux.
%   Elle ne représente donc aucun ordre, et employée sur un champ continu
%   elle fabrique des bandes qui n'existent pas dans les données.
%
%   Son usage est ailleurs : distinguer des régions étiquetées, des lignes
%   de niveau successives, des composantes connexes — tout ce qui est
%   nominal et non ordonné, où le contraste maximal entre voisins est
%   justement ce qu'on cherche.
%
%   Exemple :
%      carte = prism(12);
%      isequal(carte(1:6, :), carte(7:12, :))
%
%   Voir aussi COLORMAP, LINES, PARULA, HSV.
    if nargin < 1 || isempty(m), m = 256; end
    m = round(m);
    base = [1 0 0; 1 0.5 0; 1 1 0; 0 1 0; 0 0 1; 0.6667 0 1];
    indices = mod(0:m-1, 6) + 1;
    carte = base(indices, :);
end
