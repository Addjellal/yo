import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Optional;

/** Tests des corrigés du TD 05 (hors ProdCons, qui a son propre main).
 *  `make test` doit afficher 3 OK. */
public class TestTout {
    static void verifier(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }

    static void testDecodeur() {
        byte[] ok = {(byte) 0xA5, 0x07, (byte) 0x01, (byte) 0xF4};  // 500
        Optional<DecodeurTrame.TrameMesure> r = DecodeurTrame.decoder(ok);
        verifier(r.isPresent(), "trame valide rejetee (piege du byte signe ?)");
        verifier(r.get().id() == 7, "id incorrect");
        verifier(r.get().valeur() == 500, "valeur incorrecte");

        verifier(DecodeurTrame.decoder(
                new byte[]{0x55, 0x07, 0, 0}).isEmpty(), "mauvaise tete acceptee");
        verifier(DecodeurTrame.decoder(new byte[2]).isEmpty(), "longueur acceptee");
        verifier(DecodeurTrame.decoder(null).isEmpty(), "null accepte");
        System.out.println("OK  decodeur de trame");
    }

    static void testStation() throws IOException {
        Path csv = Files.createTempFile("mesures", ".csv");
        Station station = new Station(
                List.of(new CapteurTemp(), new CapteurHum()), csv);
        station.releve();
        station.releve();

        List<String> lignes = Files.readAllLines(csv);
        verifier(lignes.size() == 4, "attendu 4 lignes (2 releves x 2 capteurs)");
        verifier(lignes.get(0).split(";").length == 4, "format CSV incorrect");
        verifier(lignes.get(0).contains("temperature"), "capteur manquant");
        Files.deleteIfExists(csv);
        System.out.println("OK  station -> CSV");
    }

    static void testPolymorphisme() {
        // Station ne connait que Capteur : un nouveau capteur s'ajoute
        // sans toucher a Station.
        Capteur anonyme = new Capteur("pression", "hPa") {
            @Override public double lire() { return 1013.25; }
        };
        verifier(anonyme.lire() == 1013.25, "capteur anonyme");
        verifier(anonyme.getUnite().equals("hPa"), "unite");
        System.out.println("OK  polymorphisme");
    }

    public static void main(String[] args) throws IOException {
        testDecodeur();
        testStation();
        testPolymorphisme();
        System.out.println("---- tous les tests Java passent ----");
    }
}
