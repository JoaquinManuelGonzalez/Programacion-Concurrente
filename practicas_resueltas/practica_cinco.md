# Práctica 5 - Rendezvous (ADA)

## Ejercicio 1

Se requiere modelar un puente de un único sentido que soporta hasta 5 unidades de peso. El peso de los vehículos depende del tipo: cada auto pesa 1 unidad, cada camioneta pesa 2 unidades y cada camión 3 unidades. Suponga que hay una cantidad innumerable de vehículos (A autos, B camionetas y C camiones). Analice el problema y defina qué tareas, recursos y sincronizaciones serán necesarios/convenientes para resolverlo. 
- **a)** Realice la solución suponiendo que todos los vehículos tienen la misma prioridad. 
- **b)** Modifique la solución para que tengan mayor prioridad los camiones que el resto de los vehículos.

### Respuestas

**a)**

```ADA
PROCEDURE Puente IS
    TASK Paso IS
        ENTRY AccesoA;
        ENTRY AccesoB;
        ENTRY AccesoC;
        ENTRY Salir (peso: IN int);
    END Paso;

    TASK TYPE Auto
    arrAutos: array (1..A) of Auto;
    TASK BODY Auto IS
        peso: int;
    BEGIN
        peso = 1;
        Paso.AccesoA;
        Paso.Salir(peso);
    END Auto;

    TASK TYPE Camioneta
    arrCamionetas: array (1..B) of Camioneta;
    TASK BODY Camioneta IS
        peso: int;
    BEGIN
        peso = 2;
        Paso.AccesoB;
        Paso.Salir(peso);
    END Camioneta;

    TASK TYPE Camion
    arrCamiones: array (1..B) of Camion;
    TASK BODY Camion IS
        peso: int;
    BEGIN
        peso = 3;
        Paso.AccesoC;
        Paso.Salir(peso);
    END Camion;

    TASK BODY Paso IS
        pesoActual: int;
    BEGIN
        pesoActual = 0;
        LOOP
            SELECT
                when (pesoActual < 5) → ACCEPT AccesoA DO
                    pesoActual = pesoActual + 1;
                END AccesoA;
            OR
                when (pesoActual < 4) → ACCEPT AccesoB DO
                    pesoActual = pesoActual + 2;
                END AccesoB;
            OR
                when (pesoActual < 3) → ACCEPT AccesoC DO
                    pesoActual = pesoActual + 3;
                END AccesoC;
            OR
                ACCEPT Salir (peso: IN int) DO
                    pesoActual = pesoActual - peso;
                END Salir;
            END SELECT;
        END LOOP;
    END Paso;

BEGIN
    null;
END Puente;
```

**b)**

```ADA
PROCEDURE Puente IS
    TASK Paso IS
        ENTRY AccesoA;
        ENTRY AccesoB;
        ENTRY AccesoC;
        ENTRY Salir (peso: IN int);
    END Paso;

    TASK TYPE Auto
    arrAutos: array (1..A) of Auto;
    TASK BODY Auto IS
        peso: int;
    BEGIN
        peso = 1;
        Paso.AccesoA;
        Paso.Salir (peso);
    END Auto;

    TASK TYPE Camioneta
    arrCamionetas: array (1..B) of Camioneta;
    TASK BODY Camioneta IS
        peso: int;
    BEGIN
        peso = 2;
        Paso.AccesoB;
        Paso.Salir (peso);
    END Camioneta;

    TASK TYPE Camion
    arrCamiones: array (1..B) of Camion;
    TASK BODY Camion IS
        peso: int;
    BEGIN
        peso = 3;
        Paso.AccesoC;
        Paso.Salir (peso);
    END Camion;

    TASK BODY Paso IS
        pesoActual: int;
    BEGIN
        pesoActual = 0;
        LOOP
            SELECT
                when (((AccesoC'COUNT = 0) OR (pesoActual >= 3)) AND (pesoActual < 5)) → ACCEPT AccesoA DO
                    pesoActual = pesoActual + 1;
                END AccesoA;
            OR
                when (((AccesoC'COUNT = 0) OR (pesoActual = 3)) AND (pesoActual < 4)) → ACCEPT AccesoB DO
                    pesoActual = pesoActual + 2;
                END AccesoB;
            OR
                when (pesoActual < 3) → ACCEPT AccesoC DO
                    pesoActual = pesoActual + 3;
                END AccesoC;
            OR
                ACCEPT Salir (peso: IN int) DO
                    pesoActual = pesoActual - peso;
                END Salir;
            END SELECT;
        END LOOP;
    END Paso;

BEGIN
    null;
END Puente;
```

