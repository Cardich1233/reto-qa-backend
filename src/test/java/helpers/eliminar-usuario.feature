@ignore
Feature: Helper reutilizable - baja de usuario

  # Limpieza de datos al final de cada escenario (teardown):
  #   * call read('classpath:helpers/eliminar-usuario.feature') { usuarioId: '#(usuarioId)' }

  Scenario: Elimina el usuario indicado
    Given url baseUrl
    And path 'usuarios', usuarioId
    When method delete
    Then status 200
    And match response.message == 'Registro excluído com sucesso'
