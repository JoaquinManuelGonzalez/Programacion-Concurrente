# Práctica 4 - Pasaje de Mensajes - PMA

## Ejercicio 1

Suponga que N clientes llegan a la cola de un banco y que serán atendidos por sus empleados. Analice el problema y defina qué procesos, recursos y canales/comunicaciones serán necesarios/convenientes para resolverlo. Luego, resuelva considerando las siguientes 
situaciones:
- **a.** Existe un único empleado, el cual atiende por orden de llegada.
- **b.** Ídem a) pero considerando que hay 2 empleados para atender, ¿qué debe modificarse en la solución anterior?
- **c.** Ídem b) pero considerando que, si no hay clientes para atender, los empleados realizan tareas administrativas durante 15 minutos. ¿Se puede resolver sin usar procesos adicionales? ¿Qué consecuencias implicaría?

### Respuestas

**a.**

```c
chan atencion(int);

Process Cliente[id: 1 ... N] {
    send atencion(id);
}

Process Empleado {
    int idCliente;
    for [int i = 0; i < N; i++] {
        receive atencion(idCliente);
        atenderCliente(idCliente);
    }
}
```

**b.**

```c
chan atencion(int);

Process Cliente[id: 1 ... N] {
    send atencion(id);
}

Process Empleado[id: 1 ... 2] {
    int idCliente;
    while (true) {
        receive atencion(idCliente);
        atenderCliente(idCliente);
    }
}
```

**c.** Para esta solución tenemos el problema que dos procesos, en este caso los dos empleados estarían teniendo que consultar por **empty()** en un mismo canal, se puede hacer con estos dos procesos pero tendríamos busy waiting, lo mejor es sumar un proceso "Administrador" que actúe como filtro y que reciba los mensajes de los clientes y de los empleados y les comunique lo que tienen que hacer.

```c
chan atencion(int);
chan avisoTrabajo[2](int);
chan avisoEmpleadoLibre(int);

Process Cliente[id: 1 ... N] {
    send atencion(id);
}

Process Administrador {
    int IdCliente;
    int IdEmpleado;
    int clientesQueSolicitaronAtencion = 0;
    while (clientesQueSolicitaronAtencion < N) {
        receive avisoEmpleadoLibre(idEmpleado);
        if (empty(atencion)) {
            send avisoTrabajo[idEmpleado](-1);
        } else {
            clientesQueSolicitaronAtencion++;
            receive atencion(idCliente);
            send avisoTrabajo[idEmpleado](idCliente);
        }
    }
    for [int i = 1; i <= 2; i++]{ 
        send avisoTrabajo[i](-2);
    }
}

Process Empleado[id: 1 ... 2] {
    int idCliente;
    bool continuar = true;
    while (continuar) {
        send avisoEmpleadoLibre(id);
        receive avisoTrabajo[idEmpleado](idCliente);
        if (idCliente != -2) {
            if (idCliente == -1) {
                delay(15);
            } else {
                atenderCliente(idCliente);
            }
        } else {
            continuar = false;
        }
    }
}
```

## Ejercicio 2

Se desea modelar el funcionamiento de un banco en el cual existen 5 cajas para realizar pagos. Existen P clientes que desean hacer un pago. Para esto, cada una selecciona la caja donde hay menos personas esperando; una vez seleccionada, espera a ser atendido. En cada caja, los clientes son atendidos por orden de llegada por los cajeros. Luego del pago, se les entrega un comprobante. **Nota:** maximizar la concurrencia.

### Respuesta

