/**
 * Catálogo central de esquemas JSON.
 *
 * Se consumen desde los feature files con la sintaxis de validación de Karate:
 *   * match response == schemas.usuario
 *   * match response.usuarios == '#[] schemas.usuario'
 *
 * Marcadores usados:
 *   #string  -> presente y de tipo string
 *   #number  -> presente y numérico
 *   #notnull -> presente y no nulo
 *   #regex   -> valida el contenido contra una expresión regular
 */
function () {
  var esquemas = {

    /** Usuario tal como lo devuelve GET /usuarios y GET /usuarios/{_id} */
    usuario: {
      nome: '#string',
      email: '#string',
      password: '#string',
      administrador: '#regex ^(true|false)$',
      _id: '#string'
    },

    /** Envoltorio de la lista: GET /usuarios */
    listaUsuarios: {
      quantidade: '#number',
      usuarios: '#[]'
    },

    /** Respuesta de POST /usuarios exitoso (201) */
    registroExitoso: {
      message: '#string',
      _id: '#string'
    },

    /** Respuesta genérica de mensaje: PUT / DELETE / errores de negocio */
    mensaje: {
      message: '#string'
    }
  };

  return esquemas;
}
