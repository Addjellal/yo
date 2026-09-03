function [phi, psiH, psiV, psiD, xyval] = wavefun2(nom, iterations, tracer)
%WAVEFUN2 Fonctions d'échelle et d'ondelettes en deux dimensions.
%   [PHI,PSIH,PSIV,PSID,XYVAL] = WAVEFUN2(NOM,ITER) approche les quatre
%   fonctions de la base bidimensionnelle, obtenues par produit des
%   fonctions à une dimension :
%
%      phi(x,y)  = phi(x) phi(y)      approximation
%      psiH(x,y) = phi(x) psi(y)      détail horizontal
%      psiV(x,y) = psi(x) phi(y)      détail vertical
%      psiD(x,y) = psi(x) psi(y)      détail diagonal
%
%   La séparabilité est ce qui rend la transformée d'image aussi rapide
%   que celle d'un signal : on filtre les lignes, puis les colonnes.
%
%   XYVAL est la grille commune, celle que rend WAVEFUN.
%
%   Exemple :
%      [phi, ph, pv, pd, xy] = wavefun2('db2', 6);
%      size(phi)
%      abs(sum(pd(:)))                % nul : le détail est de moyenne nulle
%
%   Voir aussi WAVEFUN, WFILTERS, DWT2, WAVEDEC2.
    if nargin < 2 || isempty(iterations), iterations = 8; end
    if nargin < 3, tracer = 0; end
    [phi1, psi1, xyval] = wavefun(nom, iterations);
    phi1 = phi1(:);
    psi1 = psi1(:);
    phi = phi1 * phi1.';
    psiH = phi1 * psi1.';
    psiV = psi1 * phi1.';
    psiD = psi1 * psi1.';
    if tracer
        figure;
        noms = {'phi', 'psi horizontal', 'psi vertical', 'psi diagonal'};
        images = {phi, psiH, psiV, psiD};
        for k = 1:4
            subplot(2, 2, k);
            imagesc(xyval, xyval, images{k});
            title(noms{k});
        end
    end
end
