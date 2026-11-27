function varargout = detcoef(C, L, niveaux, option)
%DETCOEF Coefficients de détail d'une décomposition WAVEDEC.
%   D = DETCOEF(C,L,N) extrait le bloc du niveau N dans le vecteur rendu
%   par WAVEDEC. Le niveau 1 est le plus fin. D = DETCOEF(C,L) rend celui
%   du niveau le plus grossier, comme dans MATLAB.
%   D = DETCOEF(C,L,N) avec N vecteur, ou DETCOEF(C,L,N,'cells'), rend un
%   tableau de cellules, un bloc par niveau de N ;
%   [D1,...,Dp] = DETCOEF(C,L,[N1,...,Np]) les rend un par sortie.
%
%   Exemple :
%      [c, l] = wavedec(1:8, 2, 'db1');
%      numel(detcoef(c, l, 1))   % 4
%      d = detcoef(c, l, [1 2]); % {d1, d2}
%
%   Voir aussi APPCOEF, WAVEDEC, WRCOEF.
    nmax = numel(L) - 2;
    if nargin < 3 || isempty(niveaux)
        niveaux = nmax;
    end
    enCellules = nargin >= 4 && any(strcmpi(char(option), {'cells', 'dcells'}));
    if any(niveaux < 1 | niveaux > nmax | niveaux ~= round(niveaux))
        error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
              'DETCOEF: the level must be from 1 to %d.', nmax);
    end
    % Début de chaque bloc de détail : après l'approximation, du niveau
    % le plus grossier au plus fin.
    fins = cumsum(L(1:end - 1));
    blocs = cell(1, numel(niveaux));
    for k = 1:numel(niveaux)
        n = niveaux(k);
        rang = nmax + 2 - n;          % position du niveau N dans L
        debut = fins(rang - 1) + 1;
        blocs{k} = C(debut:fins(rang));
    end
    if nargout <= 1 && (numel(niveaux) > 1 || enCellules)
        varargout{1} = blocs;
    elseif nargout <= 1
        varargout{1} = blocs{1};
    else
        varargout = blocs;
    end
end
