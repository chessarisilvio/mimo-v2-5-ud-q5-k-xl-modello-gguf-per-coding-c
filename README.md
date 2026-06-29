# 📰 MiMo-V2.5-UD-Q5_K_XL: modello GGUF per coding C++

## Descrizione del progetto

Questo progetto riguarda il test e la valutazione del modello linguistico MiMo-V2.5-UD-Q5_K_XL in formato GGUF, ottimizzato per l'esecuzione su llama.cpp. Il modello è una variante Sparse Mixture-of-Experts (MoE) con 310 miliardi di parametri totali e 15 miliardi attivi, progettato per compiti di coding, in particolare la generazione di codice C++.

L'obiettivo è verificare se il modello, quantizzato con Q5_K_XL, possa essere eseguito efficacemente su una configurazione hardware locale composta da una NVIDIA Tesla P40 (24 GB VRAM) e una RTX 3050 (8 GB VRAM), per un totale di circa 30 GB di VRAM disponibile.

## Struttura del repository

- `INFO.md`: dettagli tecnici sul modello (architettura, parametri, quantizzazione, uso previsto).
- `download-mimo.sh`: script bash per il download automatico delle parti del modello da Hugging Face (repository unsloth) con verifica SHA256 tramite `checksums.txt`.
- `checksums.txt`: file contenente gli hash SHA256 attesi per ogni parte del modello.
- `test-prompts-cpp.md`: raccolta di dieci prompt di prova focalizzati su concetti di programmazione C++ (Hello World, fattoriale, somme di array, classi, quicksort, I/O, puntatori, template, ereditarietà, lambda).
- `test-coding-manuale.sh`: script interattivo per eseguire i prompt tramite llama.cpp, con configurazione variabile di GPU layers, contesto e batch size.
- `config-multigpu.md`: linee guida per la suddivisione dei layer tra P40 e RTX 3050, basate sull'analisi della VRAM disponibile.
- `calcoli-VRAM-Q5_K_XL.md`: stime dettagliate del consumo di VRAM per diverse configurazioni di offloading.
- `PROGRESS.md`: tracciamento dello stato di completamento delle fasi del progetto.
- `worker-log.txt`: log delle operazioni eseguite automaticamente dagli agenti worker.

## Come utilizzare il modello

1. **Clonare o copiare questo repository** in una directory di lavoro.
2. **Eseguire lo script di download**:
   ```bash
   ./download-mimo.sh
   ```
   Lo script individua automaticamente la directory di destinazione (preferendo `/opt/modelli-ai/` oppure `~/modelli-ai/`), crea le cartelle necessarie, scarica le parti del modello e verifica l'integrità tramite gli hash SHA256.
3. **Assicurarsi di avere llama.cpp compilato** e accessibile. Lo script di test cerca la cartella `llama.cpp` nella stessa directory oppure permette di specificarne il percorso tramite la variabile d'ambiente `LLAMA_CPP_PATH`.
4. **Eseguire i test di coding**:
   - Per testare un prompt specifico: `./test-coding-manuale.sh <numero_prompt>` (da 1 a 10).
   - Per fornire un prompt personalizzato: `./test-coding-manuale.sh "Il tuo prompt qui"`.
   - Lo script mostra i parametri di inferenza (modello, prompt, numero di layer offloadati, dimensione del contesto e batch size) prima di avviare l'esecuzione.
5. **Regolare la configurazione** in base alle proprie risorse:
   - Modificare le variabili d'ambiente `N_GPU_LAYERS`, `CTX_SIZE` e `BATCH_SIZE` per ottimizzare l'uso della VRAM.
   - Fare riferimento a `config-multigpu.md` e `calcoli-VRAM-Q5_K_XL.md` per indicazioni sullo split tra le due GPU.

## Risultati attesi

Il modello MiMo-V2.5-UD-Q5_K_XL ha dimostrato in test preliminari la capacità di generare codice C++ funzionale e coerente. L'uso della quantizzazione Q5_K_XL mira a ridurre il requisito di memoria mantenendo un buon livello di precisione, rendendo il modello eseguibile su hardware di fascia medio-alta come la combinazione P40+RTX 3050.

## Note sulla licenza e sull'uso

Il modello è distribuito tramite Hugging Face sotto la licenza originale di MiMo-V2.5. Verificare sempre i termini della licenza nel repository di origine prima di utilizzarlo per scopi commerciali. Gli script forniti in questo repository sono rilasciati sotto licenza MIT, salvo diversamente indicato.

## Contributi

Questo progetto è stato completato come parte della valutazione di modelli GGUF per coding su stack AI locale. Eventuali miglioramenti agli script o alla documentazione sono benvenuti tramite pull request.

## Aggiornamenti

L'ultimo aggiornamento risale al 29 giugno 2026, con il completamento di tutte le fasi pianificate: ricerca del modello, creazione degli script di download e test, configurazione multi-GPU e documentazione nel vault di sistema.