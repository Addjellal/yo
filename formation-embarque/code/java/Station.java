import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Instant;
import java.util.List;
import java.util.Locale;

/** Interroge une liste de capteurs et journalise en CSV (TD 05, ex. 1). */
public class Station {
    private final List<Capteur> capteurs;
    private final Path fichier;

    public Station(List<Capteur> capteurs, Path fichier) {
        this.capteurs = List.copyOf(capteurs);   // copie défensive
        this.fichier = fichier;
    }

    /** Une ligne CSV par capteur : horodatage;nom;valeur;unite */
    public void releve() throws IOException {
        try (PrintWriter out = new PrintWriter(Files.newBufferedWriter(
                fichier, StandardOpenOption.CREATE, StandardOpenOption.APPEND))) {
            Instant t = Instant.now();
            for (Capteur c : capteurs) {
                out.printf(Locale.ROOT, "%s;%s;%.2f;%s%n",
                           t, c.getNom(), c.lire(), c.getUnite());
            }
        }   // try-with-resources : fichier fermé même en cas d'exception
    }
}
