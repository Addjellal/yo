function [xd, C, L] = wden(varargin)
%WDEN Débruitage automatique par seuillage des coefficients.
%   XD = WDEN(X,TPTR,SORH,SCAL,N,NOM) décompose X sur N niveaux avec
%   l'ondelette NOM, seuille les détails, puis reconstruit.
%     TPTR   règle du seuil : 'rigrsure', 'heursure', 'sqtwolog',
%            'minimaxi'
%     SORH   's' pour un seuillage doux, 'h' pour un seuillage dur
%     SCAL   'one'  le bruit est d'écart type un
%            'sln'  écart type estimé une fois, sur le premier niveau
%            'mln'  écart type estimé niveau par niveau
%
%   [XD,C,L] = WDEN(...) rend aussi la décomposition débruitée.
%   WDEN(C,L,TPTR,SORH,SCAL,N,NOM) part d'une décomposition déjà faite.
%
%   C'est l'interface d'origine, celle de Donoho et Johnstone. WDENOISE
%   est plus récente et offre davantage de règles ; WDEN reste là parce
%   que beaucoup de code l'emploie.
%
%   Exemple :
%      [propre, bruite] = wnoise(3, 10, 7, 5);
%      xd = wden(bruite, 'sqtwolog', 's', 'sln', 3, 'db4');
%      norm(xd - propre) < norm(bruite - propre)   % vrai
%
%   Voir aussi WDENOISE, WDENCMP, THSELECT, WNOISEST, WTHRESH.
    if numel(varargin) >= 7 && isnumeric(varargin{1}) && isnumeric(varargin{2}) ...
            && ~isscalar(varargin{2}) && ischar(varargin{3})
        C = double(varargin{1});
        L = double(varargin{2});
        tptr = varargin{3};
        sorh = varargin{4};
        scal = varargin{5};
        niveaux = varargin{6};
        nom = varargin{7};
        estLigne = true;
    else
        if numel(varargin) < 6
            error('MATLAB:minrhs', 'Not enough input arguments.');
        end
        x = varargin{1};
        tptr = varargin{2};
        sorh = varargin{3};
        scal = varargin{4};
        niveaux = varargin{5};
        nom = varargin{6};
        estLigne = isrow(x);
        [C, L] = wavedec(double(x(:))', niveaux, nom);
    end
    tptr = lower(char(tptr));
    sorh = lower(char(sorh));
    scal = lower(char(scal));
    if ~any(strcmp(tptr, {'rigrsure', 'heursure', 'sqtwolog', 'minimaxi'}))
        error('wavelet:wden:Regle', 'Règle de seuil inconnue : %s.', tptr);
    end
    if ~any(strcmp(scal, {'one', 'sln', 'mln'}))
        error('wavelet:wden:Echelle', 'SCAL doit valoir ''one'', ''sln'' ou ''mln''.');
    end
    switch scal
        case 'one', sigmaGlobal = 1;
        case 'sln', sigmaGlobal = wnoisest(C, L, 1);
        case 'mln', sigmaGlobal = [];
    end
    debut = L(1) + 1;
    for k = 1:niveaux
        % Les détails sont rangés du plus grossier au plus fin ; le
        % niveau du bloc numéro K est donc niveaux - K + 1.
        longueur = L(k + 1);
        plage = debut:(debut + longueur - 1);
        niveau = niveaux - k + 1;
        if isempty(sigmaGlobal)
            sigma = wnoisest(C, L, niveau);
        else
            sigma = sigmaGlobal;
        end
        if sigma > 0
            seuil = sigma * thselect(C(plage) / sigma, tptr);
        else
            seuil = 0;
        end
        C(plage) = wthresh(C(plage), sorh, seuil);
        debut = debut + longueur;
    end
    xd = waverec(C, L, nom);
    if ~estLigne
        xd = xd(:);
    end
end
