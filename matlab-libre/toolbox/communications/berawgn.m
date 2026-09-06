function ber = berawgn(EbNodB, methode, M, codage)
%BERAWGN Taux d'erreur binaire théorique sur canal gaussien.
%   BER = BERAWGN(EBNO,METHODE,M) rend le taux d'erreur binaire d'une
%   modulation à M états sur un canal à bruit blanc gaussien additif, pour
%   les rapports EBNO donnés en décibels. EBNO est l'énergie par bit
%   rapportée à la densité spectrale de bruit, non le rapport signal sur
%   bruit : c'est ce qui rend les modulations comparables entre elles à
%   débit binaire égal.
%
%   METHODE vaut 'psk', 'dpsk', 'qam', 'pam' ou 'fsk'.
%
%   BER = BERAWGN(EBNO,'psk',M,CODAGE) tient compte du codage
%   différentiel : CODAGE vaut 'nondiff' (par défaut) ou 'diff'.
%   BER = BERAWGN(EBNO,'fsk',M,COHERENCE) où COHERENCE vaut 'coherent'
%   (par défaut) ou 'noncoherent'.
%
%   Les formules supposent un codage de Gray, qui fait différer d'un seul
%   bit deux points voisins de la constellation : c'est ce qui permet de
%   diviser le taux d'erreur symbole par le nombre de bits. Sans lui, une
%   erreur entre voisins peut faire basculer tous les bits d'un coup.
%
%   Le codage différentiel double à peu près le taux d'erreur, et coûte
%   donc de l'ordre du demi-décibel : chaque symbole reçu sert de
%   référence au suivant, si bien qu'une détection fausse en gâte deux.
%   C'est le prix de n'avoir pas à récupérer la phase de la porteuse.
%
%   La détection non cohérente en fréquence coûte davantage — environ un
%   décibel à taux courant, et sa courbe décroît en exponentielle et non
%   en fonction d'erreur complémentaire.
%
%   Ces courbes sont la référence à laquelle se compare une chaîne
%   réelle : l'écart horizontal entre la courbe mesurée et celle-ci est
%   exactement ce que coûte la mise en oeuvre.
%
%   Exemple :
%      berawgn(0:2:10, 'psk', 2)              % decroit tres vite
%      berawgn(10, 'psk', 2, 'diff') > berawgn(10, 'psk', 2)   % 1
%      berawgn(10, 'qam', 16) > berawgn(10, 'psk', 2)          % 1
%
%   Voir aussi BERCODING, BITERR, SYMERR, AWGN.
    if nargin < 2, methode = 'psk'; end
    if nargin < 3, M = 2; end
    if nargin < 4, codage = ''; end
    EbNo = 10 .^ (EbNodB / 10);
    k = log2(M);
    % Q(x), la queue de la loi normale reduite, dans laquelle toutes ces
    % formules s'ecrivent : Q(x) = erfc(x/sqrt(2))/2.
    Q = @(x) 0.5 * erfc(x / sqrt(2));
    switch lower(char(methode))
        case 'psk'
            if M == 2
                ber = Q(sqrt(2 * EbNo));
            else
                ber = 2 * Q(sqrt(2 * k * EbNo) * sin(pi / M)) / k;
            end
            if strcmpi(char(codage), 'diff')
                % Le decodeur differentiel declare une erreur des qu'une
                % des deux detections successives est fausse : les erreurs
                % isolees se comptent double, celles qui se suivent
                % s'annulent.
                ber = 2 * ber .* (1 - ber);
            end
        case 'dpsk'
            if M == 2
                ber = 0.5 * exp(-EbNo);
            else
                ber = 2 * Q(sqrt(2 * k * EbNo) * sin(pi / (2 * M))) / k;
            end
        case 'qam'
            ber = 4 * (1 - 1 / sqrt(M)) * Q(sqrt(3 * k * EbNo / (M - 1))) / k;
        case 'pam'
            ber = 2 * (1 - 1 / M) * Q(sqrt(6 * k * EbNo / (M ^ 2 - 1))) / k;
        case 'fsk'
            if strcmpi(char(codage), 'noncoherent')
                ber = 0.5 * exp(-EbNo / 2);
            else
                ber = Q(sqrt(EbNo));
            end
            if M > 2
                % M tons orthogonaux : la borne de l'union, resserree par
                % le rapport habituel entre erreur symbole et erreur bit.
                ser = min(1, (M - 1) * Q(sqrt(k * EbNo)));
                ber = ser * M / (2 * (M - 1));
            end
        otherwise
            error('comm:berawgn:unknown', ...
                  'Modulation inconnue : %s.', char(methode));
    end
end
