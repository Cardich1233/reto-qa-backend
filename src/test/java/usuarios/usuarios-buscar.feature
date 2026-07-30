@usuarios @buscar
Feature: GET /usuarios/{_id} - Buscar usuario por ID
  Como administrador del sistema
  Quiero buscar un usuario específico por su identificador
  Para consultar el detalle de su registro

  Background:
    * url baseUrl

  @positivo @smoke @CA03
  Scenario: Buscar un usuario existente por su identificador
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios', alta.usuarioId
    When method get
    Then status 200
    And match response == schemas.usuario
    And match response._id == alta.usuarioId
    And match response.nome == alta.usuario.nome
    And match response.email == alta.usuario.email
    And match response.administrador == alta.usuario.administrador

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

  @positivo @CA03
  Scenario: El detalle del usuario coincide con su registro en la lista
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios', alta.usuarioId
    When method get
    Then status 200
    * def detalle = response

    Given path 'usuarios'
    And param _id = alta.usuarioId
    When method get
    Then status 200
    And match response.usuarios[0] == detalle

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

  @negativo @CA03
  Scenario: Buscar un identificador inexistente devuelve 400
    # Se crea y elimina un usuario para garantizar un _id que ya no existe,
    # sin depender de datos fijos del ambiente compartido.
    * def alta = call read('classpath:helpers/crear-usuario.feature')
    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

    Given path 'usuarios', alta.usuarioId
    When method get
    Then status 400
    And match response == schemas.mensaje
    And match response.message == 'Usuário não encontrado'

  @negativo
  Scenario: Buscar con un identificador de formato inválido devuelve 400
    # La API valida el formato antes de buscar: el _id debe tener exactamente
    # 16 caracteres alfanuméricos, por eso el mensaje difiere del "no encontrado".
    Given path 'usuarios', 'id-con-formato-invalido'
    When method get
    Then status 400
    And match response.id == 'id deve ter exatamente 16 caracteres alfanuméricos'
