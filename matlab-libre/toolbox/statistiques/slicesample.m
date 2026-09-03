function [echantillon, nEvaluations] = slicesample(depart, n, varargin)
%SLICESAMPLE Échantillonnage par tranches.
%   X = SLICESAMPLE(X0,N,'pdf',F) tire N points d'une loi dont F donne la
%   densité, à une constante près. La méthode ne demande ni loi de
%   proposition ni réglage de pas : à chaque tour, on tire une hauteur
%   sous la densité, puis un point au hasard dans la tranche horizontale
%   qu'elle découpe.
%
%   X = SLICESAMPLE(X0,N,'logpdf',F) prend le logarithme de la densité,
%   ce qui évite les débordements.
%   SLICESAMPLE(...,'width',W) donne la largeur initiale de la tranche,
%   'burnin',B jette les B premiers points, 'thin',T n'en garde qu'un
%   sur T.
%
%   [X,NEVAL] = SLICESAMPLE(...) rend le nombre d'évaluations de la
%   densité.
%
%   Exemple :
%      rng(1);
%      x = slicesample(0, 5000, 'pdf', @(t) exp(-t.^2 / 2));
%      abs(mean(x)) < 0.1 && abs(std(x) - 1) < 0.1
%
%   Voir aussi MHSAMPLE, RANDOM, RANDSAMPLE, KSDENSITY.
    densite = [];
    logDensite = [];
    largeur = 10;
    rodage = 0;
    eclaircie = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'pdf',     densite = varargin{k+1};
            case 'logpdf',  logDensite = varargin{k+1};
            case 'width',   largeur = double(varargin{k+1});
            case 'burnin',  rodage = round(varargin{k+1});
            case 'thin',    eclaircie = max(1, round(varargin{k+1}));
            otherwise
                error('stats:slicesample:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(densite) && isempty(logDensite)
        error('stats:slicesample:Densite', ...
              'Il faut donner « pdf » ou « logpdf ».');
    end
    if isempty(logDensite)
        logDensite = @(x) log(max(densite(x), realmin));
    end
    depart = double(depart(:)).';
    d = numel(depart);
    if isscalar(largeur)
        largeur = repmat(largeur, 1, d);
    end
    echantillon = zeros(n, d);
    nEvaluations = 0;
    courant = depart;
    logCourant = logDensite(courant);
    nEvaluations = nEvaluations + 1;
    total = rodage + n * eclaircie;
    garde = 0;
    for pas = 1:total
        for j = 1:d
            % La hauteur de la tranche, tirée sous la densité.
            niveau = logCourant + log(rand());
            % La tranche est élargie par pas jusqu'à sortir de la densité :
            % c'est le « stepping out » de Neal.
            gauche = courant(j) - largeur(j) * rand();
            droite = gauche + largeur(j);
            essai = courant;
            essai(j) = gauche;
            while logDensite(essai) > niveau
                gauche = gauche - largeur(j);
                essai(j) = gauche;
                nEvaluations = nEvaluations + 1;
            end
            essai(j) = droite;
            while logDensite(essai) > niveau
                droite = droite + largeur(j);
                essai(j) = droite;
                nEvaluations = nEvaluations + 1;
            end
            % Puis on tire dans la tranche, en la rétrécissant tant que
            % le point tiré est hors de la densité.
            for tentative = 1:200
                candidat = gauche + (droite - gauche) * rand();
                essai(j) = candidat;
                logEssai = logDensite(essai);
                nEvaluations = nEvaluations + 1;
                if logEssai > niveau
                    courant(j) = candidat;
                    logCourant = logEssai;
                    break;
                end
                if candidat < courant(j)
                    gauche = candidat;
                else
                    droite = candidat;
                end
            end
        end
        if pas > rodage && mod(pas - rodage, eclaircie) == 0
            garde = garde + 1;
            if garde <= n
                echantillon(garde, :) = courant;
            end
        end
    end
end
