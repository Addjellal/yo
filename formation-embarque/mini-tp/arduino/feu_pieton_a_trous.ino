// Mini-TP Arduino — feu pieton SANS delay() (cours 03 §5)
// Plateforme : https://wokwi.com (Arduino Uno)
// Cablage : LED rouge D10, LED verte D9 (resistances 220R), bouton D2->GND.
// Complete les 4 trous. Comportement attendu : voir README du dossier.

const uint8_t LED_ROUGE = 10;
const uint8_t LED_VERTE = 9;
const uint8_t BOUTON    = 2;

enum class Etat : uint8_t { ROUGE, VERT };
Etat etat = Etat::ROUGE;

uint32_t t_entree = 0;        // horodatage d'entree dans l'etat courant
bool demande = false;         // appui pieton memorise

const uint32_t DUREE_VERT_MS = 5000;

void setup() {
  Serial.begin(115200);

  // A COMPLETER (1) : les deux LED en OUTPUT, le bouton en INPUT_PULLUP


  digitalWrite(LED_ROUGE, HIGH);      // etat de depart : rouge
  Serial.println("etat=ROUGE");
}

void loop() {
  uint32_t maintenant = millis();

  // --- lecture du bouton (pull-up : appuye == LOW) --------------------
  // A COMPLETER (2) : si le bouton est appuye, mettre  demande = true;
  //                   (une seule condition if, pas de delay)


  // --- machine d'etats ------------------------------------------------
  switch (etat) {
    case Etat::ROUGE:
      if (demande) {
        etat = Etat::VERT;
        t_entree = maintenant;
        // A COMPLETER (3) : eteindre rouge, allumer vert,
        //                   et REMETTRE demande a false (servie !)


        Serial.println("etat=VERT");
      }
      break;

    case Etat::VERT:
      // A COMPLETER (4) : apres DUREE_VERT_MS dans l'etat, repasser
      //   au ROUGE (LED + etat + trace serie). Utiliser la soustraction
      //   maintenant - t_entree (robuste au debordement de millis).
      //   Remettre AUSSI demande a false : les appuis faits pendant le
      //   vert sont consideres comme deja servis.




      break;
  }
}
