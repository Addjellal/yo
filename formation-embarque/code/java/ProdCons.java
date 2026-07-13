import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;

/** Producteur/consommateur avec arrêt propre — corrigé TD 05, exercice 2.
 *  Lancer : java ProdCons  (tourne ~3 s puis s'arrête proprement). */
public class ProdCons {
    record Mesure(String capteur, double valeur, long horodatageMs) {}

    public static void main(String[] args) throws InterruptedException {
        // File BORNÉE : contre-pression si le consommateur décroche.
        BlockingQueue<Mesure> file = new ArrayBlockingQueue<>(64);

        Thread producteur = new Thread(() -> {
            try {
                while (!Thread.currentThread().isInterrupted()) {
                    file.put(new Mesure("temp", 18 + Math.random() * 10,
                                        System.currentTimeMillis()));
                    Thread.sleep(200);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();   // restaurer le drapeau
            }
        }, "acquisition");

        Thread consommateur = new Thread(() -> {
            try {
                while (!Thread.currentThread().isInterrupted()) {
                    Mesure m = file.poll(500, TimeUnit.MILLISECONDS);
                    if (m != null)
                        System.out.printf("traite : %s = %.1f%n",
                                          m.capteur(), m.valeur());
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "traitement");

        producteur.start();
        consommateur.start();

        Thread.sleep(3000);
        producteur.interrupt();          // arrêt PROPRE
        consommateur.interrupt();
        producteur.join();
        consommateur.join();
        System.out.println("arret propre, file restante = " + file.size());
    }
}
