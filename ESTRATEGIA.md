# Informe de estrategia — Reto BackEnd (API Usuarios de ServeRest)

## 1. Objetivo y alcance

Automatizar la validación del CRUD completo del recurso `/usuarios` de
ServeRest: contrato, códigos de estado, esquemas de respuesta, reglas de negocio
y manejo de errores.

**Alcance:** 5 features (uno por endpoint), 34 escenarios — 19 positivos y 15
negativos. Cubre los 5 criterios de aceptación del reto.

---

## 2. Por qué Karate

Además de ser el requisito del reto, Karate resuelve tres cosas que en una suite
de API pesan mucho:

- **Sin capa de código intermedia.** El feature *es* el test. No hay POJOs, ni
  clases cliente, ni mapeo de serialización que mantener.
- **Aserciones sobre estructuras completas.** `match response == esquema` valida
  el JSON entero en una línea, incluyendo tipos y campos no esperados.
- **Reporte con evidencia incorporada.** Cada escenario del HTML muestra la
  petición y la respuesta reales.

---

## 3. Arquitectura de la suite

```
karate-config.js          Configuración global: baseUrl por entorno,
                          helper de datos y catálogo de esquemas
        │
        ├── usuarios/     Un feature por endpoint (los tests)
        │
        ├── helpers/      Features invocables (setup / teardown) + generador de datos
        │
        └── schemas/      Esquemas JSON centralizados
```

### 3.1 Un feature por endpoint

La organización sigue la superficie de la API, no los criterios de aceptación.
Cuando `PUT /usuarios/{_id}` cambie su contrato, hay un único archivo que tocar.
Cada feature declara su `Background` con `url baseUrl`, evitando repetición.

### 3.2 Features invocables como setup/teardown (patrón *callable feature*)

`crear-usuario.feature`, `consultar-usuario.feature` y `eliminar-usuario.feature`
están marcados con `@ignore` (no se ejecutan solos) y se invocan desde los tests:

```gherkin
* def alta = call read('classpath:helpers/crear-usuario.feature')
# ... el test usa alta.usuarioId y alta.usuario ...
* call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }
```

Es el equivalente en Karate a un `@BeforeEach`/`@AfterEach`, con dos ventajas:
es explícito en el feature (se lee qué precondición necesita cada escenario) y
es composable (un escenario puede crear dos usuarios, como el de conflicto de
email en `PUT`).

**Efecto secundario deseado:** el propio setup ejercita el `POST` y el `DELETE`.
Si el alta se rompe, falla toda la suite de inmediato y de forma evidente.

### 3.3 Catálogo central de esquemas

`schemas/esquemas.js` define los 4 contratos de respuesta de la API
(`usuario`, `listaUsuarios`, `registroExitoso`, `mensaje`) y se expone como
variable global. Los features validan así:

```gherkin
And match response == schemas.usuario                 # objeto completo
And match each response.usuarios == schemas.usuario   # todos los elementos del array
```

Si la API agrega un campo a `usuario`, se actualiza **un** archivo y las 34
validaciones quedan alineadas. Sin esta centralización, el esquema estaría
duplicado en cada uno de los 5 features.

### 3.4 Generador de datos

`helpers/nuevo-usuario.js` es una función única y parametrizable:

```gherkin
* def payload = nuevoUsuario()                             # usuario admin válido y único
* def payload = nuevoUsuario({ administrador: 'false' })   # sobreescribe un campo
* def payload = nuevoUsuario({ email: 'correo-invalido' }) # dato inválido a propósito
* def payload = nuevoUsuario({ sinCampo: 'nome' })         # omite un campo obligatorio
```

Una sola función cubre los casos positivos y los negativos, y el `nome`/`email`
salen de un UUID, garantizando unicidad.

> **Nota técnica.** La primera implementación fue un objeto con varios métodos
> que se llamaban entre sí. Falló: Karate evalúa cada expresión JS en un
> contexto nuevo, y las funciones pierden su *closure* al ser invocadas desde un
> feature (`ReferenceError: "generador" is not defined`). La solución fue una
> función autocontenida; queda documentada en el propio archivo para que nadie
> reintroduzca el patrón.

---

## 4. Estrategia de datos: independencia total del ambiente

ServeRest es un ambiente público y compartido — cualquiera puede crear o borrar
registros mientras la suite corre. La regla aplicada es que **ningún escenario
depende de datos que no haya creado él mismo**.

| Anti-patrón evitado | Qué se hizo en su lugar |
|---|---|
| IDs fijos en el código (`0uxuPY0cbmQhpEz1`) | Cada escenario crea su usuario y usa el `_id` devuelto |
| Asertar un total de usuarios (`quantidade == 30`) | Se asserta la coherencia: `quantidade == usuarios.length` |
| Reutilizar un email fijo | Email derivado de UUID en cada llamada |
| Asumir un `_id` inexistente | Se crea un usuario, se elimina, y **ese** `_id` es el inexistente garantizado |