```c
chan hayPedido(bool);
chan solicitarCaja(int);
chan entregaNroCaja[P](int);
chan atencionCaja[5](int, Pago);
chan entregaComprobante[P](Comprobante);
chan liberarCaja(int);

Process Cliente[id: 1 ... P] {
    Pago pago;
    Comprobante comprobante;
    int nroCaja;
    send solicitarCaja(id);
    send hayPedido();
    receive entregarNroCaja[id](nroCaja);
    send atencionCaja[nroCaja](id, pago)
    receive entregaComprobante[id](comprobante);
    send liberarCaja(nroCaja);
    send hayPedido();
}

Process Administrador {
    int clientesPorCaja[5] = ([5], 0);
    int idCliente;
    int nroCaja;
    for [int i = 0; i < (P * 2); i++] {
        receive hayPedido();
        if (!empty(liberarCaja)) {
            receive liberarCaja(nroCaja);
            clientesPorCaja[nroCaja]--;
        } else {
            receive solicitarCaja(idCliente);
            nroCaja = calcularMinimo(clientesPorCaja);
            clientesPorCaja[nroCaja]++;
            send entregarNroCaja[idCliente](nroCaja);
        }
    }
    for [int i = 1; i <= 5; i++] {
        send atencionCaja[i](-1; null);
    }
}

Process Caja[id: 1 ... 5] {
    int idCliente;
    bool continuar = true;
    Pago pago;
    Comprobante comprobante;
    while (continuar) {
        receive atencionCaja[id](idCliente, pago);
        if (idCliente != -1) {
            comprobante = generarComprobante(idCliente, pago);
            send entregaComprobante[idCliente](comprobante);
        } else {
            continuar = false;
        }
    }
}
```

## Ejercicio 3

Se debe modelar el funcionamiento de una casa de comida rápida, en la cual trabajan 2 cocineros y 3 vendedores, y que debe atender a C clientes. El modelado debe considerar que:
- Cada cliente realiza un pedido y luego espera a que se lo entreguen.
- Los pedidos que hacen los clientes son tomados por cualquiera de los vendedores y se lo pasan a los cocineros para que realicen el plato. Cuando no hay pedidos para atender, los vendedores aprovechan para reponer un pack de bebidas de la heladera (tardan entre 1 y 3 minutos para hacer esto).
- Repetidamente cada cocinero toma un pedido pendiente dejado por los vendedores, lo cocina y se lo entrega directamente al cliente correspondiente. **Nota:** maximizar la concurrencia.

### Respuesta

```c
chan solicitarPedido(int, Pedido);
chan obtenerPlato[C](Plato);
chan avisoVendedorLibre(int);
chan pedidosParaVendedor[3](int, Pedido);
chan pedidosParaCocinero(int, Pedido);

Process Cliente[id: 1 ... C] {
    Pedido pedido;
    Plato plato;
    send solicitarPedido(id, Pedido);
    receive obtenerPlato[id](plato);
}

Process Administrador {
    int idCliente;
    int idVendedor;
    int clientesQueSolicitaron = 0;
    Pedido pedido;
    while (clientesQueSolicitaron < C) {
        receive avisoVendedorLibre(idVendedor);
        if (empty(solicitarPedido)) {
            send pedidosParaVendedor[idVendedor](-1, null);
        } else {
            clientesQueSolicitaron++;
            receive solicitarPedido(idCliente, pedido);
            send pedidosParaVendedor[idVendedor](idCliente, Pedido);
        }
    }
    for [int i = 1; i <= 3; i++] {
        send pedidosParaVendedor[i](-2, null);
    }
    for [int i = 1; i <= 2; i++] {
        send pedidosParaCocinero[i](-2, null);
    }
}

Process Vendedor[id: 1 ... 3] {
    int idCliente;
    Pedido pedido;
    bool continuar = true;
    while (continuar) {
        send avisoVendedorLibre(id);
        receive pedidosParaVendedor[id](idCliente, pedido);
        if (idCliente != -2) {
            if (idCliente == -1) {
                delay(randInt(1, 3));
            } else {
                send pedidosParaCocineros(idCliente, pedido);
            }
        } else {
            continuar = false;
        }
    }
}

Process Cocinero[id: 1 ... 2] {
    int idCliente;
    Pedido pedido;
    Plato plato;
    bool continuar = true;
    while (continuar) {
        receive pedidosParaCocineros(idCliente, pedido);
        if (idCliente != -2) {
            plato = cocinarPedido(pedido);
            send obtenerPlato[idCliente](plato);
        } else {
            continuar = false;
        }
    }
}
```

