/* Mini-TP STM32 — PWM 20 kHz pilote par potentiometre (cours 10 §4.3)
 * Blocs a coller entre les balises USER CODE d'un projet CubeMX
 * (TIM2 CH1 = PA0 en PWM ; ADC1 IN0 si potentiometre disponible).
 * Complete les 3 trous avec TES calculs de la partie 1 du README.
 */

/* ==== Dans CubeMX (pas du code !) : TIM2 -> Channel 1 : PWM Generation.
 * A COMPLETER (1) : renseigner dans l'onglet Parameter Settings :
 *   Prescaler (PSC)  = ____   <- calcul n°1 du README (PWM 20 kHz)
 *   Counter Period   = 999    (ARR, deja impose)
 * puis regenerer le code.                                              */

/* USER CODE BEGIN 2 */
/* A COMPLETER (2) : demarrer le PWM sur TIM2 canal 1 (une ligne HAL).
 * Indice : HAL_TIM_PWM_Start(&htim2, ...);                             */


HAL_ADC_Start(&hadc1);
/* USER CODE END 2 */

/* USER CODE BEGIN WHILE */
while (1)
{
    /* Lecture du potentiometre : 0..4095 (12 bits) */
    HAL_ADC_PollForConversion(&hadc1, 10);
    uint16_t pot = (uint16_t)HAL_ADC_GetValue(&hadc1);
    HAL_ADC_Start(&hadc1);

    /* A COMPLETER (3) : convertir pot (0..4095) en rapport cyclique
     * (0..ARR, soit 0..999) et l'ecrire dans le registre de comparaison.
     * Indice : __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_1, ...);
     * Conversion simple : (pot * 1000UL) / 4096                        */


    HAL_Delay(20);   /* tolere ici : ne cadence que la lecture du pot */
    /* USER CODE END WHILE */
}
