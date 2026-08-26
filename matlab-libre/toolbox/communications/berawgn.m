function ber = berawgn(EbNodB, methode, M)
%BERAWGN Taux d'erreur binaire théorique sur canal gaussien.
%   BER = BERAWGN(EBNO,'psk',M) ou BERAWGN(EBNO,'qam',M).
    if nargin < 2, methode = 'psk'; end
    if nargin < 3, M = 2; end
    EbNo = 10 .^ (EbNodB / 10);
    k = log2(M);
    switch lower(char(methode))
        case 'psk'
            if M == 2
                ber = 0.5 * erfc(sqrt(EbNo));
            else
                ber = erfc(sqrt(k * EbNo) * sin(pi / M)) / k;
            end
        case 'qam'
            ber = 2 * (1 - 1/sqrt(M)) / k * erfc(sqrt(3 * k * EbNo / (2 * (M - 1))));
        otherwise
            error('comm:berawgn:unknown', 'Unknown modulation.');
    end
end
