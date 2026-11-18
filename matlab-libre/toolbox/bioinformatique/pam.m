function [matrice, info] = pam(distance, varargin)
%PAM Matrice de substitution PAM des acides aminés (Dayhoff, 1978).
%   M = PAM(250) rend la matrice PAM 250, en tiers de bit, dans l'ordre
%   ARNDCQEGHILKMFPSTWYVBZX*. [M,INFO] = PAM(250) rend aussi sa fiche.
%   Les options 'Extended' et 'Order' sont celles de BLOSUM.
%
%   Seule PAM 250, la plus employée, est fournie ; une autre distance
%   évolutive est refusée plutôt qu'approchée.
%
%   Exemple :
%      M = pam(250);
%      M(19, 19)            % 10 : Y contre Y
%
%   Voir aussi BLOSUM, NUC44, NWALIGN.
    if ~isnumeric(distance) || ~isscalar(distance) || distance ~= 250
        error('bioinfo:pam:Distance', ...
              'PAM %s n''est pas fournie : MatLibre n''a que PAM 250.', num2str(distance));
    end
    [matrice, info] = matlibre_info_matrice('PAM250', varargin, 'pam');
end
