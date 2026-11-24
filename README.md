# Biblioteca en Movimiento

Proyecto nuevo para administrar préstamos de una biblioteca escolar. Incluye catálogo, roles, préstamos, devoluciones e historial.

## Tecnologías

- **Frontend:** Flutter para Android y web.
- **Backend:** FastAPI.
- **Base de datos:** SQLite para desarrollo local y PostgreSQL en Render para nube.
- **Publicación:** GitHub y Render.
- **IA:** Gemini genera una descripción editable al registrar un libro.

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
2. Crea PostgreSQL en Render y conecta su URL interna como `DATABASE_URL` del Web Service.
3. En Render crea un Web Service desde el repositorio. Render detectará `render.yaml`.
4. Para activar la generación de descripciones, crea una llave de Gemini y guárdala en Render con el nombre `GEMINI_API_KEY`. Nunca subas esa llave a GitHub ni la pegues en el frontend.