## Ejercicio 4

Simular la atención en un locutorio con 10 cabinas telefónicas, el cual tiene un empleado que se encarga de atender a N clientes. Al llegar, cada cliente espera hasta que el empleado le indique a qué cabina ir, la usa y luego se dirige al empleado para pagarle. El empleado atiende a los clientes en el orden en que hacen los pedidos. A cada cliente se le entrega un ticket factura por la operación.
- **a)** Implemente una solución para el problema descrito.
- **b)** Modifique la solución implementada para que el empleado dé prioridad a los que terminaron de usar la cabina sobre los que están esperando para usarla.
**Nota:** maximizar la concurrencia; suponga que hay una función Cobrar() llamada por el empleado que simula que el empleado le cobra al cliente.

### Respuestas

**a)**

```c
chan avisoLlegadaCliente(int);
chan obtenerNroCabina[N](int);
chan liberarCabina(int, int);
chan obtenerTicket[N](TicketFactura);

Process Cliente[id: 1 ... N] {
    int nroCabina;
    TicketFactura ticket;
    send avisoLlegadaCliente(id);
    receive obtenerNroCabina[id](nroCabina);
    usarCabina(nroCabina);
    send liberarCabina(id, nroCabina);
    receive obtenerTicket[id](ticket);
}

Process Empleado {
    set cabinasLibres = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    int idCliente;
    int nroCabina;
    int cantidadClientesAtendidos = 0;
    TicketFactura ticket;
    while (cantidadClientesAtendidos < N) {
        if (!empty(liberarCabina)) {
            receive liberarCabina(idCliente, nroCabina);
            cabinasLibres.insert(nroCabina);
            ticket = Cobrar();
            send obtenerTicket[idCliente](ticket);
            cantidadClientesAtendidos++;
        } elif ((!empty(avisoLlegadaCliente)) && (!cabinasLibres.isEmpty())) {
            receive avisoLlegadaCliente(idCliente);
            send obtenerNroCabina[idCliente](cabinasLibres.removeRandom());
        }
    }
}
```

**b)** En el **a)** ya le doy prioridad a los que liberan la cabina al preguntar primero por el canal de mensajes de los que me avisan que liberan la cabina.

## Ejercicio 5

Resolver la administración de 3 impresoras de una oficina. Las impresoras son usadas por N administrativos, los cuales están continuamente trabajando y cada tanto envían documentos a imprimir. Cada impresora, cuando está libre, toma un documento y lo imprime, de acuerdo con el orden de llegada. 
- **a)** Implemente una solución para el problema descrito.
- **b)** Modifique la solución implementada para que considere la presencia de un director de oficina que también usa las impresas, el cual tiene prioridad sobre los administrativos.
- **c)** Modifique la solución (a) considerando que cada administrativo imprime 10 trabajos y que todos los procesos deben terminar su ejecución.
- **d)** Modifique la solución (b) considerando que tanto el director como cada administrativo imprimen 10 trabajos y que todos los procesos deben terminar su ejecución.
- **e)** Si la solución al ítem d) implica realizar Busy Waiting, modifíquela para evitarlo.
**Nota:** ni los administrativos ni el director deben esperar a que se imprima el documento.

### Respuestas

**a)**

```c
chan pedidoImpresion(Documento);

Process Impresora[id: 1 ... 3] {
    Documento original;
    while (true) {
        receive pedidoImpresion(original);
        imprimir(original);
    }
}

Process Administrativo[id: 1 ... N] {
    Documento original;
    while (true) {
        trabajar();
        send pedidoImpresion(original);
    }
}
```

**b)**

