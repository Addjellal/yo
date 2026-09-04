function varargout = optstocksensbybls(courbe, actif, reglement, echeance, typeOption, exercice, sorties)
%OPTSTOCKSENSBYBLS Sensibilités d'options européennes sur action.
%   S = OPTSTOCKSENSBYBLS(...,SORTIES) rend les grandeurs demandées.
%   SORTIES est un tableau de cellules parmi 'Price', 'Delta', 'Gamma',
%   'Vega', 'Lambda', 'Rho', 'Theta' ; par défaut, le prix seul.
%
%   Exemple :
%      optstocksensbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 95, ...
%                        {'Price', 'Delta', 'Gamma'})
%
%   Voir aussi OPTSTOCKBYBLS, BLSDELTA, BLSGAMMA, BLSVEGA.
    if nargin < 7 || isempty(sorties)
        sorties = {'Price'};
    end
    if ischar(sorties) || isstring(sorties)
        sorties = {char(sorties)};
    end
    [prix, parametres] = matlibre_options_actions(courbe, actif, reglement, ...
                                                  echeance, typeOption, exercice);
    for j = 1:numel(sorties)
        valeurs = zeros(numel(prix), 1);
        for k = 1:numel(prix)
            p = parametres{k};
            achat = ~strcmp(p.type, 'put');
            switch lower(char(sorties{j}))
                case 'price'
                    valeurs(k) = prix(k);
                case 'delta'
                    [dc, dp] = blsdelta(p.S, p.K, p.r, p.T, p.sigma, p.q);
                    valeurs(k) = choisir(achat, dc, dp);
                case 'gamma'
                    valeurs(k) = blsgamma(p.S, p.K, p.r, p.T, p.sigma, p.q);
                case 'vega'
                    valeurs(k) = blsvega(p.S, p.K, p.r, p.T, p.sigma, p.q);
                case 'lambda'
                    [lc, lp] = blslambda(p.S, p.K, p.r, p.T, p.sigma, p.q);
                    valeurs(k) = choisir(achat, lc, lp);
                case 'rho'
                    [rc, rp] = blsrho(p.S, p.K, p.r, p.T, p.sigma, p.q);
                    valeurs(k) = choisir(achat, rc, rp);
                case 'theta'
                    [tc, tp] = blstheta(p.S, p.K, p.r, p.T, p.sigma, p.q);
                    valeurs(k) = choisir(achat, tc, tp);
                otherwise
                    error('finstr:optstocksens:Sortie', ...
                          'Grandeur inconnue : %s.', char(sorties{j}));
            end
        end
        varargout{j} = valeurs;   %#ok<AGROW>
    end
end

function v = choisir(achat, valeurAchat, valeurVente)
    if achat
        v = valeurAchat;
    else
        v = valeurVente;
    end
end
