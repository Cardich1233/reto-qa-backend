@usuarios @listar
Feature: GET /usuarios - Listar usuarios
  Como administrador del sistema
  Quiero obtener la lista de usuarios registrados
  Para conocer el estado de la base de usuarios

  Background:
    * url baseUrl

  @positivo @smoke @CA01
  Scenario: Obtener la lista completa de usuarios
    Given path 'usuarios'
    When method get
    Then status 200
    And match response == schemas.listaUsuarios
    And match response.usuarios == '#[_ > 0]'
    And match each response.usuarios == schemas.usuario
    # El contador declarado debe coincidir con los registros devueltos
    And match response.quantidade == response.usuarios.length

  @positivo @CA01
  Scenario: El usuario recién registrado aparece en la lista
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios'
    When method get
    Then status 200
    And match response.usuarios[*]._id contains alta.usuarioId
    And match response.usuarios[*].email contains alta.usuario.email

    # Teardown: la suite no deja datos residuales en el ambiente
    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

  @positivo
  Scenario: Filtrar la lista por un identificador específico
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios'
    And param _id = alta.usuarioId
    When method get
    Then status 200
    And match response.quantidade == 1
    And match response.usuarios[0] == schemas.usuario
    And match response.usuarios[0]._id == alta.usuarioId
    And match response.usuarios[0].nome == alta.usuario.nome

    * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(alta.usuarioId)' }

  @positivo
  Scenario: Filtrar por un email que no existe devuelve una lista vacía
    Given path 'usuarios'
    And param email = nuevoUsuario().email
    When method get
    Then status 200
    And match response.quantidade == 0
    And match response.usuarios == []

  @negativo
  Scenario: Filtrar con un parámetro no soportado es rechazado
    Given path 'usuarios'
    And param parametroInvalido = 'x'
    When method get
    Then status 400
    And match response.parametroInvalido == 'parametroInvalido não é permitido'

  @negativo
  Scenario: Filtrar por email vacío es rechazado
    Given path 'usuarios'
    And param email = ''
    When method get
    Then status 400
    And match response.email == 'email deve ser uma string'
