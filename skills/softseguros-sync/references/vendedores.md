# Vendedores de una póliza

Cada vigencia de una póliza puede tener vendedores: las personas de la agencia que reciben una parte
de la comisión. Desde este MCP se buscan los vendedores de la agencia, se ven los de una póliza, se
**agregan** vendedores a una o varias pólizas y se **cambia la lista** de una póliza (el % o la base
de un vendedor, un monto fijo, quitar a alguien). Los repartos entre vendedores se arman y se
cambian en la app (Pólizas › la póliza › Vendedores).

## Contenido

- [Las tools](#las-tools)
- [Asignar un vendedor, paso a paso](#asignar-un-vendedor-paso-a-paso)
- [Cómo leer el % y la base](#cómo-leer-el--y-la-base)
- [Qué responde add_policy_sellers](#qué-responde-add_policy_sellers)
- [Cambiar el %, quitar o reemplazar un vendedor](#cambiar-el--quitar-o-reemplazar-un-vendedor)
- [Quién puede](#quién-puede)
- [Lo que no se hace aquí](#lo-que-no-se-hace-aquí)

## Las tools

| Tool | Qué hace |
| --- | --- |
| `search_sellers` | Lista los vendedores de la agencia. `query` busca por parte del nombre, sin importar tildes ni mayúsculas; `active` es `true` por defecto (solo activos), `false` para los inactivos, `null` para todos. Trae `seller_id`, `name`, `active` y `default_commission`. |
| `get_policy_sellers` | Los vendedores guardados en una vigencia (`unique_key` de `search_policies`): `version`, `origin` y la lista con `pct`, `base`, `fixed_amount`, `source` e `in_split`. Lista vacía con `version` 0: nadie asignó vendedores. |
| `preview_policy_sellers` | Qué pasaría al agregar vendedores, **sin guardar nada**: el % y la base que las reglas de comisión de la agencia le dan a cada uno en esa póliza (`proposed`), si ya está en la póliza (`already_on_policy`) y si se agregaría (`would_be_added`). Trae también los vendedores actuales. |
| `add_policy_sellers` | Agrega vendedores a pólizas (1 a 50 `unique_keys`, 1 a 10 `seller_ids`). **Guarda de inmediato.** |
| `set_policy_sellers` | Reemplaza la lista de vendedores de **una** vigencia: cambiar un %, una base o un monto fijo, quitar o agregar vendedores. Pide la `expected_version` que leíste. **Guarda de inmediato.** |

`get_policy` y `search_policies` ya traen `commission_sellers` en cada póliza; `get_policy_sellers`
sirve cuando necesitas la `version` o la lista limpia de una sola vigencia.

El CRM SoftSeguros tiene su propia tool list_sellers (prefijo `[CRM]`, ids numéricos): son los
vendedores del CRM, no los de comisiones del Sincronizador. Un `seller_id` de uno no sirve en el otro.

## Asignar un vendedor, paso a paso

«Asígnale a Juan Pérez la póliza 1012345678 de SURA.»

1. `search_policies(search="1012345678", carrier="sura")`. Si hay varias vigencias, elige con la
   persona cuál (normalmente la vigente). Copia su `unique_key`.
2. `search_sellers(query="juan perez")`. Si hay dos o más parecidos, pregunta cuál. Si no aparece,
   prueba con un solo apellido o con `active=false`: un vendedor inactivo no se puede agregar (dilo).
3. `preview_policy_sellers(unique_key=<unique_key>, seller_ids=[<seller_id>])`.
4. Muéstrale a la persona: la póliza (número, tomador, aseguradora), quién queda y con qué («Juan
   Pérez, 10 % sobre la comisión de la agencia, por su regla») y los vendedores que ya tenía.
   **Para y espera un «sí» explícito.** Si `already_on_policy` es `true`, ya estaba: no hay nada
   que guardar.
5. `add_policy_sellers(unique_keys=[<unique_key>], seller_ids=[<seller_id>])`.
6. Confirma con lo que respondió `updated` (no con lo que mostraba el preview).

Varias pólizas a la vez (por ejemplo todas las vigentes de un cliente): haz un preview de una o dos
para mostrar el % que saldrá, di que en cada póliza el % lo calculan las reglas de esa póliza (puede
variar por aseguradora, producto o renovación) y, con el «sí», una sola llamada a
`add_policy_sellers` con todas. Más de 50 pólizas: hazlo en la app (Pólizas › seleccionar ›
Agregar vendedores).

## Cómo leer el % y la base

- `pct` es el porcentaje del vendedor sobre su `base`:
  - `net_premium`: la prima neta de la póliza.
  - `agency_commission`: la comisión que la aseguradora le paga a la agencia.
  - `agency_net_received`: esa comisión menos las retenciones de la aseguradora (estimada).
- Los % de varios vendedores **no se suman entre sí** ni tienen que dar 100: cada uno es sobre su
  propia base. Dos vendedores al 10 % sobre la comisión de la agencia reciben 10 % cada uno.
- `in_split: true` marca un reparto: varios vendedores se dividen un mismo porcentaje.
- `fixed_amount` es un monto fijado a mano, en vez del %.
- `source` dice de dónde salió el %: `seller_rule` (una regla de ese vendedor), `seller_default`
  (su comisión por defecto), `all_sellers_rule` (una regla para todos), `default_rule` (la regla
  general de la agencia) o `manual` (alguien lo escribió a mano).

Este MCP no da montos en pesos de la comisión: el % y la base sí, la plata no. Si la persona quiere
saber cuánto le toca a cada uno, está en la app (la tarjeta Vendedores de la póliza), para quien
puede ver comisiones.

## Qué responde add_policy_sellers

| Campo | Qué significa | Qué decir |
| --- | --- | --- |
| `updated` | Pólizas a las que se les agregó al menos un vendedor, con su lista nueva. | Quién quedó en cada una. |
| `already_had` | Pólizas que ya tenían a todos esos vendedores. No se tocaron. | «Ya lo tenía.» |
| `skipped_missing` | `unique_key` que no es una póliza de la agencia. | Casi siempre un id copiado mal: vuelve a buscar la póliza. |
| `skipped_conflict` | Alguien cambió los vendedores de esa póliza mientras tanto, o su lista guardada no se puede ampliar. No se tocó. | `get_policy_sellers` y cuéntale a la persona qué tiene ahora; no reintentes sin mostrárselo. |

`add_policy_sellers` solo **agrega**: los vendedores que ya estaban, su % y sus repartos quedan tal
cual. Si un vendedor de la lista está inactivo, no se guarda nada (todo el pedido falla).

## Cambiar el %, quitar o reemplazar un vendedor

«Ponle a Juan el 15 % en la póliza 1012345678», «Quita a Ana de esa póliza», «Cambia a Ana por Juan».

1. `search_policies` para el `unique_key` y `get_policy_sellers(unique_key=<unique_key>)`: anota la
   `version` y la lista actual. Si algún vendedor tiene `in_split: true`, la póliza tiene un reparto:
   no sigas, dile que eso se cambia en la app.
2. Si entra alguien nuevo, `search_sellers` para su `seller_id` y, si no te dieron el %,
   `preview_policy_sellers` para ver el que le darían las reglas.
3. Muéstrale a la persona la lista **antes y después** (nombre, % y base de cada uno, y quién sale).
   **Para y espera un «sí» explícito.**
4. `set_policy_sellers(unique_key=<unique_key>, expected_version=<version>, sellers=[…])`, con la
   **lista completa que debe quedar**:
   - Cada vendedor que se queda va con su `seller_id`. Lo que no digas (`pct`, `base`,
     `fixed_amount`) queda como estaba.
   - Para cambiar algo, pon solo eso: `{"seller_id": "<id de Juan>", "pct": 15}`.
   - `"fixed_amount": null` quita un monto fijo; un número lo fija.
   - Un vendedor nuevo sin `pct` ni `base` entra con lo que dan las reglas; con ellos, con lo que digas.
   - El que no pongas, **sale**. `sellers=[]` deja la póliza sin vendedores: hazlo solo si la
     persona lo pidió así.
5. Confirma con la respuesta: `sellers` (la lista guardada), `added` y `removed` (nombres).
   `changed: false` quiere decir que la lista ya era esa y no se guardó nada.

Si responde que los vendedores cambiaron mientras tanto, no se guardó nada: vuelve al paso 1, muestra
la lista nueva y pregunta otra vez. No reintentes con la versión nueva sin mostrársela a la persona.

Un vendedor inactivo puede quedarse en la póliza, pero no entrar a una donde no estaba. Para varias
pólizas a la vez, `set_policy_sellers` va de una en una; si solo hay que **agregar**, usa
`add_policy_sellers`, que acepta hasta 50.

## Quién puede

- Buscar vendedores, ver los de una póliza y hacer el preview: cualquier miembro de la agencia.
- Agregar o cambiar vendedores (`add_policy_sellers`, `set_policy_sellers`): Administrador,
  Operación, Comisiones y Operación y comisiones. Consulta no las ve en su catálogo; explícale que
  su rol no asigna vendedores y que lo cambia un administrador en Ajustes › Miembros.

## Lo que no se hace aquí

En la app, no en este MCP:

- Armar o cambiar un reparto entre vendedores (y cualquier cambio en una póliza que ya tiene uno).
- Crear, editar, activar o desactivar vendedores (Comisiones › Vendedores).
- Las reglas que deciden el % (Comisiones › Reglas de comisión).
- Los propietarios de contactos y empresas, las comisiones, extractos y liquidaciones.
