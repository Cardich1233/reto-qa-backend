# Reto de Automatización QA — BackEnd (API Usuarios de ServeRest)

[![API Usuarios ServeRest](https://github.com/Cardich1233/reto-qa-backend/actions/workflows/api-tests.yml/badge.svg)](https://github.com/Cardich1233/reto-qa-backend/actions/workflows/api-tests.yml)

Suite de pruebas de API para el recurso **Usuarios** de
[ServeRest](https://serverest.dev/), construida con **Karate DSL**.

> Estado actual: **34 escenarios / 5 features — 100 % en verde** (~14 s con 5 hilos).

---

## 1. Requisitos

| Herramienta | Versión mínima |
|---|---|
| JDK | 17 (probado en Temurin 17.0.19) |

**No hace falta instalar Maven.** El proyecto incluye el *Maven Wrapper*
(`mvnw` / `mvnw.cmd`), que descarga Apache Maven 3.9.9 en la primera ejecución.

Verifica tu JDK:

```bash
java -version
```

---

## 2. Ejecución

### Linux / macOS / Git Bash

```bash
./mvnw test
```

### Windows (CMD / PowerShell)

```bash
mvnw.cmd test
```

La primera corrida descarga Maven y las dependencias (~1–2 min). Las siguientes
tardan unos 15 segundos.

### Ejecuciones selectivas

| Comando | Qué ejecuta |
|---|---|
| `mvnw test` | Suite completa (34 escenarios) |
| `mvnw test -Dkarate.options="--tags @smoke"` | Sólo el camino feliz de cada operación CRUD |
| `mvnw test -Dkarate.options="--tags @negativo"` | Sólo los casos negativos |
| `mvnw test -Dkarate.options="--tags @registrar"` | Sólo `POST /usuarios` |
| `mvnw test -Dkarate.threads=1` | Ejecución secuencial (log legible para depurar) |
| `mvnw test -Dkarate.env=local` | Apunta a `http://localhost:3000` en vez de serverest.dev |

---

## 3. Reportes

Después de cada corrida:

| Artefacto | Ruta |
|---|---|
| Reporte HTML de Karate | `target/karate-reports/karate-summary.html` |
| Reporte JSON (Cucumber, para CI) | `target/karate-reports/*.json` |

El reporte HTML incluye, para cada escenario, la petición y la respuesta HTTP
completas: es la evidencia de la ejecución.

---

## 4. Estructura del proyecto

```
backend-serverest/
├── pom.xml
├── mvnw / mvnw.cmd               # Maven Wrapper (no requiere Maven instalado)
└── src/test/java/
    ├── karate-config.js          # Configuración global (baseUrl, helpers, esquemas)
    ├── reto/
    │   └── UsuariosTest.java     # Runner de la suite (ejecución paralela)
    ├── usuarios/                 # Un feature por endpoint
    │   ├── usuarios-listar.feature       # GET    /usuarios
    │   ├── usuarios-registrar.feature    # POST   /usuarios
    │   ├── usuarios-buscar.feature       # GET    /usuarios/{_id}
    │   ├── usuarios-actualizar.feature   # PUT    /usuarios/{_id}
    │   └── usuarios-eliminar.feature     # DELETE /usuarios/{_id}
    ├── helpers/                  # Utilidades reutilizables
    │   ├── nuevo-usuario.js              # Generador de datos de prueba
    │   ├── crear-usuario.feature         # Setup:    alta de usuario
    │   ├── consultar-usuario.feature     # Verificación por _id
    │   └── eliminar-usuario.feature      # Teardown: baja de usuario
    └── schemas/
        └── esquemas.js           # Catálogo central de esquemas JSON
```

---

## 5. Cobertura

### Por criterio de aceptación

| # | Criterio de aceptación | Feature | Escenarios |
|---|---|---|---|
| 1 | Obtener la lista de todos los usuarios | `usuarios-listar.feature` | 6 |
| 2 | Registrar un nuevo usuario con datos válidos | `usuarios-registrar.feature` | 13 |
| 3 | Buscar un usuario específico por su ID | `usuarios-buscar.feature` | 4 |
| 4 | Actualizar la información de un usuario | `usuarios-actualizar.feature` | 7 |
| 5 | Eliminar un usuario del sistema | `usuarios-eliminar.feature` | 4 |

### Por tipo de caso

| Etiqueta | Escenarios |
|---|---|
| `@positivo` | 19 |
| `@negativo` | 15 |
| `@smoke` | 5 (uno por operación CRUD) |

---

## 6. Contrato de la API verificado

Comportamientos de ServeRest confirmados contra el ambiente real y cubiertos por
la suite:

| Operación | Caso | Respuesta |
|---|---|---|
| `POST /usuarios` | Datos válidos | `201` — `Cadastro realizado com sucesso` + `_id` |
| `POST /usuarios` | Email duplicado | `400` — `Este email já está sendo usado` |
| `POST /usuarios` | Campo faltante | `400` — `<campo> é obrigatório` |
| `POST /usuarios` | Campo en blanco | `400` — `<campo> não pode ficar em branco` |
| `GET /usuarios/{id}` | ID inexistente | `400` — `Usuário não encontrado` |
| `GET /usuarios/{id}` | ID mal formado | `400` — `id deve ter exatamente 16 caracteres alfanuméricos` |
| `GET /usuarios?x=1` | Parámetro no soportado | `400` — `x não é permitido` |
| `PUT /usuarios/{id}` | ID existente | `200` — `Registro alterado com sucesso` |
| `PUT /usuarios/{id}` | ID inexistente | `201` — actúa como *upsert* |
| `DELETE /usuarios/{id}` | ID existente | `200` — `Registro excluído com sucesso` |
| `DELETE /usuarios/{id}` | ID inexistente | `200` — `Nenhum registro excluído` (idempotente) |

---

## 7. Gestión de datos de prueba

ServeRest es un ambiente **público y compartido**: los datos cambian entre
corridas y otros usuarios los modifican. La suite es autosuficiente:

- Cada escenario **crea sus propios datos** con `nuevoUsuario()`, que genera un
  email único derivado de un UUID.
- Cada escenario **elimina lo que creó** (teardown explícito).
- No existe ninguna aserción sobre datos preexistentes del ambiente (ni IDs
  fijos, ni contadores absolutos).

Consecuencia: la suite es repetible, puede correr en paralelo (5 hilos por
defecto) y no deja residuos.

---

## 8. Integración continua (GitHub Actions)

El workflow [`.github/workflows/api-tests.yml`](.github/workflows/api-tests.yml)
ejecuta la suite completa en Ubuntu con JDK 17 (Temurin) y caché de Maven.

| Disparador | Cuándo |
|---|---|
| `push` a `main` | En cada integración |
| `pull_request` a `main` | Antes de aprobar cualquier cambio |
| `schedule` | Regresión de lunes a viernes, 07:00 hora de Lima |
| `workflow_dispatch` | Ejecución manual desde la pestaña **Actions**, con filtro de etiquetas y número de hilos configurables |

Cada ejecución deja:

- Un **resumen** con el conteo de escenarios y features en la portada del run.
- Un **artefacto** (`reporte-karate-N`) con el reporte HTML de Karate —que
  incluye el detalle de cada petición y respuesta— descargable durante 14 días.

La regresión programada tiene un valor extra en este caso: ServeRest es un
ambiente público que cambia, y una corrida diaria detecta cambios de contrato
sin que nadie tenga que ejecutar nada.

---

## 9. Informe de estrategia

El detalle de la estrategia de automatización y los patrones aplicados está en
[ESTRATEGIA.md](ESTRATEGIA.md).
