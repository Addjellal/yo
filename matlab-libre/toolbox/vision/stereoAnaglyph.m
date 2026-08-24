function J = stereoAnaglyph(gauche, droite)
%STEREOANAGLYPH Anaglyphe rouge-cyan d'une paire stéréoscopique.
%   J = STEREOANAGLYPH(G,D) place l'image gauche dans le canal rouge et
%   l'image droite dans les canaux vert et bleu. Vue à travers des
%   lunettes rouge-cyan, chaque œil ne reçoit que son image et le relief
%   apparaît.
%
%   Les deux images doivent avoir la même taille ; celles en couleur sont
%   converties en niveaux de gris.
%
%   Exemple :
%      a = stereoAnaglyph(zeros(4), ones(4));
%      a(1, 1, :)   % [0 1 1] : noir à gauche, blanc à droite
%
%   Voir aussi DISPARITYBM.
    G = enNiveauxDeGris(gauche);
    D = enNiveauxDeGris(droite);
    if ~isequal(size(G), size(D))
        error('vision:stereoAnaglyph:BadSize', ...
              'Les deux images doivent avoir la même taille.');
    end
    J = zeros(size(G, 1), size(G, 2), 3);
    J(:, :, 1) = G;
    J(:, :, 2) = D;
    J(:, :, 3) = D;
end

function I = enNiveauxDeGris(I)
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
end
