function y = convertSNR(x, depuis, vers, varargin)
%CONVERTSNR Conversion entre les trois mesures de rapport signal sur bruit.
%   Y = CONVERTSNR(X,DEPUIS,VERS) convertit entre 'snr', 'ebno' et
%   'esno', tous en décibels. Les relations sont
%
%      EsNo = EbNo + 10 log10(k R)
%      SNR  = EsNo - 10 log10(NSAMP)
%
%   où k est le nombre de bits par symbole, R le rendement du codage et
%   NSAMP le nombre d'échantillons par symbole.
%
%   Y = CONVERTSNR(...,'BitsPerSymbol',K,'SamplesPerSymbol',NSAMP,
%   'CodingRate',R) fixe ces trois paramètres, qui valent par défaut 1, 1
%   et 1.
%
%   Exemple :
%      convertSNR(10, 'ebno', 'snr', 'BitsPerSymbol', 4)   % 16.0206
%
%   Voir aussi AWGN, BERAWGN.
    bitsParSymbole = 1;
    echantillonsParSymbole = 1;
    rendement = 1;
    for k = 1:2:numel(varargin)
        if k + 1 > numel(varargin)
            error('comm:convertSNR:PairAttendue', 'Les options vont par paires.');
        end
        switch lower(char(varargin{k}))
            case 'bitspersymbol'
                bitsParSymbole = double(varargin{k + 1});
            case 'samplespersymbol'
                echantillonsParSymbole = double(varargin{k + 1});
            case 'codingrate'
                rendement = double(varargin{k + 1});
            otherwise
                error('comm:convertSNR:OptionInconnue', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    % Tout passe par EsNo, qui sert de pivot.
    esno = versEsNo(double(x), depuis, bitsParSymbole, echantillonsParSymbole, rendement);
    y = depuisEsNo(esno, vers, bitsParSymbole, echantillonsParSymbole, rendement);
end

function esno = versEsNo(x, depuis, k, nsamp, R)
    switch lower(char(depuis))
        case 'esno'
            esno = x;
        case 'ebno'
            esno = x + 10 * log10(k * R);
        case 'snr'
            esno = x + 10 * log10(nsamp);
        otherwise
            error('comm:convertSNR:BadUnit', ...
                  'L''unité doit être ''snr'', ''ebno'' ou ''esno''.');
    end
end

function y = depuisEsNo(esno, vers, k, nsamp, R)
    switch lower(char(vers))
        case 'esno'
            y = esno;
        case 'ebno'
            y = esno - 10 * log10(k * R);
        case 'snr'
            y = esno - 10 * log10(nsamp);
        otherwise
            error('comm:convertSNR:BadUnit', ...
                  'L''unité doit être ''snr'', ''ebno'' ou ''esno''.');
    end
end
