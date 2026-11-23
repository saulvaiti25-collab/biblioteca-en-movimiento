# Biblioteca en Movimiento

Proyecto nuevo para administrar préstamos de una biblioteca escolar. Incluye catálogo, roles, préstamos, devoluciones e historial.

## Tecnologías

- **Frontend:** Flutter para Android y web.
- **Backend:** FastAPI.
- **Base de datos:** SQLite para desarrollo local y PostgreSQL para nube.
- **Publicación prevista:** GitHub, Render y Aiven PostgreSQL.

## Cuentas de prueba

| Rol | Usuario | Contraseña |
| --- | --- | --- |
| Administrador | `admin` | `Admin123!` |
| Bibliotecario | `bibliotecario` | `Biblio123!` |
| Estudiante | `estudiante` | `Estu123!` |

## Ejecutar localmente

1. Abre una terminal en `backend`.
2. Ejecuta: `C:\Users\jesus\AppData\Local\Programs\Python\Python314\python.exe -m uvicorn main:app --reload --host 0.0.0.0 --port 8000`
3. Abre `http://127.0.0.1:8000/docs` para ver la API.
4. Abre otra terminal en `frontend`, ejecuta `flutter pub get` y después:
   - Chrome: `flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8000`
   - Emulador Android: `flutter run --dart-define=API_URL=http://10.0.2.2:8000`

## Publicar en la nube

1. Sube esta carpeta a un repositorio de GitHub.
2. Crea PostgreSQL en Aiven y copia su URL en `DATABASE_URL` de Render.
3. En Render crea un Web Service desde el repositorio. Render detectará `render.yaml`.
4. Compila Flutter web con `flutter build web --dart-define=API_URL=https://TU-API.onrender.com` y publícalo como sitio estático.
