# SPI LED Control – FPGA (SystemVerilog)

Projeto completo para controlar LEDs via **SPI** em FPGA (modo SPI **CPOL=1/CPHA=1**, modo 3), com protocolo simples de requisição/resposta, **roteamento seguro** por FSMs, e **testbench** em SystemVerilog (ModelSim/Questa).

---

## ✨ Visão geral

- **Objetivo**: Receber, via SPI, comandos para ligar/desligar LEDs na FPGA e responder confirmando a execução.
- **Arquitetura**:  
  - Um **serviço principal** (`main_service`) com FSM decide qual serviço secundário ativa (neste projeto, `led_service`).  
  - **Protocolos RX/TX** implementam parsing e formatação de frames.  
  - **Router** de RX e **árbitro** de TX garantem transições seguras entre FSMs.  
  - **SPI slave 100% RTL** com recarga de MISO a **cada byte** (mesmo com CS baixo) + FIFOs internos de RX/TX.
- **Protocolo**:
  - Requisição (host→FPGA): `HDR_REQ(0xAA), CMD, ID, IDX, VAL, TAIL_REQ(0x55)`
  - Resposta (FPGA→host): `HDR_RSP(0xAB), CMD, ID, IDX, VAL, OK, TAIL_RSP(0x54)`
  - `CMD_LED = 0x30`, `IDX=0..7`, `VAL=0/1`, `OK=0/1`

---

## 📁 Estrutura do repositório

```
.
├─ src/
│  ├─ drivers/
│  │  ├─ spi_slave_8.sv           # SPI slave RTL com FIFOs e recarga por byte
│  │  └─ spi_stream_bridge.sv     # Ponte byte↔stream (handshake valid/ready)
│  │
│  ├─ protocol/
│  │  ├─ interfaces/
│  │  │  ├─ stream_if.sv          # Interface de stream (valid/ready, 8 bits)
│  │  │  └─ cmd_if_led.sv         # Interface de comando do serviço LED
│  │  ├─ framings/
│  │  │  └─ framing_pkg.sv        # Constantes de framing (HDR/TAIL)
│  │  ├─ messages/
│  │  │  └─ msg_led.sv            # Tipos set_led_req_t / set_led_rsp_t
│  │  ├─ codecs/
│  │  │  └─ codec_led.sv          # codec_led_pkg: pack_rsp/unpack_req
│  │  ├─ parsers/
│  │  │  ├─ rx_router.sv          # Roteia frames por CMD; dá grant seguro
│  │  │  └─ rx_parser_led.sv      # Parser do comando LED
│  │  ├─ formatters/
│  │  │  ├─ tx_arbiter.sv         # Escalonador de fontes de resposta
│  │  │  └─ tx_formatter_led.sv   # Monta payload da resposta LED
│  │  ├─ cmd/
│  │  │  └─ led_cmd_pkg.sv        # CMD_LED e auxiliares específicos
│  │  ├─ protocol_rx.sv           # Orquestração do RX + router + parsers
│  │  └─ protocol_tx.sv           # Orquestração do TX + arbitro + formatters
│  │
│  ├─ services/
│  │  ├─ main_service.sv          # FSM principal (seleção de serviço/fluxo)
│  │  └─ led_service.sv           # FSM do serviço LED (aplica na saída)
│  │
│  └─ top/
│     └─ top_led_spi.sv           # Topo: integra tudo + parâmetros CPOL/CPHA
│
├─ tb/
│  ├─ spi_if.sv                   # Interface/BFM SPI master (modo 3, CPHA=1)
│  ├─ leds_if.sv                  # Interface de monitoramento dos LEDs
│  ├─ tb_pkg.sv                   # Classes: transação, BFM, scoreboard, env, test
│  └─ tb_top.sv                   # Testbench top (instancia DUT e BFM)
│
└─ tb/modelsim/
   ├─ cli.do                      # Script CLI para compilar/rodar
   └─ waves.do                    # Script de ondas (GUI)
```

---

## ⚙️ Parâmetros importantes

- `top_led_spi`  
  - `CPOL`, `CPHA`: **use 1’b1, 1’b1** (modo SPI 3)  
  - `NUM_LEDS`: número de LEDs expostos em `leds[]`
- `spi_slave_8`  
  - `CPOL`, `CPHA` (herdado do top)  
  - `RX_DEPTH`, `TX_DEPTH`: profundidades dos FIFOs internos  
  - `TX_UNDERFLOW_BYTE`: byte enviado se o TX FIFO estiver vazio (default `8'h00`)

---

## 🔌 Protocolo (framing)

**Requisição (host→FPGA)**  
```
+---------+------+-----+-----+-----+----------+
| HDR_REQ | CMD  | ID  | IDX | VAL | TAIL_REQ |
|  0xAA   |0x30  | 8b  | 8b  | 8b  |  0x55    |
                      (usa idx[2:0]) (usa val[0])
```

