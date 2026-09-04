function courbe = intenvset(varargin)
%INTENVSET Construit ou modifie un environnement de taux.
%   COURBE = INTENVSET('Rates',R,'StartDates',D1,'EndDates',D2,...)
%   range une courbe de taux dans une structure que les fonctions de
%   valorisation savent lire. Les autres propriétés sont 'Compounding'
%   (2 par défaut), 'Basis' (0), 'ValuationDate' et 'EndMonthRule'.
%
%   INTENVSET(COURBE,'Rates',R) modifie une courbe existante.
%   INTENVSET('Disc',F,...) part des facteurs d'actualisation plutôt que
%   des taux : les taux s'en déduisent.
%
%   Les dates de début manquantes prennent la date de valorisation, et
%   celle-ci, si elle manque, la première date de début.
%
%   Exemple :
%      c = intenvset('Rates', [0.03; 0.035], 'StartDates', '01-Jan-2024', ...
%                    'EndDates', {'01-Jan-2025'; '01-Jan-2026'});
%
%   Voir aussi INTENVGET, INTENVPRICE, INTENVSENS, BONDBYZERO.
    debut = 1;
    if ~isempty(varargin) && isstruct(varargin{1})
        courbe = varargin{1};
        debut = 2;
    else
        courbe = struct('FinObj', 'RateSpec', 'Compounding', 2, 'Disc', [], ...
                        'Rates', [], 'EndTimes', [], 'StartTimes', [], ...
                        'EndDates', [], 'StartDates', [], 'ValuationDate', [], ...
                        'Basis', 0, 'EndMonthRule', 1);
    end
    k = debut;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        valeur = varargin{k+1};
        switch nom
            case 'rates',         courbe.Rates = double(valeur(:));
            case 'disc',          courbe.Disc = double(valeur(:));
            case 'startdates',    courbe.StartDates = matlibre_dates(valeur);
            case 'enddates',      courbe.EndDates = matlibre_dates(valeur);
            case 'compounding',   courbe.Compounding = valeur;
            case 'basis',         courbe.Basis = valeur;
            case 'valuationdate', courbe.ValuationDate = matlibre_dates(valeur);
            case 'endmonthrule',  courbe.EndMonthRule = valeur;
            otherwise
                error('finstr:intenvset:Champ', ...
                      'Propriété inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    courbe = matlibre_courbe_completer(courbe);
end
