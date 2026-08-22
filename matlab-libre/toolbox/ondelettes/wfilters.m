function [Lo_D, Hi_D, Lo_R, Hi_R] = wfilters(nom)
%WFILTERS Bancs de filtres d'analyse et de synthèse.
%   [LO_D,HI_D,LO_R,HI_R] = WFILTERS(NOM) où NOM vaut 'haar', 'db2',
%   'db4' ou 'sym2'.
    switch lower(char(nom))
        case {'haar', 'db1'}
            Lo_R = [1 1] / sqrt(2);
        case 'db2'
            s = sqrt(3);
            Lo_R = [1+s, 3+s, 3-s, 1-s] / (4 * sqrt(2));
        case 'db4'
            Lo_R = [0.230377813309, 0.714846570553, 0.630880767930, ...
                    -0.027983769417, -0.187034811719, 0.030841381836, ...
                    0.032883011667, -0.010597401785];
            Lo_R = Lo_R / norm(Lo_R) * sqrt(2) / sqrt(2);
        case 'sym2'
            s = sqrt(3);
            Lo_R = [1+s, 3+s, 3-s, 1-s] / (4 * sqrt(2));
        otherwise
            error('wavelet:wfilters:unknown', 'Unknown wavelet ''%s''.', nom);
    end
    % Relations du banc de filtres à reconstruction parfaite :
    %   Lo_D[n] = Lo_R[N-1-n]      (analyse passe-bas = synthèse renversée)
    %   Hi_D[n] = (-1)^n Lo_R[n]   (miroir en quadrature)
    %   Hi_R[n] = Hi_D[N-1-n]
    n = numel(Lo_R);
    Lo_D = Lo_R(end:-1:1);
    Hi_D = Lo_R .* (-1) .^ (0:n-1);
    Hi_R = Hi_D(end:-1:1);
end
