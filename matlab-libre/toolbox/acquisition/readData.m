function [donnees, temps] = readData(session, nEchantillons)
%READDATA Lit un bloc d'échantillons sur toutes les voies d'entrée.
    temps = (0:nEchantillons-1).' / session.frequence;
    donnees = zeros(nEchantillons, numel(session.entrees));
    for k = 1:numel(session.entrees)
        g = session.entrees{k}.generateur;
        for i = 1:nEchantillons
            donnees(i, k) = g(temps(i));
        end
    end
end