Este último punto es el que sostiene el escenario negativo de `GET /usuarios/{id}`:
un ID inventado podría existir por casualidad; uno recién eliminado, no.

Consecuencia: la suite corre en **paralelo con 5 hilos** sin colisiones y no
deja datos residuales.

---

## 5. Cobertura de casos negativos

15 de los 34 escenarios son negativos, organizados en cuatro familias:

1. **Campos obligatorios ausentes** — `Scenario Outline` sobre los 4 campos.
2. **Valores inválidos** — email mal formado, campos en blanco,
   `administrador` con un valor fuera del dominio.
3. **Reglas de negocio** — email duplicado en `POST` y en `PUT`.
4. **Recursos y parámetros inexistentes** — ID no encontrado, ID mal formado,
   query param no soportado.

Se usa `Scenario Outline` donde la única variación es el dato: los 4 campos
obligatorios son 1 escenario con 4 ejemplos, no 4 escenarios copiados.

---

## 6. Profundidad de las validaciones

El criterio aplicado es que **un `status 200` no valida nada**. Cada escenario
positivo verifica tres niveles:

1. **Código de estado** — `Then status 201`
2. **Contrato de la respuesta** — `And match response == schemas.registroExitoso`
3. **Efecto real sobre el sistema** — se vuelve a consultar el recurso para
   confirmar que los datos se persistieron:

```gherkin
# No basta con que el PUT responda "Registro alterado com sucesso"
* def consulta = call read('classpath:helpers/consultar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }
* match consulta.usuarioConsultado.nome == modificado.nome
* match consulta.usuarioConsultado.administrador == 'false'
```

Lo mismo en `DELETE`: no sólo se comprueba el mensaje, sino que el usuario
**deja de ser consultable** y **desaparece de la lista general**.

Y en `GET /usuarios`, se valida la coherencia interna del contrato:
`quantidade == usuarios.length`.

---

## 7. Hallazgos sobre el contrato real

La suite se construyó sondeando la API real antes de escribir las aserciones.
Dos comportamientos no evidentes quedaron documentados como escenarios
explícitos, con un comentario que aclara que son intencionales:

- **`PUT` sobre un `_id` inexistente responde `201` y crea el usuario** — actúa
  como *upsert*, no como error.
- **`DELETE` sobre un `_id` inexistente responde `200`** con
  `Nenhum registro excluído` — es idempotente, no devuelve 404.

Un tercer caso apareció como fallo durante la primera corrida: se asumía que un
ID mal formado devolvía `Usuário não encontrado`, cuando la API valida el
formato antes de buscar y responde
`id deve ter exatamente 16 caracteres alfanuméricos`. Se corrigió la aserción
—no se relajó— porque el comportamiento real es correcto y la expectativa era
la equivocada.

---

## 8. Estrategia de ejecución

| Nivel | Comando | Cuándo |
|---|---|---|
| Humo | `mvnw test -Dtest=SmokeTest` | En cada commit — 5 escenarios, uno por operación CRUD |
| Completo | `mvnw test` | En el pipeline de integración |
| Focalizado | `mvnw test -Dkarate.options="--tags @negativo"` | Al depurar un área concreta |

El etiquetado (`@usuarios`, `@listar`, `@registrar`, `@buscar`, `@actualizar`,
`@eliminar`, `@positivo`, `@negativo`, `@smoke`, `@CA0x`) permite componer
cualquier subconjunto sin tocar código. Las etiquetas `@CA0x` trazan cada
escenario contra el criterio de aceptación del reto.

---

## 9. Decisiones y compromisos

| Decisión | Razón |
|---|---|
| Maven Wrapper en vez de exigir Maven instalado | El evaluador sólo necesita un JDK 17; `./mvnw test` funciona en cualquier máquina |
| Sin dependencia explícita de JUnit en el `pom.xml` | `karate-junit5` ya la aporta; declararla causaba un desalineamiento entre `junit-platform-engine` y el launcher de Surefire |
| 5 hilos por defecto | La independencia de datos lo permite; baja la suite de ~50 s a ~14 s. Configurable con `-Dkarate.threads=1` |
| Gherkin en inglés | Karate no soporta la internacionalización de palabras clave de Gherkin. Los títulos y comentarios sí están en español |
| Un runner extra para `@smoke`, excluido de Surefire | `mvnw test` corre la suite completa sin duplicar trabajo; el humo se invoca a demanda con `-Dtest=SmokeTest` |

---

## 10. Siguientes pasos naturales

1. Cubrir los recursos `/login`, `/produtos` y `/carrinhos`, incluyendo el flujo
   con token Bearer (la arquitectura de helpers ya lo soporta).
2. Validación de esquema con JSON Schema formal si el proyecto lo exige por
   normativa.
3. Integración en CI con publicación del reporte HTML como artefacto.
4. Pruebas de contrato sobre los tiempos de respuesta
   (`karate.configure('responseTimeout')` + asserts sobre `responseTime`).