**Resposta (FPGA→host)**  
```
+---------+------+-----+-----+-----+-----+----------+
| HDR_RSP | CMD  | ID  | IDX | VAL | OK  | TAIL_RSP |
|  0xAB   |0x30  | 8b  | 8b  | 8b  | 8b  |  0x54    |
                      (idx[2:0])  (val[0]) (ok[0])
```

- **CMD_LED (0x30)**: acende/apaga LED `IDX` com `VAL`.  
- `OK=1` se o serviço aplicou com sucesso (ex.: índice válido).

---

## 🧠 Handshakes & FSMs

- **stream_if**: `valid/ready` com `data[7:0]`.  
- **cmd_if_led**:  
  - Requisição: `req_valid/req_ready/req(set_led_req_t)`  
  - Resposta: `rsp_valid/rsp_ready/rsp(set_led_rsp_t)`  
- **FSM Principal** `main_service`: ativa e concede **allow_grant** para o **router RX**, garantindo que apenas um parser consuma o frame corrente.  
- **Router RX**: espera `HDR_REQ`, lê `CMD`, decide qual parser habilitar (aqui: `rx_parser_led`) e faz **grant**; ao final do frame, sinaliza **frame_done**.  
- **Arbitro TX**: coleta das fontes de resposta (aqui: `tx_formatter_led`) e exporta um **stream** contínuo para o SPI.  
- **Transição segura**: `allow_grant` abre/fecha o acesso de cada parser; TX só transmite quando o formatter finaliza (`*_fmt_done`) e o árbitro concede o canal.

---

## 🧩 Módulos (resumo)