# Ejercicio 2

Se quiere modelar el funcionamiento de un banco, al cual llegan clientes que deben realizar un pago y retirar un comprobante. Existe un único empleado en el banco, el cual atiende de acuerdo con el orden de llegada.  
- **a)** Implemente una solución donde los clientes llegan y se retiran sólo después de haber sido atendidos. 
- **b)** Implemente una solución donde los clientes se retiran si esperan más de 10 minutos para realizar el pago. 
- **c)** Implemente una solución donde los clientes se retiran si no son atendidos inmediatamente. 
- **d)** Implemente una solución donde los clientes esperan a lo sumo 10 minutos para ser atendidos. Si pasado ese lapso no fueron atendidos, entonces solicitan atención una vez más y se retiran si no son atendidos inmediatamente.

### Respuestas

**a)**

```ADA
PROCEDURE Banco IS
    TASK Empleado IS
        ENTRY Atencion (pago: IN Pago; comprobante: OUT Comprobante);
    END Empleado;

    TASK TYPE Cliente
    arrCliente: array (1..N) of Cliente;
    TASK BODY Cliente IS
        pago: Pago;
        comprobante: Comprobante;
    BEGIN
        pago = ...;
        Empleado.Atencion (pago, comprobante);
    END Cliente;

    TASK BODY Empleado IS
    BEGIN
        LOOP
            ACCEPT Atencion (pago: IN Pago; comprobante: OUT Comprobante) DO
                comprobante = GenerarComprobante(pago);
            END Atencion;
        END LOOP;
    END Empleado;

BEGIN 
    null;
END Banco;
```

**b)** El **OR DELAY** usa el tiempo en segundos.

```ADA
PROCEDURE Banco IS
    TASK Empleado IS
        ENTRY Atencion (pago: IN Pago; comprobante: OUT Comprobante);
    END Empleado;

    TASK TYPE Cliente
    arrCliente: array (1..N) of Cliente;
    TASK BODY Cliente IS
        pago: Pago;
        comprobante: Comprobante;
    BEGIN
        pago = ...;
        SELECT
            Empleado.Atencion (pago, comprobante);
        OR DELAY 600
            null;
        END SELECT;
    END Cliente;

    TASK BODY Empleado IS
    BEGIN
        LOOP
            ACCEPT Atencion (pago: IN Pago; comprobante: OUT Comprobante) DO
                comprobante = GenerarComprobante(pago);
            END Atencion;
        END LOOP;
    END Empleado;

BEGIN 
    null;
END Banco;
```

**c)**

```ADA
PROCEDURE Banco IS
    TASK Empleado IS
        ENTRY Atencion (pago: IN Pago; comprobante: OUT Comprobante);
    END Empleado;

    TASK TYPE Cliente
    arrCliente: array (1..N) of Cliente;
    TASK BODY Cliente IS
        pago: Pago;
        comprobante: Comprobante;
    BEGIN
        pago = ...;
        SELECT
            Empleado.Atencion (pago, comprobante);
        ELSE
            null;
        END SELECT;
    END Cliente;

    TASK BODY Empleado IS
    BEGIN
        LOOP
            ACCEPT Atencion (pago: IN Pago; comprobante: OUT Comprobante) DO
                comprobante = GenerarComprobante(pago);
            END Atencion;
        END LOOP;
    END Empleado;

BEGIN 
    null;
END Banco;
```

**d)**

```ADA
PROCEDURE Banco IS
    TASK Empleado IS
        ENTRY Atencion (pago: IN Pago; comprobante: OUT Comprobante);
    END Empleado;

    TASK TYPE Cliente
    arrCliente: array (1..N) of Cliente;
    TASK BODY Cliente IS
        pago: Pago;
        comprobante: Comprobante;
    BEGIN
        pago = ...;
        SELECT
            Empleado.Atencion (pago, comprobante);
        OR DELAY 600
            SELECT
                Empleado.Atencion (pago, comprobante);
            ELSE
                null;
            END SELECT;
        END SELECT;
    END Cliente;

    TASK BODY Empleado IS
    BEGIN
        LOOP
            ACCEPT Atencion (pago: IN Pago; comprobante: OUT Comprobante) DO
                comprobante = GenerarComprobante(pago);
            END Atencion;
        END LOOP;
    END Empleado;

BEGIN 
    null;
END Banco;
```

