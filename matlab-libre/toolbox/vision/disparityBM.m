function [carte, cout] = disparityBM(gauche, droite, varargin)
%DISPARITYBM Carte de disparité par appariement de blocs.
%   D = DISPARITYBM(G,D) rend, pour chaque pixel de l'image gauche, le
%   décalage horizontal qui rend son voisinage le plus semblable dans
%   l'image droite. La mesure de ressemblance est la somme des différences
%   absolues, calculée sur un bloc carré.
%
%   Les deux images sont supposées rectifiées : le correspondant d'un
%   pixel est sur la même ligne, ce qui ramène la recherche à une
%   dimension. La disparité est inversement proportionnelle à la
%   profondeur.
%
%   Options et valeurs par défaut :
%     'DisparityRange'  [0 16], à valeurs entières
%     'BlockSize'       15, impair
%
%   [D,C] = DISPARITYBM(...) rend aussi le coût du meilleur appariement,
%   qui sert à repérer les zones sans texture où la mesure ne veut rien
%   dire.
%
%   Exemple :
%      g = zeros(20, 40); g(:, 10:15) = 1;
%      d = zeros(20, 40); d(:, 7:12) = 1;
%      carte = disparityBM(g, d, 'BlockSize', 5, 'DisparityRange', [0 8]);
%      round(median(carte(:, 10:15)(:)))   % 3
%
%   Voir aussi STEREOANAGLYPH.
    intervalle = [0 16];
    tailleBloc = 15;
    for k = 1:2:numel(varargin)-1
        switch lower(char(varargin{k}))
            case 'disparityrange', intervalle = double(varargin{k+1});
            case 'blocksize',      tailleBloc = double(varargin{k+1});
        end
    end
    G = enGris(gauche);
    D = enGris(droite);
    if ~isequal(size(G), size(D))
        error('vision:disparityBM:BadSize', ...
              'Les deux images doivent avoir la même taille.');
    end
    if mod(tailleBloc, 2) == 0
        tailleBloc = tailleBloc + 1;
    end
    rayon = floor(tailleBloc / 2);
    [h, l] = size(G);
    disparites = round(intervalle(1)):round(intervalle(2));
    meilleurCout = Inf(h, l);
    carte = NaN(h, l);
    noyau = ones(tailleBloc);
    for d = disparites
        % Décalage de l'image droite, avec remplissage par répétition du
        % bord : un pixel dont le correspondant sort du cadre n'est pas
        % appariable, et son coût doit rester élevé.
        decalee = decalerHorizontalement(D, d);
        differences = abs(G - decalee);
        agregat = imfilter(differences, noyau);
        valide = true(h, l);
        if d > 0
            valide(:, 1:min(l, d)) = false;
        end
        valide(:, 1:min(l, rayon)) = false;
        valide(:, max(1, l - rayon + 1):end) = false;
        valide(1:min(h, rayon), :) = false;
        valide(max(1, h - rayon + 1):end, :) = false;
        meilleur = agregat < meilleurCout & valide;
        meilleurCout(meilleur) = agregat(meilleur);
        carte(meilleur) = d;
    end
    cout = meilleurCout;
end

function I = enGris(I)
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
end

function J = decalerHorizontalement(I, d)
%DECALERHORIZONTALEMENT Décale vers la droite de D colonnes.
    [~, l] = size(I);
    J = I;
    if d > 0
        d = min(d, l);
        J = [repmat(I(:, 1), 1, d), I(:, 1:l-d)];
    elseif d < 0
        d = min(-d, l);
        J = [I(:, 1+d:end), repmat(I(:, end), 1, d)];
    end
end
