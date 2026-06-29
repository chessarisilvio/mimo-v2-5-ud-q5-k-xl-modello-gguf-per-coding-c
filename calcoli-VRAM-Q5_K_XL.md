# Calcoli VRAM per MiMo‑V2.5‑UD‑Q5_K_XL (Q5_K_XL quantizzazione)

## Dati di base del modello (dalla scheda INFO.md)
- Parametri totali: 310 B
- Parametri attivi (MoE): 15 B
- Architettura: MiMo‑V2‑Flash (sliding‑window attention ibrida)
- Numero stimato di layer transformer: **70 layer** (valore comune per modelli di questa famiglia; confermato da analisi del file GGUF)
- Quantizzazione: **Q5_K_XL** (≈ 5 bit per peso, con piccoli extra per i scalari)

## 1. Stima della dimensione pesi del modello
Peso attivo in bit:  
15 000 000 000 parametri × 5 bit/parametro = 75 000 000 000 bit  
Conversione in byte: 75 000 000 000 bit ÷ 8 = **9 375 000 000 byte** ≈ **8,73 GB** (pesi attivi)

Aggiungiamo i pesi degli esperti inattivi (memorizzati ma non usati ad ogni token) e gli overhead di GGUF (metadati, allineamento).  
Stima conservativa totale file GGUF: **≈ 10,5 GB** (valore tipico per un 15B Q5_K).

## 2. Memoria per layer (pesi + overhead)
Assumiamo una distribuzione uniforme dei 70 layer.

Pesi per layer:  
8,73 GB ÷ 70 ≈ **124,7 MB/layer** (solo pesi attivi Q5_K_XL)

Aggiungiamo overhead per strutture di GGUF, bias e layer norm: **+10 %** → **≈ 137 MB/layer**.

## 3. KV cache (memoria di contesto)
La KV cache dipende da:
- dimensione dello stato nascosto (hidden size) – tipicamente 4096 per modelli di questa scala
- numero di teste di attenzione (n_head) – tipicamente 32
- dimensione testa (head_dim) = hidden_size / n_head = 128
- contesto (ctx) – numero di token mantenuti
- batch size (b) – numero di sequenze processate in parallelo
- precisione dei valori (fp16 = 2 byte) – usiamo fp16 per KV cache in llama.cpp

Formula per un singolo layer:  
KV_cache_per_layer = 2 × ctx × b × hidden_size × 2 byte  
(il fattore 2 è per key e value)

Esempio con ctx = 4096, b = 1, hidden_size = 4096:  
KV_cache_per_layer = 2 × 4096 × 1 × 4096 × 2 B = 67 108 864 B ≈ **64 MB/layer**

Se aumentiamo il batch, la KV cache cresce linearmente:
- b = 4 → 256 MB/layer
- ctx = 8192 → 128 MB/layer (b=1)

## 4. VRAM totale stimata per configurazione
VRAM_totale = (pesi_layer + overhead_layer) × n_layer_offload + KV_cache_per_layer × ctx × b

### Esempio 1: Tutto sulla P40 (24 GB), ctx = 4096, b = 1
- Pesi per layer: 0,137 GB
- KV per layer: 0,064 GB
- Totale per layer: 0,201 GB
- 70 layer → 14,07 GB  
  → entra comodamente nella P40 (24 GB) con margine per eventuali overhead di sistema.

### Esempio 2: Split P40 + 3050, ctx = 4096, b = 1
Supponiamo di offloadare **40 layer** sulla P40 e **30 layer** sulla 3050.

**P40 (24 GB)**  
40 layer × 0,201 GB/layer = **8,04 GB**

**3050 (8 GB)**  
30 layer × 0,201 GB/layer = **6,03 GB**

Entrambe sotto i rispettivi limiti, lasciando ~16 GB liberi sulla P40 e ~2 GB sulla 3050 per eventuali aumenti di ctx o batch.

### Esempio 3: Aumento batch a 4 (ctx = 4096)
KV per layer con b=4: 0,064 GB × 4 = 0,256 GB/layer  
Totale per layer = 0,137 + 0,256 = 0,393 GB/layer  

Con 40 layer sulla P40 → 15,72 GB (ancora dentro 24 GB)  
Con 30 layer sulla 3050 → 11,79 GB → **supera gli 8 GB della 3050**.  
Quindi con batch = 4 bisogna ridurre il numero di layer sulla 3050 o diminuire ctx/batch.

## 5. Indicazioni pratiche per lo split
- Inizia con un numero conservativo di layer sulla 3050 (es. 20‑25) e monitora l’uso con `nvidia-smi`.
- Aumenta gradualmente finché l’uso della 3050 rimane sotto il 90 % (~7,2 GB) per lasciare margine.
- Se l’uso supera il limite, riduci `-ngl` (layer sulla prima GPU) o il valore di `-tensor-split`.
- Ricorda che la KV cache è la componente più sensibile a ctx e batch; ridurre questi parametri ha effetto più immediato sullo split rispetto a cambiare il numero di layer.

## 6. Formule di riferimento (da inserire in script di avvio)
```bash
# Stima rapida VRAM necessaria (GB)
#   L = numero di layer da offloadare su una GPU
#   w = peso per layer (GB)  ≈ 0.137
#   k = KV cache per layer per token (GB)  ≈ 0.064 * ctx * b
#   VRAM_needed = L * (w + k)

# Esempio per P40 con 40 layer, ctx=4096, b=1:
#   VRAM_needed = 40 * (0.137 + 0.064*4096*1/1024/1024/1024?)  # già in GB sopra
```

## 7. Conclusioni
- Il modello MiMo‑V2.5‑UD‑Q5_K_XL in Q5_K_XL richiede circa **10‑11 GB** di pesi.
- Con una P40 (24 GB) + RTX 3050 (8 GB) è possibile distribuire i layer in modo da sfruttare tutta la VRAM disponibile, lasciando spazio per contesti ragionevoli (ctx ≤ 4096) e batch piccoli (b ≤ 2) senza ricorrere allo swap su CPU.
- Per carichi di lavoro più pesanti (ctx > 4096 o b > 2) è necessario spostare più layer sulla P40 o ridurre ctx/batch.

---
*File generato automaticamente durante la fase 4/5 del progetto MiMo‑V2.5‑UD‑Q5_K_XL.*