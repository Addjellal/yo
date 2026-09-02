function [entree, sortie, boucle] = wcdiskmargin(G, K, options)
%WCDISKMARGIN Pires marges de disque d'une boucle incertaine.
%   [EM,SM,BM] = WCDISKMARGIN(G,K) cherche, dans le domaine des
%   paramètres du procédé incertain G, la combinaison qui dégrade le plus
%   les marges de la boucle. Les trois structures ont la même forme que
%   celles de LOOPMARGIN, avec en plus le champ Values, qui donne les
%   valeurs de paramètres du pire cas.
%
%   La marge de disque mesure ce que la boucle supporte en gain et en
%   phase à la fois. Sa version pire cas répond à la question qui compte
%   vraiment : combien de marge reste-t-il quand le procédé n'est pas
%   celui qu'on croit ?
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
%      C = ss(tf([10 10], [1 0]));
%      [em, sm, bm] = wcdiskmargin(G, C);
%      bm.DiskMargin
%      bm.Values.k
%
%   Voir aussi LOOPMARGIN, WCSENS, WCGAIN, ROBSTAB, NCFMARGIN.
    if nargin < 3
        options = struct();
    end
    [parametres, evaluer] = matlibre_incertitudes(G);
    Kss = ss(K);
    % On minimise la marge : la recherche maximise, on prend donc
    % l'oppose.
    cout = @(v) -matlibre_marge_disque(evaluer(v), Kss);
    [oppose, valeurs] = matlibre_balayer_incertitude(parametres, cout, options);
    marge = -oppose;
    modelePire = ss(evaluer(valeurs));
    [entree, sortie, boucle] = loopmargin(modelePire, Kss);
    entree.Values = valeurs;
    sortie.Values = valeurs;
    boucle.Values = valeurs;
    boucle.DiskMargin = marge;
end
