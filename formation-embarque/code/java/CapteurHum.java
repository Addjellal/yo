public class CapteurHum extends Capteur {
    public CapteurHum() { super("humidite", "%"); }

    @Override
    public double lire() { return 30 + Math.random() * 40; }   // simulé
}