```c
chan pedidoImpresionDirectivo(Documento);
chan pedidoImpresionAdministrativo(Documento);
chan hayPeticion(bool);
chan avisoImpresoraLibre(int);
chan avisoPedidoImpresion[3](Documento);

Process Impresora[id: 1 ... 3] {
    Documento original;
    while (true) {
        send avisoImpresoraLibre(id);
        receive avisoPedidoImpresion[id](original);
        imprimir(original);
    }
}

Process Coordinador {
    Documento original;
    int idImpresora;
    while (true) {
        receive avisoImpresoraLibre(idImpresora);
        receive hayPedido();
        if (!empty(pedidoImpresionDirectivo)) {
            receive pedidoImpresionDirectivo(original);
        } else {
            receive pedidoImpresionAdministrativo(original);
        }
        send avisoPedidoImpresion[idImpresora](original);
    }
}

Process Director {
    Documento original;
    while (true) {
        send pedidoImpresionDirectivo(original);
        send hayPeticion();
    }
}

Process Administrativo[id: 1 ... N] {
    Documento original;
    while (true) {
        trabajar();
        send pedidoImpresionAdministrativo(original);
        send hayPeticion();
    }
}
```

**c)**

```c
chan pedidoImpresion(Documento);
chan cantidadPedidosAtendidos(int);

Process Impresora[id: 1 ... 3] {
    Documento original;
    int cantidadAtendidos;
    if (id == 0) {
        send cantidadPedidosAtendidos(0);
    }
    receive cantidadPedidosAtendidos(cantidadAtendidos);
    while (cantidadAtendidos < (cantidadAtendidos * 10)) {
        cantidadAtendidos++;
        send cantidadPedidosAtendidos(cantidadAtendidos);
        receive pedidoImpresion(original);
        imprimir(original);
        receive cantidadPedidosAtendidos(cantidadAtendidos);
    }
    send cantidadPedidosAtendidos(cantidadAtendidos);
}

Process Administrativo[id: 1 ... N] {
    Documento original;
    for [int i = 0; i < 10; i++] {
        trabajar();
        send pedidoImpresion(original);
    }
}
```

**d)**

```c
chan pedidoImpresionDirectivo(Documento);
chan pedidoImpresionAdministrativo(Documento);
chan hayPeticion(bool);
chan avisoImpresoraLibre(int);
chan avisoPedidoImpresion[3](Documento);

Process Impresora[id: 1 ... 3] {
    Documento original;
    bool continuar = true;
    while (continuar) {
        send avisoImpresoraLibre(id);
        receive avisoPedidoImpresion[id](original);
        if (orginal != null) {
            imprimir(original);
        } else {
            continuar = false;
        }
    }
}

Process Coordinador {
    Documento original;
    int idImpresora;
    for [int i = 0; i < ((N + 1) * 10); i++] {
        receive avisoImpresoraLibre(idImpresora);
        receive hayPedido();
        if (!empty(pedidoImpresionDirectivo)) {
            receive pedidoImpresionDirectivo(original);
        } else {
            receive pedidoImpresionAdministrativo(original);
        }
        send avisoPedidoImpresion[idImpresora](original);
    }
    for [int i = 1; i <= 3; i++] {
        send avisoPedidoImpresion[i](null);
    }
}

Process Director {
    Documento original;
    for [int i = 0; i < 10; i++] {
        send pedidoImpresionDirectivo(original);
        send hayPeticion();
    }
}

Process Administrativo[id: 1 ... N] {
    Documento original;
    for [int i = 0; i < 10; i++] {
        trabajar();
        send pedidoImpresionAdministrativo(original);
        send hayPeticion();
    }
}
```

**e)** No hace busy waiting.

# Práctica 4 - Pasaje de Mensajes - PMS

## Ejercicio 1

Suponga que existe un antivirus distribuido que se compone de R procesos robots Examinadores y 1 proceso Analizador. Los procesos Examinadores están buscando continuamente posibles sitios web infectados; cada vez que encuentran uno avisan la dirección y luego continúan buscando. El proceso Analizador se encarga de hacer todas las pruebas necesarias con cada uno de los sitios encontrados por los robots para determinar si están o no infectados. 
- **a)** Analice el problema y defina qué procesos, recursos y comunicaciones serán necesarios/convenientes para resolverlo.
- **b)** Implemente una solución con PMS sin tener en cuenta el orden de los pedidos.
- **c)** Modifique el **inciso (b)** para que el Analizador resuelva los pedidos en el orden en que se hicieron.

