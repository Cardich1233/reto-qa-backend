@ignore
Feature: Helper reutilizable - consulta de usuario por identificador

  # Se invoca con:
  #   * def consulta = call read('classpath:helpers/consultar-usuario.feature') { usuarioId: '#(id)' }
  # Devuelve: usuarioId, usuarioConsultado

  Scenario: Consulta un usuario existente por su _id
    Given url baseUrl
    And path 'usuarios', usuarioId
    When method get
    Then status 200
    * def usuarioConsultado = response
