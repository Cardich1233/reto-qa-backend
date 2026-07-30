/**
 * Configuración global de Karate.
 * Se ejecuta una vez antes de cada Scenario y expone variables a todos los
 * feature files: baseUrl, generador de datos y catálogo de esquemas JSON.
 */
function fn() {
  var env = karate.env || 'dev';
  karate.log('>> Ejecutando la suite en el entorno:', env);

  var config = {
    env: env,
    baseUrl: 'https://serverest.dev',
    passwordPorDefecto: 'Passw0rd!',
  };

  if (env === 'local') {
    config.baseUrl = 'http://localhost:3000';
  }

  // Helper de datos: `read` sobre un .js devuelve la función lista para invocar.
  config.nuevoUsuario = read('classpath:helpers/nuevo-usuario.js');
  // Catálogo de esquemas JSON: `karate.call` ejecuta la función y expone el objeto.
  config.schemas = karate.call('classpath:schemas/esquemas.js');

  karate.configure('connectTimeout', 30000);
  karate.configure('readTimeout', 30000);
  karate.configure('logPrettyRequest', true);
  karate.configure('logPrettyResponse', true);

  return config;
}