### Respuestas

**a)**

```c
Process RobotExaminador[id: 1 ... R] {
    SitioWeb sitio;
    while (true) {
        sitio = buscarSitioInfectado();
        Buffer!enviarSitio(sitio);
    }
}

Process Buffer {
    Buffer bufferSitiosWeb;
    SitioWeb sitio;
    do RobotExaminador?enviarSitio(sitio) → bufferSitiosWeb.push(sitio);
    [] !bufferSitiosWeb.isEmpty(); Analizador?avisoDisponible() → Analizador!recibirSitio(bufferSitiosWeb.pop());
    od
}

Process Analizador {
    SitioWeb sitio;
    while (true) {
        Buffer!avisoDisponible();
        Buffer?recibirSitio(sitio);
        analizarSitioWeb(sitio);
    }
}
```

**b)** Asumo que existe la función **popRandom()** para sacar un elemento random del buffer, supongo que otra forma de hacer esto es que no exista el buffer y la comunicación se de entre los procesos RobotExaminador y el Analizador, de esa forma se retrasa pero no poder determinar un orden porque para la recepción usarías RobotExaminador[*].

```c
Process RobotExaminador[id: 1 ... R] {
    SitioWeb sitio;
    while (true) {
        sitio = buscarSitioInfectado();
        Buffer!enviarSitio(sitio);
    }
}

Process Buffer {
    Buffer bufferSitiosWeb;
    SitioWeb sitio;
    do RobotExaminador?enviarSitio(sitio) → bufferSitiosWeb.push(sitio);
    [] !bufferSitiosWeb.isEmpty(); Analizador?avisoDisponible() → Analizador!recibirSitio(bufferSitiosWeb.popRandom());
    od
}

Process Analizador {
    SitioWeb sitio;
    while (true) {
        Buffer!avisoDisponible();
        Buffer?recibirSitio(sitio);
        analizarSitioWeb(sitio);
    }
}
```

**c)** Es el a).

## Ejercicio 2

En un laboratorio de genética veterinaria hay 3 empleados. El primero de ellos continuamente prepara las muestras de ADN; cada vez que termina, se la envía al segundo empleado y vuelve a su trabajo. El segundo empleado toma cada muestra de ADN preparada, arma el set de análisis que se deben realizar con ella y espera el resultado para archivarlo. Por último, el tercer empleado se encarga de realizar el análisis y devolverle el resultado al segundo empleado.

### Respuesta

```c
Process EmpleadoUno {
    MuestraADN muestra;
    while (true) {
        muestra = prepararMuestra();
        Buffer!enviarMuestra(muestra);
    }
}

Process Buffer {
    Buffer bufferMuestras;
    MuestraADN muestra;
    do EmpleadoUno?enviarMuestra(muestra) → bufferMuestras.push(muestra);
    [] !bufferMuestras.isEmpty(); EmpleadoDos?avisoDisponible() → EmpleadoDos!recibirMuestra(bufferMuestras.pop());
    od
}

Process EmpleadoDos {
    MuestraADN muestra;
    SetDeAnalisis set;
    Documento resultado;
    while (true) {
        Buffer!avisoDisponible();
        Buffer?recibirMuestra(muestra);
        set = armarSet(muestra);
        EmpleadoTres!enviarSet(set);
        EmpleadoTres?recibirResultado(resultado);
        archivarResultado(resultado);
    }
}

Process EmpleadoTres {
    SetDeAnalisis set;
    Documento resultado;
    while (true) {
        EmpleadoDos?.enviarSet(set);
        resultado = realizarAnalisis(set);
        EmpleadoDos!recibirResultado(resultado);
    }
}
```

## Ejercicio 3

En un examen final hay N alumnos y P profesores. Cada alumno resuelve su examen, lo entrega y espera a que alguno de los profesores lo corrija y le indique la nota. Los profesores corrigen los exámenes respetando el orden en que los alumnos van entregando. 
- **a)** Considerando que P=1.
- **b)** Considerando que P>1.
- **c) Ídem b)** pero considerando que los alumnos no comienzan a realizar su examen hasta que todos hayan llegado al aula.

