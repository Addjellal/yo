function [largeur, debut, fin] = pulsewidth(x, fs, varargin)
%PULSEWIDTH Largeur des impulsions à mi-hauteur.
%   W = PULSEWIDTH(X,FS) rend la durée entre le front montant et le front
%   descendant qui le suit, mesurée au niveau médian.
%
%   PULSEWIDTH(...,'Polarity','negative') mesure les creux.
    if nargin < 2 || isempty(fs), fs = 1; end
    positive = true;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'Polarity')
            positive = ~strcmpi(char(varargin{k + 1}), 'negative');
        end
    end
    [instants, ~] = midcross(x, fs);
    [~, montantes] = signalTraverses(double(x(:)), (0:numel(x)-1)'/fs, milieuDe(x));
    debut = [];
    fin = [];
    for k = 1:numel(instants) - 1
        if montantes(k) == positive && montantes(k + 1) ~= positive
            debut(end + 1, 1) = instants(k);      %#ok<AGROW>
            fin(end + 1, 1) = instants(k + 1);    %#ok<AGROW>
        end
    end
    largeur = fin - debut;
end

function m = milieuDe(x)
    [~, ~, m] = signalNiveaux(double(x(:)), 50);
end
