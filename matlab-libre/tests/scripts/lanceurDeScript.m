function r = lanceurDeScript(parNom)
%LANCEURDESCRIPT Lance scriptQuiRend, puis rend 42 s'il a repris la main.
    if parNom
        scriptQuiRend;
    else
        run('scriptQuiRend');
    end
    r = 42;
end
