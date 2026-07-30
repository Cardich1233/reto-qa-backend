@usuarios @eliminar
Feature: DELETE /usuarios/{_id} - Eliminar usuario
  Como administrador del sistema
  Quiero eliminar usuarios del sistema
  Para depurar la base de usuarios

  Background:
    * url baseUrl

  @positivo @smoke @CA05
  Scenario: Eliminar un usuario existente
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios', alta.usuarioId
    When method delete
    Then status 200
    And match response == schemas.mensaje
    And match response.message == 'Registro excluído com sucesso'

  @positivo @CA05
  Scenario: El usuario eliminado deja de estar disponible
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios', alta.usuarioId
    When method delete
    Then status 200

    # Ya no se puede consultar por su identificador
    Given path 'usuarios', alta.usuarioId
    When method get
    Then status 400
    And match response.message == 'Usuário não encontrado'

    # Ni aparece en la lista general
    Given path 'usuarios'
    When method get
    Then status 200
    And match response.usuarios[*]._id !contains alta.usuarioId

  @positivo
  Scenario: Eliminar un identificador inexistente no produce error
    # Comportamiento documentado de ServeRest: el DELETE es idempotente (200).
    * def alta = call read('classpath:helpers/crear-usuario.feature')

    Given path 'usuarios', alta.usuarioId
    When method delete
    Then status 200
    And match response.message == 'Registro excluído com sucesso'

    Given path 'usuarios', alta.usuarioId
    When method delete
    Then status 200
    And match response == schemas.mensaje
    And match response.message == 'Nenhum registro excluído'

  @negativo
  Scenario: Eliminar con un identificador de formato inválido no elimina nada
    Given path 'usuarios', 'id-con-formato-invalido'
    When method delete
    Then status 200
    And match response.message == 'Nenhum registro excluído'
