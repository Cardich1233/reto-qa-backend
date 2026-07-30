package reto;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Runner principal de la suite: ejecuta todos los feature files de la API de
 * Usuarios y genera el reporte HTML en target/karate-reports.
 *
 * Cada escenario crea y elimina sus propios datos, por lo que la ejecución en
 * paralelo es segura.
 */
class UsuariosTest {

    private static final int HILOS = Integer.parseInt(System.getProperty("karate.threads", "5"));

    @Test
    void ejecutarSuiteDeUsuarios() {
        Results resultados = Runner.path("classpath:usuarios")
                .outputCucumberJson(true)
                .parallel(HILOS);

        assertEquals(0, resultados.getFailCount(), resultados.getErrorMessages());
    }
}
