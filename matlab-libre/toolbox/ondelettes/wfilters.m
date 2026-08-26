function [Lo_D, Hi_D, Lo_R, Hi_R] = wfilters(nom, genre)
%WFILTERS Bancs de filtres d'analyse et de synthèse.
%   [LO_D,HI_D,LO_R,HI_R] = WFILTERS(NOM) où NOM vaut 'haar', 'dbN' ou
%   'symN'. Les coefficients ne sont pas recopiés d'une table : ils sont
%   construits par factorisation spectrale du polynôme de Daubechies, ce
%   qui les rend disponibles à n'importe quel ordre. L'orthogonalité du
%   banc reste au niveau de la précision machine jusqu'à db20 environ, et
%   meilleure que 1e-9 jusqu'à db45.
%
%   WFILTERS(NOM,'d') ne rend que les filtres d'analyse, 'r' que ceux de
%   synthèse, 'l' les passe-bas, 'h' les passe-haut ; les deux sorties
%   demandées sont alors les deux premières.
%
%   Exemple :
%      [lod, hid, lor, hir] = wfilters('db4');
%      [lod, hid] = wfilters('db4', 'd');
%
%   Voir aussi DWT, WAVEDEC, ORTHFILT.
    nom = lower(char(nom));
    if strcmp(nom, 'haar')
        nom = 'db1';
    end
    if numel(nom) > 2 && strcmp(nom(1:2), 'db')
        ordre = str2double(nom(3:end));
        if isnan(ordre) || ordre < 1
            error('wavelet:wfilters:unknown', 'Unknown wavelet ''%s''.', nom);
        end
        Lo_R = daubechiesFiltre(ordre);
    elseif numel(nom) > 3 && strcmp(nom(1:3), 'sym')
        ordre = str2double(nom(4:end));
        if isnan(ordre) || ordre < 1
            error('wavelet:wfilters:unknown', 'Unknown wavelet ''%s''.', nom);
        end
        Lo_R = daubechiesFiltre(ordre, 'symetrique');
    else
        error('wavelet:wfilters:unknown', 'Unknown wavelet ''%s''.', nom);
    end
    % Relations du banc de filtres à reconstruction parfaite :
    %   Lo_D[n] = Lo_R[N+1-n]      (analyse passe-bas = synthèse renversée)
    %   Hi_D[n] = (-1)^n Lo_R[n]   (miroir en quadrature, n compté depuis 1)
    %   Hi_R[n] = Hi_D[N+1-n]
    % Le signe est celui de MATLAB : wfilters('db2') rend bien
    %   Hi_D = [-0.4830 0.8365 -0.2241 -0.1294].
    n = numel(Lo_R);
    Lo_D = Lo_R(end:-1:1);
    Hi_D = Lo_R .* (-1) .^ (1:n);
    Hi_R = Hi_D(end:-1:1);
    if nargin >= 2 && ~isempty(genre)
        % Les deux filtres demandés sortent par les deux premiers
        % arguments, comme dans MATLAB.
        switch lower(char(genre))
            case 'd'
                % Analyse : Lo_D et Hi_D sont déjà en place.
            case 'r'
                Lo_D = Lo_R;
                Hi_D = Hi_R;
            case 'l'
                % Passe-bas : analyse puis synthèse.
                Hi_D = Lo_R;
            case 'h'
                % Passe-haut : analyse puis synthèse.
                Lo_D = Hi_D;
                Hi_D = Hi_R;
            otherwise
                error('wavelet:wfilters:BadType', ...
                      'Le type doit être ''d'', ''r'', ''l'' ou ''h''.');
        end
    end
end
