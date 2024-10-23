const byte adcPin = 0;              // A0  <=  ATMega 2560 A0 pin for ADC0

const int MAX_RESULTS = 2560;       // size for store data to be sent
int VALOR_AD = 0;
float tensao = 0;
volatile int results[MAX_RESULTS]; // data vector
volatile int resultNumber = 0;      // Inicializar resultNumber

// ADC complete ISR
ISR(ADC_vect)
{
    if (resultNumber < MAX_RESULTS) {
        results[resultNumber++] = ADC;
    } else {
        ADCSRA &= ~(1 << ADIE);  // Desativa a interrupção do ADC
    }
}  // end of ADC_vect

EMPTY_INTERRUPT(TIMER1_COMPB_vect);

// ADC configure initialization
void ADC_init() {
    ADCSRA = bit(ADEN) | bit(ADIE);   // turn ADC on, want interrupt on completion
    ADCSRA |= bit(ADPS2);  // Prescaler of 16
    ADMUX = bit(REFS0) | (adcPin & 7); // Set Voltage reference to Avcc (5v)
    ADCSRB = bit(ADTS0) | bit(ADTS2);  // Timer/Counter1 Compare Match B
    ADCSRA |= bit(ADATE);   // turn on automatic triggering
}

// Timer sampling configure
void timer() {
    // reset Timer 1
    TCCR1A = 0;
    TCCR1B = 0;
    TCNT1 = 0;
    TCCR1B = bit(CS11) | bit(WGM12);  // CTC, prescaler of 8
    TIMSK1 = bit(OCIE1B);  // Output Compare B Match Interrupt Enable
    OCR1A = 39;    // Prescaler of 8 (16MHz / 8 = 2MHz, para 50kHz, OCR1A = 39)
    OCR1B = 39;    // 50kHz sampling frequency
}

// Função para gerar a onda senoidal
float generateSineWave(float time, float frequency, float amplitude, float offset) {
    return amplitude * sin(2.0 * PI * frequency * time) + offset;
}

// Setup and run
void setup() {
    Serial.begin(2000000);
    Serial.println();

    timer();
    ADC_init();

    float frequency = 1000; // 1kHz
    float amplitude = 2.5; // 5Vpp => 2.5V amplitude
    float offset = 2.5;    // Offset de 2.5V para manter a onda entre 0 e 5V

    // Gerar a onda senoidal e enviar para o Serial
    for (int i = 0; i < MAX_RESULTS; i++) {
        float time = i * (1.0 / 50000.0);  // assumindo 50kHz de taxa de amostragem
        float sineValue = generateSineWave(time, frequency, amplitude, offset);
        Serial.println(sineValue * 1023 / 5);  // Ajuste para 10 bits ADC (0 a 1023)
    }
}

void loop() {
  VALOR_AD = analogRead(adcPin);
  tensao = (VALOR_AD*5.0)/1023.0;

  Serial.println(" A/D = ");
  Serial.println(VALOR_AD);
  Serial.println("\n");
  Serial.println(" Tensao = ");
  Serial.println(tensao);
  Serial.println("V"      );
  Serial.println("\n");
  delay(1000);
}
