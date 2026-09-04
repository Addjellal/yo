function serie = totalreturnprice(prix, dividendes, datesDividendes, dates)
%TOTALRETURNPRICE Série de prix réinvestissant les dividendes.
%   S = TOTALRETURNPRICE(PRIX,DIVIDENDES,DATESDIVIDENDES,DATES) rend la
%   série qu'aurait suivie un placement qui réinvestit chaque dividende
%   dans le titre, le jour où il est versé.
%
%   Comparer deux titres sur leur seul cours fausse le jugement : celui
%   qui distribue beaucoup paraît stagner. La série de rendement total
%   corrige cela.
%
%   Exemple :
%      s = totalreturnprice(prix, [1.2 1.3], datesVersement, dates);
%
%   Voir aussi RET2TICK, TICK2RET, PRICE2RET.
    prix = double(prix(:));
    dates = matlibre_dates(dates);
    dates = dates(:);
    if numel(dates) ~= numel(prix)
        error('finance:totalreturnprice:Tailles', ...
              'Il faut une date par prix.');
    end
    dividendes = double(dividendes(:));
    datesDividendes = matlibre_dates(datesDividendes);
    datesDividendes = datesDividendes(:);
    parts = ones(size(prix));
    courant = 1;
    for k = 2:numel(prix)
        verses = dividendes(datesDividendes > dates(k - 1) & datesDividendes <= dates(k));
        if ~isempty(verses)
            % Le dividende achète des titres au cours du jour : le nombre
            % de parts augmente d'autant.
            courant = courant * (1 + sum(verses) / prix(k));
        end
        parts(k) = courant;
    end
    serie = prix .* parts;
end
