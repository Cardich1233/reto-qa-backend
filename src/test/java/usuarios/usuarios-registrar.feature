@usuarios @registrar
Feature: POST /usuarios - Registrar usuario
  Como administrador del sistema
  Quiero registrar nuevos usuarios con datos válidos
  Para incorporarlos a la base de usuarios

  Background:
    * url baseUrl
    * path 'usuarios'

  @positivo @smoke @CA02
  Scenario: Registrar un usuario administrador con datos válidos
    * def payload = nuevoUsuario()

    Given request payload
    When method post
    Then status 201
    And match response == schemas.registroExitoso
    And match response.message == 'Cadastro realizado com sucesso'
    And match response._id == '#regex ^[A-Za-z0-9]{16}$'

    # El recurso creado es consultable y conserva los datos enviados
    * def creado = call read('classpath:helpers/consultar-usuario.feature') { usuarioId: '#(response._id)' }
    * match creado.usuarioConsultado.nome == payload.nome
    * match creado.usuarioConsultado.email == payload.email
    * match creado.usuarioConsultado.administrador == 'true'

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(creado.usuarioId)' }

  @positivo @CA02
  Scenario: Registrar un usuario no administrador
    * def payload = nuevoUsuario({ administrador: 'false' })

    Given request payload
    When method post
    Then status 201
    And match response == schemas.registroExitoso

    * def creado = call read('classpath:helpers/consultar-usuario.feature') { usuarioId: '#(response._id)' }
    * match creado.usuarioConsultado.administrador == 'false'

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(creado.usuarioId)' }

  @negativo
  Scenario: No se permite registrar dos usuarios con el mismo email
    * def alta = call read('classpath:helpers/crear-usuario.feature')
    * def duplicado = nuevoUsuario({ email: alta.usuario.email })

    Given request duplicado
    When method post
    Then status 400
    And match response == schemas.mensaje
    And match response.message == 'Este email já está sendo usado'

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

  @negativo
  Scenario Outline: Registrar sin el campo obligatorio <campo> es rechazado
    Given request nuevoUsuario({ sinCampo: '<campo>' })
    When method post
    Then status 400
    And match response.<campo> == "<mensaje>"

    Examples:
      | campo         | mensaje                       |
      | nome          | nome é obrigatório            |
      | email         | email é obrigatório           |
      | password      | password é obrigatório        |
      | administrador | administrador é obrigatório   |

  @negativo
  Scenario Outline: Registrar con el campo <campo> inválido es rechazado
    Given request nuevoUsuario({ <campo>: '<valor>' })
    When method post
    Then status 400
    And match response.<campo> == "<mensaje>"

    Examples:
      | campo         | valor            | mensaje                                  |
      | email         | correo-invalido  | email deve ser um email válido           |
      | email         |                  | email não pode ficar em branco           |
      | nome          |                  | nome não pode ficar em branco            |
      | password      |                  | password não pode ficar em branco        |
      | administrador | quizas           | administrador deve ser 'true' ou 'false' |

  @negativo
  Scenario: Registrar con el cuerpo vacío informa todos los campos obligatorios
    Given request {}
    When method post
    Then status 400
    And match response ==
      """
      {
        nome: 'nome é obrigatório',
        email: 'email é obrigatório',
        password: 'password é obrigatório',
        administrador: 'administrador é obrigatório'
      }
      """
