function [descripteur, disposition] = extractHOGFeatures(I, varargin)
%EXTRACTHOGFEATURES Histogrammes de gradients orientés.
%   F = EXTRACTHOGFEATURES(I) rend le descripteur de Dalal et Triggs : le
%   gradient est calculé partout, son orientation votée dans des
%   histogrammes par cellule, puis les cellules groupées en blocs
%   normalisés qui se recouvrent.
%
%   Le recouvrement des blocs est ce qui donne au descripteur sa
%   robustesse : chaque cellule est normalisée plusieurs fois, avec des
%   voisinages différents, si bien qu'un changement local d'éclairage
%   n'emporte pas tout.
%
%   Options et valeurs par défaut :
%     'CellSize'      [8 8]
%     'BlockSize'     [2 2]      en cellules
%     'BlockOverlap'  [1 1]      moitié du bloc
%     'NumBins'       9
%     'UseSignedOrientation'  false, l'orientation est prise modulo pi
%
%   La longueur du descripteur vaut
%     prod(BlocsParImage) * prod(BlockSize) * NumBins
%   avec
%     BlocsParImage = floor((floor(taille./CellSize) - BlockSize) ./
%                           (BlockSize - BlockOverlap)) + 1
%
%   [F,INFO] = EXTRACTHOGFEATURES(...) rend aussi cette disposition.
%
%   Exemple :
%      f = extractHOGFeatures(zeros(64, 64));
%      numel(f)   % 1764 = 7*7 blocs * 4 cellules * 9 secteurs
%
%   Voir aussi EXTRACTLBPFEATURES, EXTRACTFEATURES.
    tailleCellule = [8 8];
    tailleBloc = [2 2];
    recouvrement = [];
    nSecteurs = 9;
    signee = false;
    for k = 1:2:numel(varargin)-1
        switch lower(char(varargin{k}))
            case 'cellsize',     tailleCellule = double(varargin{k+1});
            case 'blocksize',    tailleBloc = double(varargin{k+1});
            case 'blockoverlap', recouvrement = double(varargin{k+1});
            case 'numbins',      nSecteurs = double(varargin{k+1});
            case 'usesignedorientation', signee = logical(varargin{k+1});
            otherwise
                error('vision:extractHOGFeatures:BadOption', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    if isscalar(tailleCellule), tailleCellule = [tailleCellule tailleCellule]; end
    if isscalar(tailleBloc), tailleBloc = [tailleBloc tailleBloc]; end
    if isempty(recouvrement), recouvrement = ceil(tailleBloc / 2); end
    if isscalar(recouvrement), recouvrement = [recouvrement recouvrement]; end
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
    [Gx, Gy] = gradientCentre(I);
    amplitude = sqrt(Gx .^ 2 + Gy .^ 2);
    if signee
        orientation = mod(atan2(Gy, Gx), 2 * pi);
        etendue = 2 * pi;
    else
        orientation = mod(atan2(Gy, Gx), pi);
        etendue = pi;
    end
    cellules = floor(size(I) ./ tailleCellule);
    histogrammes = zeros(cellules(1), cellules(2), nSecteurs);
    largeurSecteur = etendue / nSecteurs;
    for ci = 1:cellules(1)
        lignes = (ci - 1) * tailleCellule(1) + (1:tailleCellule(1));
        for cj = 1:cellules(2)
            colonnes = (cj - 1) * tailleCellule(2) + (1:tailleCellule(2));
            a = amplitude(lignes, colonnes);
            o = orientation(lignes, colonnes);
            % Vote bilinéaire entre les deux secteurs encadrants : sans
            % lui, une orientation qui bascule d'un secteur à l'autre
            % ferait sauter le descripteur.
            position = o(:) / largeurSecteur - 0.5;
            basIndice = floor(position);
            poidsHaut = position - basIndice;
            secteurBas = mod(basIndice, nSecteurs) + 1;
            secteurHaut = mod(basIndice + 1, nSecteurs) + 1;
            valeurs = a(:);
            histogramme = zeros(1, nSecteurs);
            for p = 1:numel(valeurs)
                histogramme(secteurBas(p)) = histogramme(secteurBas(p)) + valeurs(p) * (1 - poidsHaut(p));
                histogramme(secteurHaut(p)) = histogramme(secteurHaut(p)) + valeurs(p) * poidsHaut(p);
            end
            histogrammes(ci, cj, :) = histogramme;
        end
    end
    pas = tailleBloc - recouvrement;
    if any(pas < 1)
        error('vision:extractHOGFeatures:BadOverlap', ...
              'Le recouvrement doit rester strictement sous la taille du bloc.');
    end
    blocs = floor((cellules - tailleBloc) ./ pas) + 1;
    blocs = max(blocs, 0);
    disposition = struct('CellSize', tailleCellule, 'BlockSize', tailleBloc, ...
                         'BlockOverlap', recouvrement, 'NumBins', nSecteurs, ...
                         'NumCells', cellules, 'NumBlocks', blocs);
    if any(blocs < 1)
        descripteur = zeros(1, 0);
        return
    end
    parBloc = prod(tailleBloc) * nSecteurs;
    descripteur = zeros(1, prod(blocs) * parBloc);
    position = 1;
    for bj = 1:blocs(2)
        for bi = 1:blocs(1)
            lignes = (bi - 1) * pas(1) + (1:tailleBloc(1));
            colonnes = (bj - 1) * pas(2) + (1:tailleBloc(2));
            bloc = histogrammes(lignes, colonnes, :);
            v = bloc(:)';
            v = v / sqrt(sum(v .^ 2) + 1e-12);
            descripteur(position:position + parBloc - 1) = v;
            position = position + parBloc;
        end
    end
end

function [Gx, Gy] = gradientCentre(I)
%GRADIENTCENTRE Dérivées par différences centrées, sans lissage.
%   C'est le masque [-1 0 1] de Dalal et Triggs : ils ont montré que tout
%   lissage préalable dégrade la détection.
    Gx = zeros(size(I));
    Gy = zeros(size(I));
    Gx(:, 2:end-1) = (I(:, 3:end) - I(:, 1:end-2)) / 2;
    Gx(:, 1) = I(:, min(2, end)) - I(:, 1);
    Gx(:, end) = I(:, end) - I(:, max(end-1, 1));
    Gy(2:end-1, :) = (I(3:end, :) - I(1:end-2, :)) / 2;
    Gy(1, :) = I(min(2, end), :) - I(1, :);
    Gy(end, :) = I(end, :) - I(max(end-1, 1), :);
end