## Ejercicio 3

Se dispone de un sistema compuesto por **1 central y 2 procesos periféricos**, que se comunican continuamente. Se requiere modelar su funcionamiento considerando las siguientes condiciones:
- La central siempre comienza su ejecución tomando una señal del proceso 1; luego toma aleatoriamente señales de cualquiera de los dos indefinidamente. Al recibir una señal de proceso 2, recibe señales del mismo proceso durante 3 minutos. 
- Los procesos periféricos envían señales continuamente a la central. La señal del proceso 1 será considerada vieja (se deshecha) si en 2 minutos no fue recibida. Si la señal del proceso 2 no puede ser recibida inmediatamente, entonces espera 1 minuto y vuelve a mandarla (no se deshecha).

### Respuesta

```ADA
PROCEDURE Sistema IS
    TASK Central IS
        ENTRY RecibirSenialPerifericoUno (senial: IN Senial);
        ENTRY RecibirSenialPerifericoDos (senial: IN Senial);
        ENTRY RecibirAviso;
    END Central;

    TASK PerifericoUno
    TASK BODY PerifericoUno IS
        senial: Senial;
    BEGIN
        LOOP
            senial = GenerarSenial();
            SELECT
                Central.RecibirSenialPerifericoUno (senial);
            OR DELAY 120
                null;
            END SELECT;
        END LOOP;
    END PerifericoUno;

    TASK PerifericoDos
    TASK BODY PerifericoDos IS
        senial: Senial;
    BEGIN
        senial = GenerarSenial();
        LOOP
            SELECT
                Central.RecibirSenialPerifericoDos (senial);
                senial = GenerarSenial();
            ELSE
                DELAY 60;
            END SELECT;
        END LOOP;
    END PerifericoDos;

    TASK Timer IS
        ENTRY InicioTimer;
    TASK BODY Timer IS
    BEGIN
        ACCEPT InicioTimer;
        DELAY(180);
        Central.RecibirAviso;
    END Timer;

    TASK BODY Central IS
        continuar: Boolean;
    BEGIN
        ACCEPT RecibirSenialPerifericoUno (senial: IN Senial);
        LOOP
            SELECT
                ACCEPT RecibirSenialPerifericoUno (senial: IN Senial);
            OR
                ACCEPT RecibirSenialPerifericoDos (senial: IN Senial);
                continuar = True;
                Timer.InicioTimer;
                LOOP (continuar)
                    SELECT
                        WHEN (RecibirAviso'COUNT = 0) → ACCEPT RecibirSenialPerifericoDos (senial: IN Senial);
                    OR
                        ACCEPT RecibirAviso;
                        continuar = False;
                    END SELECT;
                END LOOP;
            END SELECT;
        END LOOP;
    END Central;

BEGIN
    null;
END Sistema;
```

## Ejercicio 4

En una clínica existe un **médico** de guardia que recibe continuamente peticiones de atención de las **E enfermeras** que trabajan en su piso y de las **P personas** que llegan a la clínica ser atendidos.  
Cuando una persona necesita que la atiendan espera a lo sumo 5 minutos a que el médico lo haga, si pasado ese tiempo no lo hace, espera 10 minutos y vuelve a requerir la atención del médico. Si no es atendida tres veces, se enoja y se retira de la clínica. 
Cuando una enfermera requiere la atención del médico, si este no lo atiende inmediatamente le hace una nota y se la deja en el consultorio para que esta resuelva su pedido en el momento que pueda (el pedido puede ser que el médico le firme algún papel). Cuando la petición ha sido recibida por el médico o la nota ha sido dejada en el escritorio, continúa trabajando y haciendo más peticiones.
El médico atiende los pedidos dándole prioridad a los enfermos que llegan para ser atendidos. Cuando atiende un pedido, recibe la solicitud y la procesa durante un cierto tiempo. Cuando está libre aprovecha a procesar las notas dejadas por las enfermeras.

### Respuesta (CONSULTAR BUSY WAITING MEDICO)

