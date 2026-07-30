@ignore
Feature: Helper reutilizable - alta de usuario

  # Se invoca con:  * def alta = call read('classpath:helpers/crear-usuario.feature')
  # Opcionalmente recibe `usuarioSolicitado` para forzar un payload específico:
  #   * def alta = call read('classpath:helpers/crear-usuario.feature') { usuarioSolicitado: '#(payload)' }
  # Devuelve: usuarioId, usuario (payload enviado)

  Scenario: Registra un usuario y expone su identificador
    * def payload = karate.get('usuarioSolicitado', nuevoUsuario())
    Given url baseUrl
    And path 'usuarios'
    And request payload
    When method post
    Then status 201
    * def usuarioId = response._id
    * def usuario = payload
