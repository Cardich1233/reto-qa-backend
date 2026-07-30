@usuarios @actualizar
Feature: PUT /usuarios/{_id} - Actualizar usuario
  Como administrador del sistema
  Quiero actualizar la información de un usuario existente
  Para mantener la base de usuarios al día

  Background:
    * url baseUrl

  @positivo @smoke @CA04
  Scenario: Actualizar todos los datos de un usuario existente
    * def alta = call read('classpath:helpers/crear-usuario.feature')
    * def modificado = nuevoUsuario({ administrador: 'false' })

    Given path 'usuarios', alta.usuarioId
    And request modificado
    When method put
    Then status 200
    And match response == schemas.mensaje
    And match response.message == 'Registro alterado com sucesso'

    # Los cambios quedan efectivamente persistidos
    * def consulta = call read('classpath:helpers/consultar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }
    * match consulta.usuarioConsultado.nome == modificado.nome
    * match consulta.usuarioConsultado.email == modificado.email
    * match consulta.usuarioConsultado.administrador == 'false'
    * match consulta.usuarioConsultado._id == alta.usuarioId

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

  @positivo @CA04
  Scenario: Actualizar únicamente el nombre conservando el resto de los datos
    * def alta = call read('classpath:helpers/crear-usuario.feature')
    * def modificado = karate.merge(alta.usuario, { nome: 'Nombre Actualizado QA' })

    Given path 'usuarios', alta.usuarioId
    And request modificado
    When method put
    Then status 200
    And match response.message == 'Registro alterado com sucesso'

    * def consulta = call read('classpath:helpers/consultar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }
    * match consulta.usuarioConsultado.nome == 'Nombre Actualizado QA'
    * match consulta.usuarioConsultado.email == alta.usuario.email

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

  @positivo
  Scenario: Actualizar un identificador inexistente registra un usuario nuevo
    # Comportamiento documentado de ServeRest: el PUT actúa como upsert (201).
    * def alta = call read('classpath:helpers/crear-usuario.feature')
    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }
    * def nuevo = nuevoUsuario()

    Given path 'usuarios', alta.usuarioId
    And request nuevo
    When method put
    Then status 201
    And match response == schemas.registroExitoso
    And match response.message == 'Cadastro realizado com sucesso'

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(response._id)' }

  @negativo
  Scenario: No se permite actualizar usando el email de otro usuario
    * def primero = call read('classpath:helpers/crear-usuario.feature')
    * def segundo = call read('classpath:helpers/crear-usuario.feature')
    * def conflicto = nuevoUsuario({ email: primero.usuario.email })

    Given path 'usuarios', segundo.usuarioId
    And request conflicto
    When method put
    Then status 400
    And match response.message == 'Este email já está sendo usado'

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(primero.usuarioId)' }
    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(segundo.usuarioId)' }

  @negativo
  Scenario Outline: Actualizar con el campo <campo> inválido es rechazado
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios', alta.usuarioId
    And request nuevoUsuario({ <campo>: '<valor>' })
    When method put
    Then status 400
    And match response.<campo> == "<mensaje>"

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

    Examples:
      | campo         | valor           | mensaje                                  |
      | email         | correo-invalido | email deve ser um email válido           |
      | administrador | quizas          | administrador deve ser 'true' ou 'false' |

  @negativo
  Scenario: Actualizar con el cuerpo vacío informa los campos obligatorios
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios', alta.usuarioId
    And request {}
    When method put
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

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }
