# Configurazione Multi‑GPU per llama.cpp (P40 + RTX 3050)

## Obiettivo
Distribuire i layer del modello MiMo‑V2.5‑UD‑Q5_K_XL tra una NVIDIA Tesla P40 (24 GB VRAM) e una NVIDIA RTX 3050 (8 GB VRAM) per evitare lo swap su CPU e sfruttare al meglio la VRAM totale disponibile (~30 GB).

## Prerequisiti
- llama.cpp compilato con supporto CUDA e flag `-DGGML_CUDA=on` (o equivalente).
- Driver NVIDIA ≥ 525, CUDA toolkit compatibile.
- Due GPU visibili tramite `nvidia-smi` (indici 0 e 1, o come assegnato da `CUDA_VISIBLE_DEVICES`).

## Variabili d'ambiente consigliate
```bash
# Usa l'ordine PCI per prevedibilità (vedi feedback_cuda_device_order.md)
export CUDA_DEVICE_ORDER=PCI_BUS_ID
# Assegna la P40 a cuda:0 e la 3050 a cuda:1 (modifica se necessario)
export CUDA_VISIBLE_DEVICES=0,1
```

## Flag llama.cpp per split layer
llama.cpp permette di specificare quanti layer offloadare su ciascuna GPU tramite:
- `-ngl <n>` – numero di layer da offloadare sulla GPU principale (prima dispositivo visibile).
- Per split avanzato tra più GPU, usare la variabile d'ambiente `CUDA_VISIBLE_DEVICES` insieme a `-ngl` e poi ridistribuire manualmente con `-tensor-split` (se supportato dalla build) oppure creando due istanze separate con `CUDA_VISIBLE_DEVICES` diverso e condividendo la memoria tramite offload parziale.

### Metodo semplice: offload principale + CPU
Se si vuole caricare la maggior parte dei layer sulla P40 e il resto sulla CPU (o sulla 3050 come fallback):
```bash
./main -m ./MiMo-V2.5-UD-Q5_K_XL.nguf \
       -ngl 45 \   # esempio: 45 layer sulla prima GPU (P40)
       -c 4096 \
       -b 8 \
       <altri parametri>
```
I layer rimanenti verranno processati sulla CPU (lenta). Per sfruttare anche la 3050, vedere il metodo avanzato.

### Metodo avanzato: split manuale tra due GPU
Alcune fork di llama.cpp supportano il flag `-tensor-split` che accetta una lista di percentuali o valori assoluti per ogni dispositivo. Esempio ipotetico (verificare la propria build):
```bash
./main -m ./MiMo-V2.5-UD-Q5_K_XL.gguf \
       -ngl 35 \   # base layer sulla prima GPU
       -tensor-split 0.6,0.4 \   # 60% dei rimanenti tensor su GPU0, 40% su GPU1
       -c 4096 \
       -b 8
```
Se il tuo build non supporta `-tensor-split`, puoi avviare due processi llama.cpp distinti, ciascuno con la propria `CUDA_VISIBLE_DEVICES`, e farli comunicare tramite una coda o condividere lo stesso modello usando `mmap` (richiede modifiche al codice).

## Calcolo indicativo della distribuzione layer
Vedere il file `calcoli-VRAM-Q5_K_XL.md` per i dettagli, ma una regola pratica è:

| GPU | VRAM disponibile | Layer consigliati (esempio) | VRAM stimata per layer* |
|-----|------------------|----------------------------|--------------------------|
| P40 | 24 GB            | 40‑45 layer                | ~0.4‑0.5 GB/layer        |
| 3050| 8 GB             | 25‑30 layer                | ~0.25‑0.3 GB/layer       |

\* Include pesi del layer (Q5_K_XL) + piccola quota di attivazioni/KV cache per token.

## Monitoraggio VRAM durante l'inferenza
1. **nvidia-smi** in modalità continua:
   ```bash
   watch -n 0.5 nvidia-smi
   ```
2. **Utilizzo nvtop** (se installato) per una vista più dettagliata:
   ```bash
   nvtop
   ```
3. **Strumenti di profiling integrati in llama.cpp** (se compilati con `-DGGML_CUDA_PROFILE=on`):
   - Aggiungere `--cuda-profile` all'esecuzione per vedere tempi e memoria per operazione.
4. **Script di logging** (esempio Bash):
   ```bash
   while true; do
       echo "$(date +%T) $(nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv,noheader,nounits)"
       sleep 2
   done > vram_log.csv
   ```

## Suggerimenti pratici
- Inizia con un numero conservativo di layer sulla 3050 (es. 20) e aumenta finché `nvidia-smi` mostra utilizzo vicino al limite senza superarlo.
- Se vedi errori di allocazione OOM sulla 3050, riduci `-ngl` o il valore di `-tensor-split`.
- La dimensione del batch (`-b`) e del contesto (`-c`) influiscono fortemente sulla KV cache; riduci questi valori se la VRAM si esaurisce rapidamente.
- Per testare la stabilità, esegui un carico di lavoro prolungato (es. generazione di 500 token) e osserva se l'uso di memoria rimane stabile o cresce (possibile leak).

## Riferimenti
- Documentazione ufficiale llama.cpp: https://github.com/ggerganov/llama.cpp/blob/master/docs/multi-gpu.md
- Issue e discussioni su split layer: cercare "tensor-split" nelle discussioni del repository.
- Guida pratica al multi‑GPU con llama.cpp (community blog).

---
*File generato automaticamente durante la fase 4/5 del progetto MiMo‑V2.5‑UD‑Q5_K_XL.*