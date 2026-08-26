function instrument = visadev(adresse)
%VISADEV Ouvre une liaison vers un instrument simulé.
    instrument = struct();
    instrument.adresse = adresse;
    instrument.journal = {};
    instrument.derniereReponse = '';
end