**Nota:** maximizar la concurrencia; no generar demora innecesaria; todos los procesos deben terminar su ejecución.

### Respuestas

**a)**

```c
Process Alumno[id: 1 ... N] {
    Examen examen;
    int nota;
    examen = realizarExamen();
    Buffer!enviarExamen(id, examen);
    Profesor?recibirNota(nota);
}

Process Buffer {
    Buffer bufferExamenes;
    Examen examen;
    int idAlumno;
    int cantidadExamenesRecibidos = 0;
    do cantidadExamenesRecibidos < N; Alumno[*]?enviarExamen(idAlumno, examen) → 
        bufferExamenes.push(idAlumno, examen);
        cantidadExamenesRecibidos++;
    [] !bufferExamenes.isEmpty(); Profesor?avisoDisponible() → Profesor!recibirExamen(idAlumno, bufferExamenes.pop());
    od
}

Process Profesor {
    Examen examen;
    int nota;
    int idAlumno;
    for [int i = 0; i < N; i++] {
        Buffer!avisoDisponible();
        Buffer?recibirExamen(idAlumno, examen);
        nota = corregirExamen(examen);
        Alumno[idAlumno]!recibirNota(nota);
    }
}
```

**b)**

```c
Process Alumno[id: 1 ... N] {
    Examen examen;
    int nota;
    examen = realizarExamen();
    Buffer!enviarExamen(id, examen);
    Profesor[*]?recibirNota(nota);
}

Process Buffer {
    Buffer bufferExamenes;
    Examen examen;
    int idAlumno;
    int idProfesor;
    int cantidadExamenesRecibidos = 0;
    do cantidadExamenesRecibidos < N; Alumno[*]?enviarExamen(idAlumno, examen) → 
        bufferExamenes.push(idAlumno, examen);
        cantidadExamenesRecibidos++;
    [] !bufferExamenes.isEmpty(); Profesor[*]?avisoDisponible(idProfesor) → Profesor[idProfesor]!recibirExamen(bufferExamenes.pop());
    od
    for [int i = 1; i <= P; i++] {
        Profesor[*]?avisoDisponible(idProfesor);
        Profesor[idProfesor]!recibirExamen(-1, null);
    }
}

Process Profesor[id: 1 ... P] {
    Examen examen;
    int nota;
    int idAlumno;
    bool continuar = true;
    while (continuar) {
        Buffer!avisoDisponible(id);
        Buffer?recibirExamen(idAlumno, examen);
        if (idAlumno != -1) {
            nota = corregirExamen(examen);
            Alumno[idAlumno]!recibirNota(nota);
        } else {
            continuar = false;
        }
    }
}
```

**c)**

```c
Process Alumno[id: 1 ... N] {
    Examen examen;
    int nota;
    Barrera!avisoLlegada();
    Barrera?avisoArranque();
    examen = realizarExamen();
    Buffer!enviarExamen(id, examen);
    Profesor[*]?recibirNota(nota);
}

Process Barrera {
    for [int i = 1; i <= N; i++] {
        Alumno[*]?avisoLlegada();
    }
    for [int i = 1; i <= N; i++] {
        Alumno[i]!avisoArranque();
    }
}

Process Buffer {
    Buffer bufferExamenes;
    Examen examen;
    int idAlumno;
    int idProfesor;
    int cantidadExamenesRecibidos = 0;
    do cantidadExamenesRecibidos < N; Alumno[*]?enviarExamen(idAlumno, examen) → 
        bufferExamenes.push(idAlumno, examen);
        cantidadExamenesRecibidos++;
    [] !bufferExamenes.isEmpty(); Profesor[*]?avisoDisponible(idProfesor) → Profesor[idProfesor]!recibirExamen(bufferExamenes.pop());
    od
    for [int i = 1; i <= P; i++] {
        Profesor[*]?avisoDisponible(idProfesor);
        Profesor[idProfesor]!recibirExamen(-1, null);
    }
}

Process Profesor[id: 1 ... P] {
    Examen examen;
    int nota;
    int idAlumno;
    bool continuar = true;
    while (continuar) {
        Buffer!avisoDisponible(id);
        Buffer?recibirExamen(idAlumno, examen);
        if (idAlumno != -1) {
            nota = corregirExamen(examen);
            Alumno[idAlumno]!recibirNota(nota);
        } else {
            continuar = false;
        }
    }
}
```

