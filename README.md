# 💻💻💻 Arcium — Node Installation & Management (arcium-node-hub.sh v0.5.2-mig)

🟣 **Activity Type:** Node  
🟣 **Funding:** $14.00M  
🟣 **Investors:** [Coinbase Ventures, Anatoly Yakovenko, and others](https://cryptorank.io/ru/ico/elusiv)  
🟣 **Setup Time:** ~20 min  
🟣 **Minimum Requirements:** amd64 12 CPU / 32 RAM / 20GB SSD

> **Script:** `arcium-node-hub.sh` **v0.5.2-mig**  
> Fresh install, tools, and migration **0.3.0 → 0.4.0 → 0.5.1**, with a workaround for the BLS bug in Arcium CLI 0.5.1.

---

## 🧠 About the Project

**Arcium** is a next-generation encrypted supercomputer designed for secure and scalable computations on encrypted data.  
It’s powered by **MPC (Multi-Party Computation)** technology, which ensures full confidentiality without revealing the original data.

Arcium builds the foundation for **privacy-preserving infrastructure** across Web2 and Web3 — connecting developers, enterprises, and industries into a decentralized network where data remains protected at every step.

---

## 🚀 Public Testnet Phase 2

📅 **October 3, 2025** — Arcium launched **Public Testnet Phase 2**, the final stage before Mainnet Alpha.  

> ⚠️ Running a node is **voluntary** and **not officially linked** to any airdrop or reward program.

---

## 🧩 Known Issue: BLS Bug in Arcium CLI (v0.5.1) & Workaround

In Arcium CLI v0.5.1 some operators hit the error:

```text
Failed to convert BLS keypair to 32 byte array
````

This happens inside the **CLI**, not in user scripts:

1. `arcium gen-bls-key` outputs a BLS key as JSON (array of 32 integers).
2. Later `arcium init-arx-accs` sometimes fails to convert that JSON into a 32-byte key.
3. As a result, `init-arx-accs` fails and the node never inits.

Formally this should be fixed by the **Arcium team** in the CLI / BLS handling.
Until then, `arcium-node-hub.sh v0.5.2-mig` adds a **safe workaround** so operators can still initialize or migrate nodes.

### 🔧 How the workaround works

When you run on-chain initialization from the script (fresh install or migration 0.4.0 → 0.5.1), it does the following:

1. **Generates a BLS key in JSON form**

   ```bash
   arcium gen-bls-key bls-keypair.json
   ```

   The file contains a JSON array of 32 integers (`[14, 223, 126, ...]`).

2. **Validates the JSON**
   A small embedded Python snippet checks that:

   * it is a list,
   * length is exactly 32,
   * each element is an integer in range `0..255`.

3. **Converts JSON → `bls-keypair.bin`**
   If validation succeeds, the script writes a second file:

   ```text
   bls-keypair.bin
   ```

   This is the **same BLS private key**, but stored as a **raw 32-byte blob**, without JSON wrapper — exactly what the CLI expects internally.

4. **Calls `init-arx-accs` with automatic retry**

   * First run uses the “normal” path (JSON or BIN, depending on CLI support).
   * If CLI returns:

     ```text
     Failed to convert BLS keypair to 32 byte array
     ```

     the script **automatically retries** `init-arx-accs` with:

     ```bash
     --bls-keypair-path bls-keypair.bin
     ```
   * If CLI says:

     ```text
     Allocate: account Address ... already in use
     ```

     the script treats this as **success** (your operator account already exists on-chain), not a fatal error.

> 📌 Important: the script does **not** change protocol logic or key formats.
> It only:
>
> * generates the BLS key via official CLI,
> * validates it,
> * provides the CLI with the same key in a slightly different (binary) form when JSON parsing fails.

This is explicitly a **temporary workaround** around a CLI bug, until Arcium ships an official fix.

---

## ⚙️ What `arcium-node-hub.sh` Does (Under the Hood)

High-level features:

* **Server preparation** (menu `1`):

  * Installs / configures: Docker, Rust, Solana CLI, Node.js + Yarn, Anchor (or a shim), Arcium CLI via `arcup` or `cargo`.
  * Sets up PATH and optional `binfmt` for ARM hosts (to run amd64 Docker images).

* **Node installation & launch** (menu `2`):

  * Asks for RPC endpoints, OFFSET, IP and saves everything into `.env`.
  * Generates Solana keypairs (node + callback), Ed25519 identity, BLS key (JSON + BIN).
  * Extracts and stores mnemonics (seed phrases) in separate files.
  * Checks Devnet balances and helps with airdrop.
  * Runs `arcium init-arx-accs` with the BLS workaround.
  * Creates `node-config.toml` and starts a Docker container `arx-node` with the selected image (default: `arcium/arx-node:v0.5.1`).

* **Configuration menu** (menu `4`):

  * Allows you to edit `RPC_HTTP` / `RPC_WSS`.
  * Updates both `.env` and `node-config.toml`.
  * Offers to restart the container after changes.

* **Tools menu** (menu `5`):

  * Live logs from inside the container.
  * `arx-info` and `arx-active` for node status and activity.
  * Propose / join cluster and check membership.
  * Show keys and Devnet balances.
  * Devnet airdrop helper.
  * Safely display seed phrases (masked by default, full view only on explicit `YES`).
  * Show versions (Arcium CLI, arcup, running Docker image vs `IMAGE` in `.env`).

* **Management menu** (menu `3`):

  * Start / restart / stop / remove the `arx-node` container.
  * Show container status table.

* **Migration paths**:

  * `6) Migration 0.3.0 → 0.4.0`
  * `7) Migration 0.4.0 → 0.5.1` (includes CLI upgrade + BLS key generation + container rebuild).

* **Full removal**:

  * `8) Full node removal` — removes container, image and local node directory (requires explicit `YES`).

---

## 🚀 Node Installation (Fresh Install, 0.5.1)

### 🔧 One-time Python fix (optional)

If during `apt-get update` you see a `_distutils_hack` / setuptools-related error, install:

```bash
sudo apt-get install -y python3-setuptools
```

---

### ➡️ Step-by-Step

**1️⃣ Download and run the setup script:**

```bash
wget -q -O arcium-node-hub.sh https://raw.githubusercontent.com/k2wGG/Arcium/refs/heads/main/arcium-node-hub.sh && sudo chmod +x arcium-node-hub.sh && ./arcium-node-hub.sh
```

**2️⃣ Prepare the server:**
Select:
`1) Server preparation (Docker, Rust, Solana, Node/Yarn, Anchor, Arcium CLI)`
Wait until it finishes (Docker, Rust, Solana CLI, Node/Yarn, Anchor shim, Arcium CLI).

**3️⃣ Install and launch the node:**
Select:
`2) Node installation & run`

* When asked for **Solana Devnet RPC** → press **Enter** to use default if you don’t have your own.
* When asked for **Solana Devnet WSS** → press **Enter** again.

  > Recommended RPC providers: [Helius](https://helius.xyz/) or [QuickNode](https://quicknode.com/)
* Enter your **Node OFFSET** — any 8–10 digit combination (keep it, you’ll need it for cluster actions).
* When asked for public IP → press **Enter** to auto-detect (or set manually).

**4️⃣ Wallets & faucet:**
The script will generate your wallets and show addresses + balances.
If Devnet balance is `0`, use:

* built-in airdrop helper, or
* [https://faucet.solana.com/](https://faucet.solana.com/)

Once both node and callback accounts have SOL, initialization continues automatically (including BLS handling).

**5️⃣ Check node logs:**
Menu:
`5) Tools (logs, status, keys)` → `1) Logs (follow)`

You should see normal sync logs (no fatal errors).

**6️⃣ Verify node activity:**
`5) Tools (logs, status, keys)` → `3) Check if Node is Active`

Output should be **True**.

**7️⃣ Backup your keys & seeds:**

* `5) Tools (logs, status, keys)` → `9) Show seed phrases`

  * Script shows masked mnemonics by default (first 4 + last 4 words).
  * Full seed is shown only if you explicitly type `YES`.

Save files (path may differ if you changed `BASE_DIR`):

```text
/root/arcium-node-setup/node-keypair.json
/root/arcium-node-setup/callback-kp.json
/root/arcium-node-setup/identity.pem
/root/arcium-node-setup/node-keypair.seed.txt
/root/arcium-node-setup/callback-kp.seed.txt
/root/arcium-node-setup/bls-keypair.json
/root/arcium-node-setup/bls-keypair.bin
```

**8️⃣ Join a cluster (via menu):**

To join a cluster:

1. Open `5) Tools (logs, status, keys)` → `5) Join cluster`
2. Enter **CLUSTER OFFSET** of the cluster you want to join.

If you want to join **my cluster**, DM me your **NODE OFFSET** (shown in `Tools → Check Node Activity`),
and I’ll send you the CLUSTER OFFSET / instructions. If you’re not sure which cluster to use — ask in the community chat.

To inspect a node in a cluster:
`5) Tools (logs, status, keys)` → `2) Node status` or `6) Check node membership in your cluster`.

---

## 🟠 Additional Resources

📘 **Official Docs:**
[docs.arcium.com/developers/node-setup#devnet-rpc-provider-recommendations](https://docs.arcium.com/developers/node-setup#devnet-rpc-provider-recommendations)

🌐 **Website:**
[arcium.com](https://www.arcium.com/)

💬 **X (Twitter):**
[x.com/arciumhq](https://x.com/arciumhq)

👾 **Discord:**
[discord.gg/arcium](https://discord.com/invite/arcium)

---

✍️ Even though the team states that running a node is voluntary and not rewarded, I decided to run at least one node — the project looks **promising** with **strong backing**.

---

📢 **Community Resources:**
💬 Chat — [t.me/nod3r_team](https://t.me/nod3r_team)
🤖 Bot — [t.me/wiki_nod3r_bot](https://t.me/wiki_nod3r_bot)

---

# 💻💻💻 Arcium — установка и управление нодой (arcium-node-hub.sh v0.5.2-mig)

🟣 **Тип активности:** Ноды

🟣 **Инвестиции:** $14.00M

🟣 **Инвесторы:** [Coinbase Ventures, Anatoly Yakovenko и др.](https://cryptorank.io/ru/ico/elusiv)

🟣 **Время выполнения:** ~20 мин

🟣 **Системные требования (минимум):** amd64 12 CPU / 32 RAM / 20GB SSD

> **Скрипт:** `arcium-node-hub.sh` **v0.5.2-mig**
> Умеет: свежая установка, удобные меню, миграции **0.3.0 → 0.4.0 → 0.5.1**, плюс обход бага BLS в Arcium CLI 0.5.1.

---

## 🧠 О проекте

**Arcium** — зашифрованный суперкомпьютер нового поколения для безопасных и масштабируемых вычислений над зашифрованными данными.
В основе — технология **MPC (Multi-Party Computation)**, которая позволяет выполнять вычисления, не раскрывая исходные данные.

Arcium строит инфраструктуру приватных вычислений для Web2 и Web3, объединяя разработчиков и бизнес в единую децентрализованную сеть, где данные остаются защищёнными на каждом этапе.

---

## 🚀 Public Testnet Phase 2

📅 **03.10.2025** запущен **Public Testnet Phase 2**.

> 🚨 Участие в тестнете — **добровольное**, официально не привязано к airdrop или наградам.

---

## 🧩 Известная проблема: баг с BLS в Arcium CLI (v0.5.1) и костыль

В версии Arcium CLI 0.5.1 у многих операторов команда `init-arx-accs` падает с ошибкой:

```text
Failed to convert BLS keypair to 32 byte array
```

Это происходит **внутри CLI**, а не в наших скриптах:

1. `arcium gen-bls-key` генерит BLS-ключ в виде JSON (массив из 32 чисел).
2. Потом `arcium init-arx-accs` иногда не может превратить этот JSON в 32-байтовый ключ.
3. В итоге `init-arx-accs` падает, и нода не инициализируется.

Формально этот баг должны исправить сами **Arcium** (обновление CLI / логики работы с BLS).
Пока фикс не вышел, `arcium-node-hub.sh v0.5.2-mig` добавляет аккуратный **костыль**, чтобы можно было поднять или мигрировать ноду.

### 🔧 Как работает костыль

При ончейн-инициализации (новая установка или миграция 0.4.0 → 0.5.1) скрипт делает следующее:

1. **Генерирует BLS-ключ в JSON**

   ```bash
   arcium gen-bls-key bls-keypair.json
   ```

   Внутри — JSON-массив из 32 целых чисел (`[14, 223, 126, ...]`).

2. **Проверяет формат**
   Встроенный Python-фрагмент проверяет, что:

   * это список,
   * длина ровно 32,
   * каждое значение — целое число в диапазоне `0..255`.

3. **Конвертирует JSON → `bls-keypair.bin`**
   Если всё ок, создаётся второй файл:

   ```text
   bls-keypair.bin
   ```

   Это **тот же самый BLS-приватник**, но в виде «сырых» 32 байт без JSON-обёртки — в том виде, в каком его ожидает сам CLI внутри.

4. **Вызывает `init-arx-accs` с автоповтором**

   * Сначала запуск идёт по «нормальному» пути (JSON или BIN — в зависимости от того, что поддерживает версия CLI).
   * Если CLI отвечает:

     ```text
     Failed to convert BLS keypair to 32 byte array
     ```

     скрипт **автоматически перезапускает** `init-arx-accs` c:

     ```bash
     --bls-keypair-path bls-keypair.bin
     ```
   * Если CLI пишет:

     ```text
     Allocate: account Address ... already in use
     ```

     скрипт считает это **успешной повторной инициализацией** (аккаунт уже есть on-chain), а не фатальной ошибкой.

> 📌 Важно: скрипт **не меняет** протокол и формат ключей.
> Он лишь:
>
> * генерирует BLS-ключ штатной командой,
> * валидирует его,
> * при падении JSON-пути подсовывает CLI тот же ключ в бинарном виде.

Это именно **временный обходной путь**, пока команда Arcium не выкатает официальный фикс.

---

## ⚙️ Что умеет `arcium-node-hub.sh` (под капотом)

Кратко:

* **Подготовка сервера** (меню `1`):

  * Устанавливает и настраивает: Docker, Rust, Solana CLI, Node.js + Yarn, Anchor (или заглушку), Arcium CLI через `arcup` или `cargo`.
  * Прописывает PATH, при необходимости включает `binfmt` для ARM-хостов (чтобы гонять amd64-образы).

* **Установка и запуск ноды** (меню `2`):

  * Спрашивает RPC, OFFSET, IP и сохраняет это в `.env`.
  * Генерирует солановские ключи (нода + callback), Ed25519-identity, BLS-ключи (JSON + BIN).
  * Выделяет и сохраняет сид-фразы в отдельные файлы.
  * Проверяет балансы на Devnet, помогает с airdrop.
  * Запускает `arcium init-arx-accs` с учётом костыля вокруг BLS.
  * Создаёт `node-config.toml` и стартует Docker-контейнер `arx-node` (по умолчанию `arcium/arx-node:v0.5.1`).

* **Меню конфигурации** (меню `4`):

  * Позволяет редактировать `RPC_HTTP` / `RPC_WSS`.
  * Обновляет и `.env`, и `node-config.toml`.
  * Предлагает перезапустить контейнер.

* **Меню инструментов** (меню `5`):

  * Просмотр логов в реальном времени.
  * `arx-info` и `arx-active` для статуса и активности ноды.
  * Отправка заявки в кластер, присоединение к кластеру, проверка членства.
  * Показ адресов и балансов на Devnet.
  * Вспомогательный airdrop.
  * Безопасный показ сид-фраз (маскирование, полный текст только по явному `YES`).
  * Пункт «Показать версии» — Arcium CLI, arcup, текущий Docker-образ и значение `IMAGE` в `.env`.

* **Меню управления контейнером** (меню `3`):

  * Старт / рестарт / стоп / удаление контейнера `arx-node`.
  * Таблица статуса Docker-контейнера.

* **Миграции**:

  * `6) Миграция 0.3.0 → 0.4.0`
  * `7) Миграция 0.4.0 → 0.5.1` (включая обновление CLI, генерацию BLS, перезапуск контейнера на `arcium/arx-node:v0.5.1`).

* **Полное удаление**:

  * `8) Полное удаление ноды` — удаляет контейнер, образ и каталог ноды (только после явного ввода `YES`).

---

## ⚙️ Установка ноды (чистая установка, 0.5.1)

### 🔧 Возможный фикс Python-ошибки

Если при `apt-get update` появляется ошибка `_distutils_hack` / setuptools, устанавливаем:

```bash
sudo apt-get install -y python3-setuptools
```

---

### ➡️ Шаг за шагом

1️⃣ **Скачиваем и запускаем скрипт:**

```bash
wget -q -O arcium-node-hub.sh https://raw.githubusercontent.com/k2wGG/Arcium/refs/heads/main/arcium-node-hub.sh && sudo chmod +x arcium-node-hub.sh && ./arcium-node-hub.sh
```

2️⃣ **Подготовка сервера:**
Выбираем `1) Подготовка сервера (Docker, Rust, Solana, Node/Yarn, Anchor, Arcium CLI)`
Ждём, пока всё установится.

3️⃣ **Установка и запуск ноды:**
Выбираем `2) Установка и запуск ноды`.

* При запросе **RPC Solana Devnet** → жмём **Enter**, если нет своего RPC.
* При запросе **WSS Solana Devnet** → тоже **Enter**, если нет своего.

  > Рекомендуемые RPC: [Helius](https://helius.xyz/) или [QuickNode](https://quicknode.com/)
* Вводим **Node OFFSET** — любая комбинация из 8–10 цифр (запомните её).
* При запросе IP → жмём **Enter** для автоопределения (или вводим вручную).

4️⃣ **Кошельки и токены:**
Скрипт создаст ключи, покажет адреса и балансы.
Если на Devnet 0 SOL:

* можно воспользоваться встроенным запросом airdrop,
* либо зайти на [https://faucet.solana.com/](https://faucet.solana.com/).

После появления SOL на обоих аккаунтах (нода + callback) установка продолжится автоматически (включая работу с BLS).

5️⃣ **Проверяем работу ноды:**
`5) Инструменты (логи, статус, ключи)` → `1) Просмотр логов`

Должны быть нормальные логи синхронизации без фатальных ошибок.

6️⃣ **Проверяем активность ноды:**
`5) Инструменты (логи, статус, ключи)` → `3) Проверить активность ноды`

Ожидаемое значение — **True**.

7️⃣ **Бэкапим ключи и сид-фразы:**

* `5) Инструменты (логи, статус, ключи)` → `9) Показать сид-фразы`

  * По умолчанию сиды показываются с маской (первые 4 и последние 4 слова).
  * Полный сид выводится только если вы явно вводите `YES`.

Сохраняем файлы (если не меняли `BASE_DIR`):

```text
/root/arcium-node-setup/node-keypair.json
/root/arcium-node-setup/callback-kp.json
/root/arcium-node-setup/identity.pem
/root/arcium-node-setup/node-keypair.seed.txt
/root/arcium-node-setup/callback-kp.seed.txt
/root/arcium-node-setup/bls-keypair.json
/root/arcium-node-setup/bls-keypair.bin
```

8️⃣ **Присоединение к кластеру через меню:**

Чтобы вступить в кластер:

1. Открываем `5) Инструменты (логи, статус, ключи)` → `5) Присоединиться к кластеру`.
2. Вводим **CLUSTER OFFSET** кластера, в который хотим вступить.

Если хотите вступить в **мой кластер** — пришлите в чат ваш **NODE OFFSET**
(его можно увидеть в `5) Инструменты` → `3) Проверить активность ноды`),
и я отправлю вам нужный **CLUSTER OFFSET** / инструкции. Если не знаете, в какой кластер идти — просто спросите в чате.

Проверить информацию по ноде и кластеру можно через:
`5) Инструменты` → `2) Статус ноды` или `6) Проверить членство ноды в кластере`.

---

## 🟠 Дополнительно

📘 **Официальная инструкция:**
[docs.arcium.com/developers/node-setup#devnet-rpc-provider-recommendations](https://docs.arcium.com/developers/node-setup#devnet-rpc-provider-recommendations)

🌐 **Сайт:**
[arcium.com](https://arcium.com/)

💬 **X (Twitter):**
[x.com/arciumhq](https://x.com/arciumhq)

👾 **Discord:**
[discord.gg/arcium](https://discord.com/invite/arcium)

---

✍️ Несмотря на заявление команды об отсутствии наград за ноды, я решил поднять хотя бы одну — проект выглядит **перспективно** и с **сильными инвесторами**.

---

📢 **Ресурсы коммьюнити:**
💬 Чат — [t.me/nod3r_team](https://t.me/nod3r_team)
🤖 Бот — [t.me/wiki_nod3r_bot](https://t.me/wiki_nod3r_bot)
