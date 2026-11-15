# Peticiones de Postman · User Service

Colección para probar la API REST de `user-service` desde Postman o Postman CLI.

## Archivos

| Archivo | Uso |
| --- | --- |
| `collections/user-service.postman_collection.json` | 22 peticiones con tests automáticos |
| `environments/user-service.local.postman_environment.json` | `baseUrl` y credenciales locales |
| `setup-rabbitmq.ps1` | Prepara RabbitMQ local (exchange, cola y binding) |
| `mocks/` y `simulations/` | Simulación local usada por las pruebas E2E de Playwright |

## 1. Backend y RabbitMQ

El backend debe estar en `http://localhost:8080`:

```powershell
cd ..\..\user-service
docker compose up -d
```

Las operaciones de escritura (`POST`, `PUT`, `DELETE`) publican un evento de dominio. Si RabbitMQ no está disponible, el dato se guarda pero el API responde **503**. Para preparar un RabbitMQ local desechable:

```powershell
# Desde la raíz de user-crud-vuejs-app
powershell -ExecutionPolicy Bypass -File postman/setup-rabbitmq.ps1
```

El script crea el contenedor `user-service-rabbitmq` (puertos `5672` y `15672`), declara el exchange `domain.events`, la cola `domain.events.postman` y un binding `#`. Es idempotente: puedes ejecutarlo varias veces.

## 2. Importar en Postman

1. Abre Postman → **Import**.
2. Importa `collections/user-service.postman_collection.json`.
3. Importa `environments/user-service.local.postman_environment.json`.
4. Selecciona el environment **User Service · Local**.

## 3. Ejecutar

En Postman, abre la colección y usa **Run collection**. También puedes ejecutarla por CLI:

```powershell
npm run test:postman
```

O directamente:

```powershell
postman collection run "postman/collections/user-service.postman_collection.json" -e "postman/environments/user-service.local.postman_environment.json" --no-report-events
```

`postman login` es opcional; solo hace falta para publicar el reporte en la nube.

## Credenciales

El `schema.sql` del backend crea el administrador. La contraseña no se guarda en el repositorio: escríbela en la variable `adminPassword` del environment.

- Email: `admin@example.com`
- Contraseña: la definida en el `schema.sql` de tu backend local.

Cambia estos valores en el environment si tu base de datos usa otros.

## Qué cubre

- `GET /health`.
- Login correcto, credenciales inválidas y validación de campos.
- Acceso sin token (401).
- Creación pública con `201` y estado `PENDING`.
- Creación idempotente con el mismo `id` y datos (`200`).
- Conflicto con el mismo `id` y datos distintos (`409`).
- Listado y consulta individual.
- Login de una cuenta `PENDING` (`401`).
- Activación por un ADMIN (`PUT`), conservando la contraseña si se envía vacía.
- Login del usuario activado y permisos de `MEMBER` (`403` en listado y edición).
- Correo duplicado en edición (`409`).
- Eliminación (`204`) y consulta posterior (`404`).
- Errores de validación y rol inexistente (`400`).

El flujo genera un UUID y un correo únicos en cada ejecución, y elimina el usuario al final. La última petición de limpieza acepta `204` o `404`, así que puedes repetir la colección sin dejar registros de prueba.

## Pruebas E2E con la simulación

La carpeta `mocks/` y `simulations/` alimenta los tests de Playwright. No tocan la base real: la app Vue se prueba contra una simulación local del contrato.

```powershell
npx playwright install chromium
npm run test:e2e
```

Playwright levanta la simulación en el puerto `4010` y Vite en el `5173`; ambos deben estar libres. La CLI de Postman 1.90 está en `devDependencies`, así que no necesitas instalarla globalmente. El registro HTTP queda en `postman/simulation.log`.

## Notas

- La colección guarda `accessToken` y `memberToken` automáticamente en variables de colección.
- Si ejecutas una petición del flujo CRUD por separado, ejecuta antes **1. Crear usuario** o define `testUserId` y `testEmail` manualmente.
- La colección de backend y la simulación E2E son independientes: la primera prueba el API real; la segunda prueba la interfaz sin tocar datos reales.
- El contenedor de RabbitMQ se puede detener con `docker stop user-service-rabbitmq` y eliminar con `docker rm -f user-service-rabbitmq`.