## Ejercicio 4

En una exposición aeronáutica hay un simulador de vuelo (que debe ser usado con exclusión mutua) y un empleado encargado de administrar su uso. Hay P personas que esperan a que el empleado lo deje acceder al simulador, lo usa por un rato y se retira.
- **a)** Implemente una solución donde el empleado sólo se ocupa de garantizar la exclusión mutua.
- **b)** Modifique la solución anterior para que el empleado considere el orden de llegada para dar acceso al simulador.

**Nota:** cada persona usa sólo una vez el simulador.

### Respuestas

**a)**

```c
Process Persona[id: 1 ... P] {
    SimuladorDeVuelo simulador;
    Empleado!solicitarSimulador(id);
    Empleado?habilitarSimulador(simulador);
    usarSimulador(simulador);
    Empleado!liberarSimulador();
}

Process Empleado {
    SimuladorDeVuelo simulador;
    int idPersona;
    for [int i = 0; i < P; i++] {
        Persona[*]?solicitarSimulador(idPersona);
        Persona[idPersona]!habilitarSimulador(simulador);
        Persona[idPersona]?liberarSimulador();
    }
}
```

**b)**

```c
Process Persona[id: 1 ... P] {
    SimuladorDeVuelo simulador;
    Buffer!solicitarSimulador(id);
    Empleado?habilitarSimulador(simulador);
    usarSimulador(simulador);
    Empleado!liberarSimulador();
}

Process Buffer {
    Buffer bufferPersonas;
    int idPersona;
    int personasQueSolicitaron = 0;
    do personasQueSolicitaron < P; Persona[*]?solicitarSimulador(idPersona) →
        bufferPersonas.push(idPersona);
        personasQueSolicitaron++;
    [] !bufferPersonas.isEmpty(); Empleado?avisoDisponible() → Empleado!recibirPeticion(bufferPersonas.pop());
}

Process Empleado {
    SimuladorDeVuelo simulador;
    int idPersona;
    for [int i = 0; i < P; i++] {
        Buffer!avisoDisponible();
        Buffer?recibirPeticion(idPersona);
        Persona[idPersona]!habilitarSimulador(simulador);
        Persona[idPersona]?liberarSimulador();
    }
}
```

## Ejercicio 5

En un estadio de fútbol hay una máquina expendedora de gaseosas que debe ser usada por E Espectadores de acuerdo con el orden de llegada. Cuando el espectador accede a la máquina en su turno usa la máquina y luego se retira para dejar al siguiente. **Nota:** cada Espectador una sólo una vez la máquina.

### Respuesta

```c
Process Espectador[id: 1 ... E] {
    Maquina maquina;
    Buffer!solicitarMaquina(id);
    Buffer?habilitarMaquina(maquina);
    usarMaquina(maquina);
    Buffer!liberarMaquina();
}

Process Buffer {
    Maquina maquina;
    Buffer bufferSolicitudes;
    bool libre = true;
    int idEspectador;
    int espectadoresAtendidos = 0;
    do espectadoresAtendidos < E; Espectador[*]?solicitarMaquina(idEspectador) →
        if (libre) {
            libre = false;
            Espectador[idEspectador]!habilitarMaquina(maquina);
        } else {
            bufferSolicitudes.push(idEspectador);
        }
    [] espectadoresAtendidos < E; Espectador[*]?liberarMaquina() →
        espectadoresAtendidos++;
        if (!bufferSolicitudes.isEmpty()) {
            Espectador[bufferSolicitudes.pop()]!habilitarMaquina(maquina);
        } else {
            libre = true;
        }
    od
}
```