```ADA
PROCEDURE Clinica IS
    TASK Medico IS
        ENTRY AtenderEnfermera (pedido: IN Pedido);
        ENTRY AtenderPersona;
    END Medico;
    TASK BODY Medico IS
        pedidoEnfermera: Pedido;
    BEGIN
        LOOP
            SELECT
                WHEN (AtenderPersona'COUNT = 0) → ACCEPT AtenderEnfermera (pedido: IN Pedido) DO 
                    pedidoEnfermera = pedido;
                END AtenderEnfermera;
                ProcesarPedido (pedidoEnfermera);
            OR
                ACCEPT AtenderPersona DO
                    -- Atender Paciente;
                END AtenderPersona;
            ELSE
                Consultorio.RetirarNota(pedidoEnfermera);
                IF (pedidoEnfermera != "") THEN
                    ProcesarPedido (pedidoEnfermera);
                END IF;
            END SELECT;
        END LOOP;
    END Medico;

    TASK Consultorio IS
        ENTRY RecibirNota (nota: IN Pedido);
        ENTRY RetirarNota (nota: OUT Pedido);
    END Consultorio;
    TASK BODY Consultorio IS
        colaNotas: Cola;
    BEGIN
        LOOP
            SELECT
                ACCEPT RecibirNota (nota: IN Pedido) DO
                    Push (colaNotas, nota);
                END RecibirNota;
            OR
                ACCEPT RetirarNota (nota: OUT Pedido) DO
                    IF (NOT Empty (colaNotas)) THEN
                        nota = Pop (colaNotas);
                    ELSE
                        nota = "";
                    END IF;
                END RetirarNota;
            END SELECT;
        END LOOP;
    END Consultorio;

    TASK TYPE Enfermera
    arrEnfermeras: array (1..E) of Enfermera;
    TASK BODY Enfermera IS
        pedido, nota: Pedido;
    BEGIN
        LOOP
            pedido = GenerarPedido ();
            SELECT
                Medico.AtenderEnfermera(pedido);
            ELSE
                nota = GenerarNota (pedido);
                Consultorio.RecibirNota(nota);
            END SELECT;
        END LOOP;
    END Enfermera;

    TASK TYPE Persona
    arrPersonas: array (1..P) of Persona;
    TASK BODY Persona IS
        intentos: int;
        continuar: Boolean;
    BEGIN
        intentos = 0;
        continuar = True;
        LOOP ((intentos < 3) AND (continuar))
            SELECT
                Medico.AtenderPersona;
                continuar = False;
            OR DELAY 300
                intentos = intentos + 1;
                IF (intentos < 3) THEN
                    DELAY 600;
                END IF;
            END SELECT;
        END LOOP;
    END Persona;

BEGIN
    null;
END Clinica;
```

## Ejercicio ?

En un sistema para acreditar carreras universitarias, hay UN Servidor que atiende pedidos de U Usuarios de a uno a la vez y de acuerdo con el orden en que se hacen los pedidos. Cada usuario trabaja en el documento a presentar, y luego lo envía al servidor; espera la respuesta de este que le indica si está todo bien o hay algún error. Mientras haya algún error, vuelve a trabajar con el documento y a enviarlo al servidor. Cuando el servidor le responde que está todo bien, el usuario se retira. Cuando un usuario envía un pedido espera a lo sumo 2 minutos a que sea recibido por el servidor, pasado ese tiempo espera un minuto y vuelve a intentarlo (usando el mismo documento).

### Respuesta ?

```ADA
PROCEDURE Sistema IS
    TASK Servidor IS
        ENTRY RecibirDocumento (documento: IN Documento; correcto: OUT Boolean);
    END Servidor;
    TASK BODY Servidor IS
    BEGIN
        LOOP
            ACCEPT RecibirDocumento (documento: IN Documento; correcto: OUT Boolean) DO
                correcto = EvaluarDocumento (documento);
            END RecibirDocumento;
        END LOOP;
    END Servidor;

    TASK TYPE Usuario
    arrUsuarios: array (1..U) of Usuario;
    TASK BODY Usuario IS
        documento: Documento;
        correcto: Boolean;
    BEGIN
        correcto = False;
        documento = TrabajarDocumento ();
        LOOP (NOT correcto)
            SELECT
                Servidor.RecibirDocumento (documento, correcto);
                IF (NOT correcto) THEN
                    documento = ArreglarDocumento (documento);
                END IF;
            OR DELAY 120
                DELAY 60;
            END SELECT;
        END LOOP;
    END Usuario;

BEGIN
    null;
END Sistema;
```

