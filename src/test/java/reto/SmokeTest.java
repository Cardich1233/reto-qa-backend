package reto;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Runner de humo: ejecuta sólo los escenarios etiquetados con @smoke,
 * uno por cada operación CRUD. Pensado para validaciones rápidas en CI.
 */
class SmokeTest {

    @Test
    void ejecutarSmoke() {
        Results resultados = Runner.path("classpath:usuarios")
                .tags("@smoke")
                .outputCucumberJson(true)
                .parallel(3);

        assertEquals(0, resultados.getFailCount(), resultados.getErrorMessages());
    }
}
