function [Lo_D, Hi_D, Lo_R, Hi_R] = biorfilt(DF, RF, sansSortie)
%BIORFILT Banc de filtres biorthogonal à partir des deux filtres d'échelle.
%   [LO_D,HI_D,LO_R,HI_R] = BIORFILT(DF,RF) construit le banc à partir du
%   filtre d'échelle d'analyse DF et de celui de synthèse RF, que rend
%   BIORWAVF.
%
%   Les relations sont celles du banc biorthogonal :
%
%      Lo_D[n] = DF[N+1-n],       Lo_R[n] = RF[n],
%      Hi_D[n] = (-1)^n Lo_R[n],  Hi_R[n] = (-1)^(n+1) Lo_D[n],
%
%   chaque filtre d'échelle étant d'abord normalisé à une somme de racine
%   de deux. Le passe-haut d'analyse se lit sur le passe-bas de synthèse,
%   et le passe-haut de synthèse sur le passe-bas d'analyse : c'est là
%   toute la différence avec l'orthogonal, où un seul filtre suffit. Le
%   croisement est ce qui fait que
%
%      conv(Lo_D,Lo_R) + conv(Hi_D,Hi_R)
%
%   vaut deux au centre et zéro partout ailleurs — la reconstruction
%   parfaite.
%
%   Ces relations donnent Hi_D(z) = -Lo_R(-z) et Hi_R(z) = Lo_D(-z) :
%   c'est ce qui annule le repliement, la partie du signal que le
%   sous-échantillonnage a repliée. Encore faut-il que les deux filtres
%   d'échelle soient alignés à un décalage pair près, faute de quoi le
%   demi-bande change de parité et le repliement subsiste — la distorsion
%   restant nulle, l'erreur ne se voit qu'à la reconstruction. C'est
%   pourquoi les deux filtres se complètent, comme dans MATLAB, à une même
%   longueur paire.
%
%   Exemple :
%      [df, rf] = biorwavf('bior2.2');
%      [lod, hid, lor, hir] = biorfilt(df, rf);
%      max(abs(conv(lod, lor) + conv(hid, hir) - ...
%              [zeros(1, numel(lod) - 1), 2, zeros(1, numel(lod) - 1)]))
%
%   Voir aussi BIORWAVF, RBIOWAVF, ORTHFILT, WFILTERS.
    if nargin < 3, sansSortie = false; end
    DF = double(DF(:))';
    RF = double(RF(:))';
    % Les deux filtres se complètent à une même longueur paire, les zéros
    % répartis comme dans MATLAB (le plus petit nombre à gauche) : c'est la
    % parité de cette longueur qui met les centres des deux filtres à la
    % distance qui annule le repliement.
    n = max(numel(DF), numel(RF));
    n = n + mod(n, 2);
    DF = completer(DF, n);
    RF = completer(RF, n);
    analyse = DF / sum(DF) * sqrt(2);
    synthese = RF / sum(RF) * sqrt(2);
    Lo_D = analyse(end:-1:1);
    Lo_R = synthese;
    % Le banc rend le signal retardé du pic de conv(Lo_D,Lo_R). DWT et
    % IDWT attendent ce pic au rang N : on décale les deux filtres
    % ensemble — un zéro devant chacun avance le pic de deux rangs, un
    % zéro derrière allonge les filtres sans le bouger — pour l'y amener.
    % Décaler les deux à la fois ne change pas leur position relative,
    % qui est ce qui compte pour le repliement.
    [~, pic] = max(abs(conv(Lo_D, Lo_R)));
    while pic < numel(Lo_D)
        Lo_D = [0, Lo_D];
        Lo_R = [0, Lo_R];
        pic = pic + 2;
    end
    while pic > numel(Lo_D)
        % Un zéro derrière chacun allonge les filtres sans déplacer le
        % pic : c'est l'autre sens du même réglage.
        Lo_D = [Lo_D, 0];
        Lo_R = [Lo_R, 0];
    end
    n = numel(Lo_D);
    Hi_D = Lo_R .* (-1) .^ (1:n);
    Hi_R = Lo_D .* (-1) .^ (2:(n + 1));
    if sansSortie
        % La forme à huit sorties de MATLAB n'est pas reprise : elle rend
        % les mêmes filtres découpés en deux bancs.
        error('wavelet:biorfilt:HuitSorties', ...
              'The eight-output syntax is not supported.');
    end
end

function v = completer(f, n)
    manque = n - numel(f);
    v = [zeros(1, floor(manque / 2)), f, zeros(1, ceil(manque / 2))];
end
