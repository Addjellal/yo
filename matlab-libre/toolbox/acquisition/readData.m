function [donnees, temps] = readData(session, nEchantillons)
%READDATA Lit un bloc d'échantillons sur toutes les voies d'entrée.
%   [DONNEES,TEMPS] = READDATA(SESSION,N) rend N échantillons : une ligne
%   par instant, une colonne par voie, et le vecteur des instants.
%
%   Le pas d'échantillonnage est l'inverse de la fréquence de la session :
%   c'est la seule chose que la fréquence veut dire. N échantillons
%   couvrent donc (N-1)/frequence secondes, non N/frequence — l'erreur
%   d'un pas est la plus fréquente du domaine.
%
%   Échantillonner à moins du double de la fréquence du signal ne le
%   dégrade pas : il le remplace par un autre, de fréquence |f - k fe|.
%   C'est le repliement, et aucun traitement postérieur ne le défait.
%
%   Exemple :
%      [donnees, temps] = readData(s, 1000);
%      1 / diff(temps(1:2))            % la frequence d'echantillonnage
%
%   Voir aussi DAQ, ADDANALOGINPUT, WRITEDATA.
    temps = (0:nEchantillons-1).' / session.frequence;
    donnees = zeros(nEchantillons, numel(session.entrees));
    for k = 1:numel(session.entrees)
        g = session.entrees{k}.generateur;
        for i = 1:nEchantillons
            donnees(i, k) = g(temps(i));
        end
    end
end
