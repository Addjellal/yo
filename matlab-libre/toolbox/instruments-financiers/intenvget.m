function varargout = intenvget(courbe, varargin)
%INTENVGET Lit un champ d'un environnement de taux.
%   V = INTENVGET(COURBE,'Rates') rend les taux. Sans nom de champ, la
%   structure entière est rendue ; avec plusieurs noms, autant de
%   sorties.
%
%   Exemple :
%      courbe = intenvset('Rates', [0.03; 0.035; 0.04], ...
%                         'StartDates', '01-Jan-2024', ...
%                         'EndDates', {'01-Jan-2025'; '01-Jan-2027'; '01-Jan-2029'});
%      taux = intenvget(courbe, 'Rates');
%
%   Voir aussi INTENVSET, INTENVPRICE.
    if ~isstruct(courbe) || ~isfield(courbe, 'FinObj') || ...
            ~strcmp(courbe.FinObj, 'RateSpec')
        error('finstr:intenvget:Courbe', ...
              'INTENVGET attend un environnement de taux.');
    end
    if isempty(varargin)
        varargout{1} = courbe;
        return
    end
    champs = fieldnames(courbe);
    for k = 1:numel(varargin)
        demande = char(varargin{k});
        rang = find(strcmpi(champs, demande), 1);
        if isempty(rang)
            error('finstr:intenvget:Champ', 'Champ inconnu : %s.', demande);
        end
        varargout{k} = courbe.(champs{rang});   %#ok<AGROW>
    end
end
