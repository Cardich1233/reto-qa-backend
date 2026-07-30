/**
 * Generador de datos de prueba para la API de Usuarios.
 *
 * Construye un payload de usuario VÁLIDO y ÚNICO (email derivado de un UUID),
 * de modo que cada escenario trabaje con sus propios datos y la suite pueda
 * ejecutarse en paralelo, de forma repetible, contra el ambiente compartido de
 * ServeRest.
 *
 * Uso desde los feature files (se expone como `nuevoUsuario` en karate-config.js):
 *
 *   * def payload = nuevoUsuario()                              // administrador válido
 *   * def payload = nuevoUsuario({ administrador: 'false' })    // sobreescribe un campo
 *   * def payload = nuevoUsuario({ email: 'correo-invalido' })  // dato inválido a propósito
 *   * def payload = nuevoUsuario({ sinCampo: 'nome' })          // omite un campo obligatorio
 *
 * Nota de implementación: la función es autocontenida a propósito. Karate
 * evalúa cada expresión JS en un contexto nuevo, por lo que un objeto de
 * helpers que se referencie a sí mismo pierde su closure al ser invocado
 * desde un feature.
 */
function (opciones) {
  var UUID = Java.type('java.util.UUID');
  var unico = UUID.randomUUID().toString().replace(/-/g, '').substring(0, 12);

  var o = opciones || {};

  var usuario = {
    nome: o.nome == null ? 'Usuario QA ' + unico : o.nome,
    email: o.email == null ? 'qa.reto.' + unico + '@reto-qa.com' : o.email,
    password: o.password == null ? 'Passw0rd!' : o.password,
    administrador: o.administrador == null ? 'true' : o.administrador
  };

  // Permite construir payloads incompletos para los casos negativos.
  if (o.sinCampo != null) {
    delete usuario[o.sinCampo];
  }

  return usuario;
}
