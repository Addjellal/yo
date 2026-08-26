function session = daq(fournisseur)
%DAQ Crée une session d'acquisition simulée.
    if nargin < 1
        fournisseur = 'simule';
    end
    session = struct();
    session.fournisseur = fournisseur;
    session.frequence = 1000;
    session.entrees = {};
    session.sorties = {};
    session.ecrit = [];
end
