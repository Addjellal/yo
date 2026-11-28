function y = wextend(type, mode, x, longueur, cote)
%WEXTEND Prolonge un signal ou une image aux bords.
%   Y = WEXTEND(TYPE,MODE,X,L) où TYPE vaut 1 ou '1D' pour un signal,
%   2 ou '2D' pour une image, et MODE l'un de :
%     'zpd'            zéros
%     'sp0'            répétition du bord (lissage d'ordre 0)
%     'spd' ou 'sp1'   prolongement affine (lissage d'ordre 1)
%     'sym' ou 'symh'  symétrie demi-point : le bord est répété
%     'symw'           symétrie point entier : le bord n'est pas répété
%     'asym', 'asymh'  antisymétrie demi-point
%     'asymw'          antisymétrie point entier
%     'ppd'            périodique
%     'per'            périodique, la longueur étant d'abord rendue paire
%
%   COTE vaut 'b' (des deux côtés, par défaut), 'l' ou 'r'.
%
%   Y = WEXTEND('addrow',MODE,X,L) ajoute L lignes en haut et en bas de
%   la matrice X ('u', 'd' ou 'b' pour le côté) ; 'addcol' ajoute des
%   colonnes. Seule cette dimension est touchée, même en mode 'per' :
%   c'est ce que DWT2 emploie.
%
%   Les modes sont ceux de MATLAB, vérifiés contre PyWavelets ; en
%   particulier 'asym' est périodique de période 2N sur [x, -x renversé],
%   et 'asymw' enchaîne les réflexions ponctuelles 2*x(1) - x(1+k).
%
%   Exemples :
%      wextend('1D', 'zpd',   [1 2 3], 2)   % [0 0 1 2 3 0 0]
%      wextend('1D', 'sp0',   [1 2 3], 2)   % [1 1 1 2 3 3 3]
%      wextend('1D', 'spd',   [1 2 3], 2)   % [-1 0 1 2 3 4 5]
%      wextend('1D', 'sym',   [1 2 3], 2)   % [2 1 1 2 3 3 2]
%      wextend('1D', 'symw',  [1 2 3], 2)   % [3 2 1 2 3 2 1]
%      wextend('1D', 'asym',  [1 2 3], 2)   % [-2 -1 1 2 3 -3 -2]
%      wextend('1D', 'asymw', [1 2 3], 2)   % [-1 0 1 2 3 4 5]
%      wextend('1D', 'ppd',   [1 2 3], 2)   % [2 3 1 2 3 1 2]
%
%   Voir aussi WKEEP, DWT.
    if nargin < 5 || isempty(cote), cote = 'b'; end
    type = lower(char(string(type)));
    mode = lower(char(mode));
    cote = lower(char(cote));
    if any(strcmp(type, {'2', '2d'}))
        if numel(longueur) == 1, longueur = [longueur longueur]; end
        y = double(x);
        y = prolongerLignes(y, mode, longueur(1), cote);
        y = prolongerLignes(y.', mode, longueur(2), cote).';
        return
    end
    % 'addrow' ajoute des lignes (chaque colonne est prolongée), 'addcol'
    % des colonnes ; l'autre dimension n'est pas touchée, même en mode
    % 'per'. Le côté vaut 'u'/'d' (haut, bas) ou 'l'/'r', ou 'b'.
    if any(strcmp(type, {'addrow', 'ar'}))
        cote = strrep(strrep(cote, 'u', 'l'), 'd', 'r');
        y = prolongerLignes(double(x), mode, longueur(1), cote);
        return
    end
    if any(strcmp(type, {'addcol', 'ac'}))
        y = prolongerLignes(double(x).', mode, longueur(1), cote).';
        return
    end
    ligne = isrow(x);
    v = double(x(:)).';
    y = prolongerVecteur(v, mode, longueur, cote);
    if ~ligne, y = y'; end
end

function y = prolongerLignes(x, mode, longueur, cote)
%PROLONGERLIGNES Prolonge chaque colonne, la largeur ne bougeant pas.
    premiere = prolongerVecteur(x(:, 1)', mode, longueur, cote);
    y = zeros(numel(premiere), size(x, 2));
    y(:, 1) = premiere(:);
    for k = 2:size(x, 2)
        colonne = prolongerVecteur(x(:, k)', mode, longueur, cote);
        y(:, k) = colonne(:);
    end
end

function y = prolongerVecteur(v, mode, longueur, cote)
    if strcmp(mode, 'per')
        % La périodisation de MATLAB commence par rendre la longueur
        % paire, en répétant le dernier échantillon.
        if mod(numel(v), 2) == 1
            v = [v v(end)];
        end
        mode = 'ppd';
    end
    n = numel(v);
    if longueur <= 0
        y = v;
        return
    end
    switch mode
        case 'zpd'
            gauche = zeros(1, longueur);
            droite = zeros(1, longueur);
        case {'sp0', 'rep'}
            gauche = repmat(v(1), 1, longueur);
            droite = repmat(v(end), 1, longueur);
        case {'spd', 'sp1'}
            % Prolongement affine : on continue la pente du bord.
            if n == 1
                penteG = 0;
                penteD = 0;
            else
                penteG = v(1) - v(2);
                penteD = v(end) - v(end-1);
            end
            gauche = v(1) + penteG * (longueur:-1:1);
            droite = v(end) + penteD * (1:longueur);
        case {'sym', 'symh'}
            [gauche, droite] = miroir(v, longueur, false);
        case 'symw'
            [gauche, droite] = miroir(v, longueur, true);
        case {'asym', 'asymh'}
            % Périodique de période 2N sur le motif [x, -x renversé] : la
            % négation ne vaut que pour une période sur deux.
            motif = [v, -v(end:-1:1)];
            periode = 2 * n;
            gauche = motif(mod(-(longueur:-1:1), periode) + 1);
            droite = motif(mod(n - 1 + (1:longueur), periode) + 1);
        case 'asymw'
            % Réflexions ponctuelles successives : chaque bloc de N-1
            % valeurs est le reflet, par rapport au dernier point atteint,
            % du bloc qui le précède — e(c+j) = 2 e(c) - e(c-j).
            droite = reflexionsPonctuelles(v, longueur);
            gauche = reflexionsPonctuelles(v(end:-1:1), longueur);
            gauche = gauche(end:-1:1);
        case 'ppd'
            gauche = zeros(1, longueur);
            droite = zeros(1, longueur);
            for k = 1:longueur
                gauche(longueur - k + 1) = v(mod(n - k, n) + 1);
                droite(k) = v(mod(k - 1, n) + 1);
            end
        otherwise
            error('wavelet:wextend:UnknownMode', 'Mode inconnu : %s.', mode);
    end
    switch cote
        case 'l'
            y = [gauche v];
        case 'r'
            y = [v droite];
        otherwise
            y = [gauche v droite];
    end
end

function [gauche, droite] = miroir(v, longueur, pointEntier)
%MIROIR Réflexion aux deux bords, par répétition périodique du motif
%   replié. POINTENTIER vrai réfléchit autour de l'échantillon du bord,
%   qui n'est donc pas répété ; faux réfléchit à mi-chemin, et le bord
%   apparaît deux fois.
    n = numel(v);
    if pointEntier
        if n == 1
            gauche = repmat(v(1), 1, longueur);
            droite = gauche;
            return
        end
        periode = 2 * n - 2;
        motif = [v v(end-1:-1:2)];
    else
        periode = 2 * n;
        motif = [v v(end:-1:1)];
    end
    gauche = zeros(1, longueur);
    droite = zeros(1, longueur);
    for k = 1:longueur
        if pointEntier
            gauche(longueur - k + 1) = motif(mod(-k, periode) + 1);
            droite(k) = motif(mod(n - 1 + k, periode) + 1);
        else
            gauche(longueur - k + 1) = motif(mod(-k, periode) + 1);
            droite(k) = motif(mod(n - 1 + k, periode) + 1);
        end
    end
end

% Les LONGUEUR valeurs qui prolongent V à droite par réflexions
% ponctuelles répétées (mode 'asymw', « antireflect » de PyWavelets).
function droite = reflexionsPonctuelles(v, longueur)
    n = numel(v);
    if n == 1
        droite = repmat(v, 1, longueur);
        return
    end
    s = v;
    while numel(s) < n + longueur
        c = numel(s);
        bloc = 2 * s(c) - s(c - (1:n - 1));
        s = [s, bloc]; %#ok<AGROW>
    end
    droite = s(n + 1:n + longueur);
end