- **drivers/spi_slave_8.sv**: Slave SPI **modo 3** (CPOL=1/CPHA=1), MSB-first, normaliza SCLK/CSN/MOSI ao clock do sistema, **recarga de MISO a cada byte**, **FIFOs** internos (RX/TX).
- **drivers/spi_stream_bridge.sv**: Converte entre bytes discretos (do slave) e `stream_if` (valid/ready), tanto RX quanto TX.
- **protocol/**  
  - `framing_pkg.sv`: HDR/TAIL CONSTs.  
  - `stream_if.sv`, `cmd_if_led.sv`: interfaces padrão.  
  - `msg_led.sv`: tipos `set_led_req_t/rsp_t`.  
  - `codec_led.sv`: `codec_led_pkg` com `unpack_req` (bytes→req) e `pack_rsp` (rsp→bytes).  
  - `rx_router.sv`, `rx_parser_led.sv`: roteia e interpreta frame CMD_LED.  
  - `tx_arbiter.sv`, `tx_formatter_led.sv`: arbitra e monta resposta LED.  
  - `protocol_rx.sv`, `protocol_tx.sv`: orquestram fluxo RX/TX.
- **services/**  
  - `main_service.sv`: FSM principal do protocolo (gerencia **allow_grant** e estado global).  
  - `led_service.sv`: FSM secundária; aplica `req` no `leds[]` e emite `rsp`.
- **top/top_led_spi.sv**: Integra tudo; parametriza CPOL/CPHA e `NUM_LEDS`.

---

## ▶️ Simulação (ModelSim/Questa)

### Pré-requisitos
- ModelSim/Questa (Intel FPGA Edition 2020.1 ou similar).
- Windows paths no exemplo, ajuste se estiver em Linux.

### Rodando (CLI)
```tcl
# a partir da pasta do projeto
vsim -do tb/modelsim/cli.do
```

O `cli.do`:
- Detecta a raiz do projeto, configura `+incdir` para `.` e `./src`.  
- Compila `tb/spi_if.sv`, `tb/leds_if.sv`, `tb/tb_pkg.sv`, `tb/tb_top.sv`.  
- Roda `run -all`.

### Ondas (GUI)
No GUI, após carregar o design:
```
do tb/modelsim/waves.do
```
> Script compatível (sem `sim:/`), com `catch` nos sinais opcionais.

---

## 🧪 Testbench

- **BFM** (`spi_if.sv`): Master SPI com timing especial para **CPHA=1** (garante **setup** antes da borda de amostragem).  
- **tb_pkg.sv**:
  - `led_cmd_item`: transação com `id, idx, val`.  
  - `spi_master_bfm`: envia o frame de **requisição** e lê a **resposta**.  
    - *Leitura robusta*: “multi-frame polling” (pulsando CS) até achar `HDR_RSP`.  
  - `led_scoreboard`: confere frame de resposta e estado do LED físico.  
  - `led_env`/`led_test`: rodam a sequência de testes.

### Dicas se der timeout no `0xAB`
1. **Garanta CPOL=1/CPHA=1** no **BFM** e no **DUT** (override nos parâmetros do `tb_top.sv`).  
2. **Deixe `allow_grant=1`** durante o bring-up (em `top_led_spi.sv`, conectar `protocol_rx.allow_grant(1'b1)`) para não travar o parser.  
3. Garanta que `spi_if.xfer_bit` (CPHA=1) dá **setup** antes da borda de amostragem (já ajustado no BFM).  
4. Veja nas ondas se `tx_stream→bridge→spi_slave_8` realmente recebe os bytes do formatter.

---

## 🔧 Síntese / FPGA

- Projeto testado em fluxo Gowin (Tang Primer 20K), mas o **SPI é 100% RTL** (não usa IP Gowin).  
- **MISO tri-state** quando `CSN=1` (o *mapper* infere OBUFT).  
- Ajuste pinos e clocks conforme sua placa.  
- **Clock de sistema** deve ser rápido o bastante para sincronizar SCLK/CSN/MOSI (use 2×–4× o SCLK, pelo menos).

---

## 🐍 Exemplo de host (Raspberry Pi / Linux)

```python
# host/spi_led.py
import spidev, time

HDR_REQ, TAIL_REQ = 0xAA, 0x55
HDR_RSP, TAIL_RSP = 0xAB, 0x54
CMD_LED = 0x30

def open_spi(bus=0, dev=0, speed=1_000_000):
    spi = spidev.SpiDev()
    spi.open(bus, dev)
    spi.max_speed_hz = speed
    spi.mode = 0b11          # CPOL=1, CPHA=1 (modo 3)
    spi.bits_per_word = 8
    return spi

def send_led(spi, id_, idx, val):
    req = [HDR_REQ, CMD_LED, id_ & 0xFF, idx & 0xFF, val & 0x01, TAIL_REQ]
    spi.xfer2(req)

def read_rsp(spi, tries=64, gap=0.002):
    # multi-frame polling: a cada tentativa lê 1 byte (CS baixa por transação)
    for _ in range(tries):
        time.sleep(gap)
        first = spi.xfer2([0x00])[0]
        if first == HDR_RSP:
            body = spi.xfer2([0x00]*6)
            return [first] + body
    raise RuntimeError("Timeout esperando HDR_RSP")

if __name__ == "__main__":
    spi = open_spi(0, 0, 1_000_000)
    send_led(spi, id_=0xA1, idx=0, val=1)
    rsp = read_rsp(spi)
    print("RSP:", [hex(x) for x in rsp])
```

> Lembre de ligar **GND comum** entre Pi e placa. Adeque `bus/dev` e `speed`.

---

## 🪪 Boas práticas que este projeto segue

- ``ifndef / `define / `endif` em **todos** os módulos/pkg.  
- **Separação por camadas**: drivers, protocolo, serviços, topo.  
- **Encapsulamento**: parsers/formatters específicos **não** ficam nos `*_pkg` genéricos.  
- **FSM principal** + **FSM secundárias**, com **router/arbiter** para transições seguras.  
- **Interfaces modport** distintos para RX, TX e service (evita “multidrivers”).  
- **Reload de MISO por byte** + **FIFOs RX/TX** no `spi_slave_8`: robusto com mestres reais.

---

## 🛠️ Solução de problemas (FAQ)

- **Timeout no `HDR_RSP (0xAB)`**  
  - Verifique **modo SPI**: BFM e DUT em **CPOL=1/CPHA=1**.  
  - No bring-up, use `allow_grant=1`.  
  - Garanta que `spi_if.xfer_bit` (CPHA=1) dá **setup** antes da borda de amostragem (já ajustado no BFM).  
  - Veja nas ondas se `tx_stream→bridge→spi_slave_8` realmente recebe os bytes do formatter.

- **Warnings “swept in optimizing”**  
  - Algum módulo ficou **sem conexões ativas** (ex.: `tx_arbiter` sem fonte). Verifique ligações e sinais `*_valid/ready`.

- **“Illegal to assign to input modport port”**  
  - Cheque os `modports` nas `interfaces` e **quem dirige quem**. Use modports separados: `protocol_rx`, `protocol_tx`, `service`.

- **“Illegal declaration after statement”**  
  - Em ModelSim antigo, **declare tasks/functions antes** de `always_*`. Evite chamar `task` dentro de `always_ff` (use pulsos e blocos dedicados).

---

## 📜 Licença

Escolha sua licença (ex.: MIT/BSD-2/Apache-2.0). Exemplo:

```
MIT License – (c) 2025 Seu Nome
```

---

## ✅ Checklist rápido

- [ ] `top_led_spi` instanciado com **`.CPOL(1’b1), .CPHA(1’b1)`**  
- [ ] `spi_if.sv` BFM com **timing CPHA=1** (setup antes da borda de amostragem)  
- [ ] `allow_grant` liberado no bring-up  
- [ ] `cli.do` e `waves.do` ajustados para seu ambiente  
- [ ] Host (opcional) com **SPI mode 3**  

Se travar em qualquer etapa, abra uma issue com o *log* (arquivo:linha) ou um screenshot de ondas e eu te ajudo a localizar o gargalo rapidinho. 🚀

