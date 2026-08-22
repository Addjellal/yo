function [reponse, instrument] = query(instrument, commande)
%QUERY Envoie une commande puis lit la réponse.
    instrument = writeline(instrument, commande);
    reponse = readline(instrument);
end