## Ejercicio 5

En una playa hay 5 equipos de 4 personas cada uno (en total son 20 personas donde cada una conoce previamente a que equipo pertenece). Cuando las personas van llegando esperan con los de su equipo hasta que el mismo esté completo (hayan llegado los 4 integrantes), a partir de ese momento el equipo comienza a jugar. El juego consiste en que cada integrante del grupo junta 15 monedas de a una en una playa (las monedas pueden ser de 1, 2 o 5 pesos) y se suman los montos de las 60 monedas conseguidas en el grupo. Al finalizar cada persona debe conocer el grupo que más dinero junto. **Nota:** maximizar la concurrencia. Suponga que para simular la búsqueda de una moneda por parte de una persona existe una función Moneda() que retorna el valor de la moneda encontrada.

### Respuesta

```ADA
PROCEDURE Juego IS
    TASK Administrador IS
        ENTRY FinalizarEquipo (idEquipo: IN int; totalJuntado: IN int);
        ENTRY ConsultarGanador (idEquipo: OUT int);
    END Administrador;
    TASK BODY Administrador IS
        idEquipoGanador, totalMaximo: int;
    BEGIN
        totalMaximo = -1;
        FOR i IN 1..5 LOOP
            ACCEPT FinalizarEquipo (idEquipo: IN int; totalJuntado: IN int) DO
                IF (totalJuntado > totalMaximo) THEN
                    totalMaximo = totalJuntado;
                    idEquipoGanador = idEquipo;
                END IF;
            END FinalizarEquipo;
        END LOOP;
        FOR i IN 1..20 LOOP
            ACCEPT ConsultarGanador (idEquipo: OUT int) DO
                idEquipo = idEquipoGanador;
            END ConsultarGanador;
        END LOOP;
    END Administrador;

    TASK TYPE Equipo IS
        ENTRY RecibirIdentificacion (nroId: IN int);
        ENTRY LlegadaBarrera;
        ENTRY SalidaBarrera;
        ENTRY SumarAlTotal (cantidadSumada: IN int);
    END Equipo;
    arrEquipos: array (1..5) of Equipo;
    TASK BODY Equipo IS
        id, totalDeEquipo: int;
    BEGIN
        totalDeEquipo = 0;
        ACCEPT RecibirIdentificacion (nroId: IN int) DO
            id = nroId;
        END RecibirIdentificacion;
        FOR i IN 1..4 LOOP
            ACCEPT LlegadaBarrera;
        END LOOP;
        FOR i IN 1..4 LOOP
            ACCEPT SalidaBarrera;
        END LOOP;
        FOR i IN 1..4 LOOP
            ACCEPT SumarAlTotal (cantidadSumada) DO
                totalDeEquipo = totalDeEquipo + cantidadSumada;
            END SumarAlTotal;
        END LOOP;
        Administrador.FinalizarEquipo (id, totalDeEquipo);
    END Equipo;

    TASK TYPE Persona IS
        ENTRY RecibirIdentificacion(nroId: IN int);
    END Persona;
    arrPersonas: array (1..20) of Persona;
    TASK BODY Persona IS
        totalEncontrado, equipo, equipoGanador: int;
    BEGIN
        equipo = ...;
        totalEncontrado = 0;
        arrEquipos(equipo).LlegadaBarrera;
        arrEquipos(equipo).SalidaBarrera;
        FOR i in 1..15 LOOP
            totalEncontrado = totalEncontrado + Moneda();
        END LOOP;
        arrEquipos(equipo).SumarAlTotal (totalEncontrado);
        Administrador.ConsultarGanador (idEquipoGanador);
        IF (idEquipoGanador == idEquipo) THEN
            puts "A casa bots";
        END IF;
    END Persona;

BEGIN
    FOR i IN 1..5 LOOP
        arrEquipos(i).RecibirIdentificacion (i);
    END FOR;
END Juego;
```

## Ejercicio 6

