function session = addAnalogOutput(session, nom)
%ADDANALOGOUTPUT Ajoute une voie de sortie.
    session.sorties{end+1} = struct('nom', nom);
end