Se debe calcular el valor promedio de un vector de 1 millón de números enteros que se encuentra distribuido entre 10 procesos Worker (es decir, cada Worker tiene un vector de 100 mil números). Para ello, existe un Coordinador que determina el momento en que se debe realizar el cálculo de este promedio y que, además, se queda con el resultado. **Nota:** maximizar la concurrencia; este cálculo se hace una sola vez.

### Respuesta

```ADA
PROCEDURE Promedio IS
    TASK Coordinador IS
        ENTRY Empezar;
        ENTRY RecibirSuma (cantidadSumada: IN int);
    END Coordinador;
    TASK BODY Coordinador IS
        total, promedio: int;
    BEGIN
        total = 0;
        FOR i IN 1..20 LOOP
            SELECT
                ACCEPT Empezar;
            OR
                ACCEPT RecibirSuma (cantidadSumada: IN int) DO
                    total = total + cantidadSumada;
                END RecibirSuma;
            END SELECT;
        END LOOP;
        promedio = (total / 100000000);
    END Coordinador;

    TASK TYPE Worker;
    arrWorkers: array (1..10) of Worker;
    TASK BODY Worker IS
        arrNumeros: array (1..100000) of int;
        suma: int;
    BEGIN
        suma = 0;
        Coordinador.Empezar;
        FOR i IN 1..100000 LOOP
            suma = suma + arrNumeros(i);
        END LOOP;
        Coordinador.RecibirSuma (suma);
    END Worker;

BEGIN
    null;
END Promedio;
```

## Ejercicio 7

Hay un sistema de reconocimiento de huellas dactilares de la policía que tiene 8 Servidores para realizar el reconocimiento, cada uno de ellos trabajando con una Base de Datos propia; a su vez hay un Especialista que utiliza indefinidamente. El sistema funciona de la siguiente manera: el Especialista toma una imagen de una huella (TEST) y se la envía a los servidores para que cada uno de ellos le devuelva el código y el valor de similitud de la huella que más se asemeja a TEST en su BD; al final del procesamiento, el especialista debe conocer el código de la huella con mayor valor de similitud entre las devueltas por los 8 servidores. Cuando ha terminado de procesar una huella comienza nuevamente todo el ciclo. **Nota:** suponga que existe una función Buscar(test, código, valor) que utiliza cada Servidor donde recibe como parámetro de entrada la huella test, y devuelve como parámetros de salida el código y el valor de similitud de la huella más parecida a test en la BD correspondiente. Maximizar la concurrencia y no generar demora innecesaria.

### Respuesta (CONSULTAR ESTE)

```ADA
PROCEDURE Sistema IS
    TASK Especialista IS
        ENTRY ListoParaProcesar (huellaTest: OUT Huella);
        ENTRY RecibirResultado (codigoHuella: IN int; valorSimilitud: IN double);
        ENTRY TermineCiclo;
    END Especialista;
    TASK BODY Especialista IS
        test: Huella;
        codigoMasParecido: int;
        similitudMaxima: double;
    BEGIN
        LOOP
            similitudMaxima = -1;
            test = tomarImagen ();
            FOR i IN 1..16 LOOP
                SELECT
                    ACCEPT ListoParaProcesar (huellaTest: OUT Huella) DO
                        huellaTest = test;
                    END ListoParaProcesar;
                OR
                    ACCEPT RecibirResultado (codigoHuella: IN int; valorSimilitud: IN double) DO
                        IF (valorSimilitud > similitudMaxima) THEN
                            similitudMaxima = valorSimilitud;
                            codigoMasParecido = codigoHuella;
                        END IF;
                END SELECT;
            END LOOP;
            FOR i IN 1..8 LOOP
                ACCEPT TermineCiclo;
            END LOOP;
        END LOOP;
    END Especialista;

    TASK TYPE Servidor IS
        ENTRY RecibirIdDatabase (id: IN int);
    END Servidor;
    arrServidores: array (1..8) of Servidor;
    TASK BODY Servidor IS
        idDatabase: int;
        huellaTest: Huella;
        codigoHuella: int;
        valorSimilitud: double;
    BEGIN
        ACCEPT RecibirIdDatabase (id: IN int) DO
            idDatabase = id;
        END RecibirIdDatabase;
        LOOP
            Especialista.ListoParaProcesar (huellaTest);
            arrDatabases(idDatabase).Buscar(huellaTest, codigoHuella, valorSimilitud);
            Especialista.RecibirResultado (codigoHuella, valorSimilitud);
            Especialista.TermineCiclo;
        END LOOP;
    END Servidor;

    TASK TYPE Database IS
        ENTRY Buscar (test: IN Huella; codigo: OUT int; valor: OUT double);
    END Database;
    arrDatabases: array (1..8) of Database;
    TASK BODY Database IS
    BEGIN
        LOOP
            ACCEPT Buscar (test: IN Huella; codigo: OUT int; valor: OUT double) DO
                codigo, valor = ObtenerParecido (test);
            END Buscar;
        END LOOP;
    END Database;

BEGIN
    FOR i IN 1..8 LOOP
        arrServidores(i).RecibirIdDatabase (i);
    END LOOP;
END Sistema;
```

## Ejercicio 8

Una empresa de limpieza se encarga de recolectar residuos en una ciudad por medio de 3 camiones. Hay P personas que hacen reclamos continuamente hasta que uno de los camiones pase por su casa. Cada persona hace un reclamo y espera a lo sumo 15 minutos a que llegue un camión; si no pasa, vuelve a hacer el reclamo y a esperar a lo sumo 15 minutos a que llegue un camión; y así sucesivamente hasta que el camión llegue y recolecte los residuos. Sólo cuando un camión llega, es cuando deja de hacer reclamos y se retira. Cuando un camión está libre la empresa lo envía a la casa de la persona que más reclamos ha hecho sin ser atendido. **Nota:** maximizar la concurrencia.

### Respuesta

```ADA
PROCEDURE Ciudad IS
    TASK Administrador IS
        ENTRY RecibirReclamo (idPersona: IN int);
        ENTRY EnviarCamion (idPersona: OUT int);
    END Administrador;
    TASK BODY Administrador IS
        reclamosPorPersona : array (1..P) of int;
        maxReclamos, maxIdPersona, cantidadQueReclamaron: int;
    BEGIN
        cantidadQueReclamaron = 0;
        LOOP 
            SELECT 
                ACCEPT RecibirReclamo(idPersona: IN int) DO
                    IF (reclamosPorPersona(idPersona) != -1) THEN
                        IF (reclamosPorPersona(idPersona) == 0) THEN
                            cantidadQueReclamaron = cantidadQueReclamaron + 1;
                        END IF;
                        reclamosPorPersona[idPersona] = reclamosPorPersona[idPersona] + 1; 
                    END IF;
                END RecibirReclamo;
            OR
                WHEN (cantidadQueReclamaron > 0) → ACCEPT EnviarCamion(idPersona: OUT int) DO
                    maxReclamos = -1; 
                    maxIdPersona = -1;
                    FOR i IN 1..P LOOP
                        IF (reclamosPorPersona(i) > maxReclamos) THEN
                            maxReclamos = reclamosPorPersona(i);
                            maxIdPersona = i;
                        END IF;
                    END LOOP;
                    reclamosPorPersona(maxIdPersona) = -1;
                    idPersona = maxIdPersona;
                    cantidadQueReclamaron = cantidadQueReclamaron - 1;
                END EnviarCamion;
            END SELECT;
        END LOOP;
    END Administrador;
    
    TASK TYPE Persona IS
        ENTRY RecibirId (id: IN int);
        ENTRY EsperarCamion;
    END Persona;
    arrPersonas: array (1..P) of Persona;
    TASK BODY Persona IS
        vinoCamion: Boolean;
        idPersona: int;
    BEGIN
        vinoCamion = False;
        ACCEPT RecibirId(id: IN int) DO
            idPersona = id;
        END RecibirId;
        LOOP (NOT vinoCamion)
            Administrador.RecibirReclamo(idPersona);
            SELECT 
                ACCEPT EsperarCamion DO
                    vinoCamion = True;
                END EsperarCamion;
            OR DELAY 900;
                null;
            END SELECT;
        END LOOP;
    END BODY Persona;

    TASK TYPE Camion;
    arrCamiones: array (1..3) of Camion;
    TASK BODY Camion IS
        idPersona: int;
    BEGIN
        LOOP 
            Administrador.EnviarCamion(idPersona);
            arrPersonas(idPersona).EsperarCamion;   
        END LOOP;
    END Camion;

BEGIN
    FOR i IN 1..P LOOP
        arrPersonas(i).recibirID (i);
    END LOOP;
END ciudad;
```