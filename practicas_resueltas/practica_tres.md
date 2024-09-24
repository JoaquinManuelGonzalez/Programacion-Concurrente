# Practica 3 - Monitores

## Ejercicio 1

Se dispone de un puente por el cual puede pasar un solo auto a la vez. Un auto pide permiso para pasar por el puente, cruza por el mismo y luego sigue su camino.

```c
Monitor Puente
    cond cola; 
    int cant= 0;

    Procedure entrarPuente()
        while ( cant > 0) wait (cola);
        cant = cant + 1; 
    end;

    Procedure salirPuente()
        cant = cant – 1;
        signal(cola);
    end;

End Monitor;

Process Auto [a:1..M]
    Puente.entrarPuente(a);
    “el auto cruza el puente”
    Puente.salirPuente(a);
End Process;
```

- **a)** ¿El código funciona correctamente? Justifique su respuesta.
- **b)** ¿Se podría simplificar el programa? ¿Sin monitor? ¿Menos procedimientos? ¿Sin variable condition? En caso afirmativo, rescriba el código.
- **c)** ¿La solución original respeta el orden de llegada de los vehículos? Si rescribió el código en el punto **b)**, ¿esa solución respeta el orden de llegada? 

### Respuestas

**a)** Si, el código funciona correctamente ya que al querer entrar un auto al puente, se llama al procedimiento entrarPuente() y este se encarga de verificar si hay autos en el puente, si no hay autos en el puente, se incrementa la variable cant y, si hay autos en el puente, se duerme al proceso hasta que el auto que está en el puente disminuya la variable cant y despierte al primer proceso dormido en la cola de espera. Lo único a remarcar es que no se respeta el orden de llegada de los vehículos. Esto se puede solucionar usando Passing the Condition.

**b)** Podríamos simplificarlo si el Monitor únicamente representa el cruce del puente y no la entrada y salida del mismo. Al hacer esto y gracias a la exclusión mutua que garantizan los Monitores, podemos resolver el problema de la siguiente manera:

```c
Monitor Puente {
    Procedure cruzarPuente() {
        # El auto cruza el puente
    }
}

Process Auto [a:1..M] {
    Puente.cruzarPuente();
}
```

**c)** Ninguna de las dos soluciones respeta el orden de llegada de los vehículos. Esto se puede solucionar usando Passing the Condition.

## Ejercicio 2

Existen N procesos que deben leer información de una base de datos, la cual es administrada por un motor que admite una cantidad limitada de consultas simultáneas.
- **a)** Analice el problema y defina qué procesos, recursos y monitores/sincronizaciones serán necesarios/convenientes para resolverlo.
- **b)** Implemente el acceso a la base por parte de los procesos, sabiendo que el motor de base de datos puede atender a lo sumo 5 consultas de lectura simultáneas.

### Respuestas

**a) y b)**

```c
Monitor BaseDeDatos {
    cond cola;
    int cantidadLectores= 0;

    Procedure leer() {
        while ( cantidadLectores > 5) wait (cola);
        cantidadLectores ++;
    }

    Procedure liberar() {
        cantidadLectores --;
        signal(cola);
    }
}

Process Procesos [a:1..N] {
    BaseDeDatos.leer();
    # Leer de la base de datos
    BaseDeDatos.liberar();
}
```

## Ejercicio 3

Existen N personas que deben fotocopiar un documento. La fotocopiadora sólo puede ser usada por una persona a la vez. Analice el problema y defina qué procesos, recursos y monitores serán necesarios/convenientes, además de las posibles sincronizaciones requeridas para resolver el problema. Luego, resuelva considerando las siguientes situaciones:
- **a)** Implemente una solución suponiendo no importa el orden de uso. Existe una función ```Fotocopiar()``` que simula el uso de la fotocopiadora. 
- **b)** Modifique la solución de (a) para el caso en que se deba respetar el orden de llegada.
- **c)** Modifique la solución de (b) para el caso en que se deba dar prioridad de acuerdo con la edad de cada persona (cuando la fotocopiadora está libre la debe usar la persona de mayor edad entre las que estén esperando para usarla).
- **d)** Modifique la solución de (a) para el caso en que se deba respetar estrictamente el orden dado por el identificador del proceso (la persona X no puede usar la fotocopiadora hasta que no haya terminado de usarla la persona X-1).
- **e)** Modifique la solución de (b) para el caso en que además haya un Empleado que le indica a cada persona cuando debe usar la fotocopiadora.
- **f)** Modificar la solución (e) para el caso en que sean 10 fotocopiadoras. El empleado le indica a la persona cuál fotocopiadora usar y cuándo hacerlo.

### Respuestas

**a)**

```c
Monitor Fotocopiadora {
    Procedure Fotocopiar(documento: in Documento; copia: out Documento) {
        copia = Fotocopiar(documento);
    }
}

Process Persona [a:1..N] {
    Documento copia; Documento documento;
    Fotocopiadora.Fotocopiar(documento, copia);
}
```

**b)**

```c
Monitor Fotocopiadora {
    cond cola;
    bool libre = true;
    int personasEsperando = 0;

    Procedure usarFotocopiadora() {
        if (!libre) {
            personasEsperando ++;
            wait(cola);
        } else {
            libre = false;
        }
    }

    Procedure liberarFotocopiadora() {
        if (personasEsperando == 0) {
            libre = true;
        } else {
            personasEsperando --;
            signal(cola);
        }
    }
}

Process Persona [a:1..N] {
    Documento copia; Documento documento;
    Fotocopiadora.usarFotocopiadora();
    copia = Fotocopiar(documento);
    Fotocopiadora.liberarFotocopiadora();
}
```

**c)**

```c
Monitor Fotocopiadora {
    cond espera[N];
    bool libre = true;
    Cola cola;

    Procedure usarFotocopiadora(id: in int; edad: in int) {
        if (!libre) {
            insertarOrdenado(cola, id, edad);
            wait(espera[id]);
        } else {
            libre = false;
        }
    }

    Procedure liberarFotocopiadora() {
        int id;
        if (empty(cola)) {
            libre = true;
        } else {
            id = sacar(cola);
            signal(espera[id]);
        }
    }
}

Process Persona [a:1..N] {
    Documento copia; Documento documento;
    int edad = X;
    Fotocopiadora.usarFotocopiadora(a, edad);
    copia = Fotocopiar(documento);
    Fotocopiadora.liberarFotocopiadora();
}
```

**d)**

```c
Monitor Fotocopiadora {
    cond espera[N];
    int proximo = 1;

    Procedure usarFotocopiadora(id: in int) {
        if (id != proximo) {
            wait(espera[id]);
        }
    }

    Procedure Fotocopiar(documento: in Documento; copia: out Documento) {
        copia = Fotocopiar(documento);
        proximo ++;
        signal(espera[proximo]);
    }
}

Process Persona [a:1..N] {
    Documento copia; Documento documento;
    Fotocopiadora.usarFotocopiadora(a);
    Fotocopiadora.Fotocopiar(documento, copia);
}
```

**e)**

```c
Monitor Fotocopiadora {
    cond cola; cond empleado; cond impresoraLibre;
    int personasEsperando = 0;

    Procedure solicitarFotocopiadora() {
        personasEsperando ++;
        signal(empleado);
        wait(cola);
    }

    Procedure usarFotocopiadora() {
        if (personasEsperando == 0) {
            wait(empleado);
        }
        personasEsperando --;
        signal(cola);
        wait(impresoraLibre);
    }

    Procedure liberarFotocopiadora() {
        signal(impresoraLibre);
    }
}

Process Persona [a:1..N] {
    Documento copia; Documento documento;
    Fotocopiadora.solicitarFotocopiadora();
    copia = Fotocopiar(documento);
    Fotocopiadora.liberarFotocopiadora();
}

Process Empleado {
    for [int i = 1; i < N; i ++] {
        Fotocopiadora.usarFotocopiadora();
    }
}
```

**f)**

```c
Monitor Fotocopiadora {
    cond empleado; cond impresoraLibre; cond esperarUso[N];
    cola impresoras[10] = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10); cola personasEsperando;
    int fotocopiadoraAsignada[N] = ([N] 0);

    Procedure solicitarFotocopiadora(id: in int; fotocopiadora: out int) {
        personasEsperando.push(id);  // me encolo en la lista de personas esperando
        signal(empleado);  // aviso de pedido
        wait(esperarUso[id]);  // espero a que me hayan asigando una fotocopiadora
        fotocopiadora = fotocopiadoraAsignada[id];  // asigno la fotocopiadora
    }

    Procedure usarFotocopiadora() {
        if (personasEsperando.empty()) {  // si no hay nadie esperando me duermo
            wait(empleado);
        }
        int id = personasEsperando.pop();
        if (impresoras.empty()) {  // si no hay fotocopiadoras libres me duermo
            wait(impresoraLibre);
        }
        fotocopiadoraAsignada[id] = impresoras.pop();
        signal(esperarUso[id]);  // aviso de que ya asigné una fotocopiadora
    }

    Procedure liberarFotocopiadora(fotocopiadora: in int) {
        impresoras.push(fotocopiadora);  // devuelvo la fotocopiadora
        signal(impresoraLibre);  // aviso de que hay una fotocopiadora libre
    }
}

Process Persona [a:1..N] {
    Documento copia; Documento documento;
    int fotocopiadora;
    Fotocopiadora.solicitarFotocopiadora(a, fotocopiadora);
    copia = fotocopiador.Fotocopiar(documento);
    Fotocopiadora.liberarFotocopiadora(fotocopiadora);
}

Process Empleado {
    for [int i = 1; i < N; i ++] {
        Fotocopiadora.usarFotocopiadora();
    }
}
```

## Ejercicio 4

Existen N vehículos que deben pasar por un puente de acuerdo con el orden de llegada. Considere que el puente no soporta más de 50000kg y que cada vehículo cuenta con su propio peso (ningún vehículo supera el peso soportado por el puente).

### Respuesta

```c
Monitor Puente{
    bool pasando = true;
    int vehiculosEsperando = 0;
    int pesoAcumulado = 0;
    cond autosEsperando;
    cond pesoAdecuado;

    Procedure entrarAlPuente (peso: in int){
        if (!pasando){  // si hay alguien queriendo pasar
            vehiculosEsperando++;
            wait(autosEsperando);  // me quedo esperando para respetar el orden
        }
        else {
            pasando = false;  // indico que estoy queriendo pasar
        }
        while (pesoAcumulado + peso > 50000){  // si con mi peso supero el peso máximo, espero
            wait(pesoAdecuado);
        }
        pesoAcumulado += peso;  // sumo mi peso al acumulado porque puedo pasar
        if (esperando > 0){  // si hay alguien esperando, aviso que puede pasar
            esperando--;
            signal(auto);  // despierto al auto que estaba esperando
        }
        else {
            pasando = true;  // indico que el puente está libre y no hay nadie esperando
        }
    }

    Procedure dejar (peso: in int){
        pesoAcumulado -= peso;
        signal(pesoAdecuado);  // hago que pase el vehículo que no podía por peso
    }
}

Process Vehiculo [a:1..N] {
    int peso = X;
    Puente.entrarAlPuente(peso);
    // Pasar por el puente
    Puente.salirDelPuente(peso);
}
```

## Ejercicio 5

En un corralón de materiales se deben atender a N clientes de acuerdo con el orden de llegada. Cuando un cliente es llamado para ser atendido, entrega una lista con los productos que comprará, y espera a que alguno de los empleados le entregue el comprobante de la compra realizada.
- **a)** Resuelva considerando que el corralón tiene un único empleado.
- **b)** Resuelva considerando que el corralón tiene E empleados (E > 1). Los empleados no deben terminar su ejecución.
- **c)** Modifique la solución (b) considerando que los empleados deben terminar su ejecución cuando se hayan atendido todos los clientes.

### Respuestas

**a)**

```c
Monitor Corralon {
    cond clientesEsperandoASerAtendido; cond empleado; cond hayLista; cond hayComprobante; cond retiroComprobante;
    int esperando = 0;
    ListaDeProductos listaDeProductosActual;
    Comprobante comprobanteActual;


    Procedure solicitarAtencion(listaDeProductos: in ListaDeProductos) {
        esperando++;
        signal(empleado);  // aviso al empleado que hay un cliente esperando
        wait(clientesEsperandoASerAtendido);  // espero a que me llamen
        listaDeProductosActual = listaDeProductos;  // brindo mi lista de productos
        signal(hayLista);  // aviso que entregué mi lista de productos
    }

    Procedure atenderCliente() {
        if (esperando == 0) {  // si no hay nadie esperando, me duermo
            wait(empleado);  
        }
        esperando--;
        signal(clientesEsperandoASerAtendido);  // aviso al cliente
        wait(hayLista);  // espero a que me dé la lista de productos
        commprobanteActual = generarComprobante(listaDeProductosActual);  // le genero el comprobante
        signal(hayComprobante);  // aviso que ya tiene el comprobante
        wait(retiroComprobante);  // espero que el cliente retire el comprobante para atender al siguiente
    }

    Procedure retirarComprobante(comprobante: out Comprobante) {
        wait(hayComprobante);  // espero a que me entreguen el comprobante
        comprobante = comprobanteActual;
        signal(retiroComprobante);  // aviso que ya lo retiré
    }
}

Process Cliente [a:1..N] {
    ListaDeProductos listaDeProductos;
    Comprobante comprobante;
    Corralon.solicitarAtencion(listaDeProductos);
    Corralon.retirarComprobante(comprobante);
}

Process Empleado {
    for [int i = 1; i < N; i ++] {
        Corralon.atenderCliente();
    }
}
```

**b)**

```c
Monitor Corralon {
    int cantidadDeEmpleadosLibres = 0; int esperando = 0; 
    cola empleadosLibres;
    cond clientesEsperando;

    Procedure llegada (empleadoAsignado: out int) {
        if (cantidadDeEmpleadosLibres == 0) {  // si no hay  empleados libres, espero
            esperando++;
            wait(clientesEsperando);
        } else {
            cantidadDeEmpleadosLibres--;  // disminuyo la cantidad de empleados libres
        }
        empleadoAsignado = empleadosLibres.pop();  // agarro un empleado libre
    }

    Procedure proximo(numeroDeEmpleado: in int) {
        empleadosLibres.push(numeroDeEmpleado);  // vuelvo al empleado a la cola de empleados libres
        if (esperando > 0) {  // si hay alguien esperando, aviso que puede pasar
            esperando--;
            signal(clientesEsperando);
        } else {
            cantidadDeEmpleadosLibres++;  // aumento la cantidad de empleados libres
        }
    }
}

Monitor Escritorio[id:1..E] {
    ListaDeProductos listaDeProductosActual;
    Comprobante comprobanteActual;
    bool hayDatos = false;
    cond datos;
    cond atencionDeEmpleado;

    Procedure atencion(listaDeProductos: in ListaDeProductos; comprobante: out Comprobante) {
        listaDeProductosActual = listaDeProductos;  // guardo la lista de productos a procesar
        hayDatos = true;  // aviso que llego el cliente 
        signal(datos);  // aviso que ya están los datos
        wait(atencionDeEmpleado);  // espero a que el empleado termine
        comprobante = comprobanteActual;  // guardo el comprobante
        signal(datos);  // aviso que ya retiró el comprobante
    }

    Procedure obtenerLista(listaDeProductos: out ListaDeProductos) {
        if (!hayDatos) {  // si no hay datos, espero
            wait(datos);
        }
        listaDeProductos = listaDeProductosActual;
    }

    Procedure dejarComprobante(comprobante: in Comprobante) {
        comprobanteActual = comprobante;
        signal(atencionDeEmpleado);  // aviso que se puede retirar el comprobante
        wait(datos);  // espero que retire el comprobante
        hayDatos = false;  // aviso que el cliente se fue
    }
}

Process Cliente[id:1..N] {
    int empleadoAsignado;
    Comprobante comprobante;
    ListaDeProductos listaDeProductos;
    Corralon.llegada(empleadoAsignado);
    Escritorio[empleadoAsignado].atencion(listaDeProductos, comprobante);
}

Process Empleado[id:1..E] {
    ListaDeProductos listaDeProductos;
    while (true) {
        Corralon.proximo(id);
        Escritorio[id].obtenerLista(listaDeProductos);
        Comprobante comprobante = generarComprobante(listaDeProductos);
        Escritorio[id].dejarComprobante(comprobante);
    }
}
```

**c)**

```c
Monitor Corralon {
    int cantidadDeEmpleadosLibres = 0; int esperando = 0; int cantidadAtendidos = 0;
    cola empleadosLibres;
    cond clientesEsperando;

    Procedure llegada (empleadoAsignado: out int) {
        if (cantidadDeEmpleadosLibres == 0) {  // si no hay  empleados libres, espero
            esperando++;
            wait(clientesEsperando);
        } else {
            cantidadDeEmpleadosLibres--;  // disminuyo la cantidad de empleados libres
        }
        empleadoAsignado = empleadosLibres.pop();  // agarro un empleado libre
    }

    Procedure proximo(numeroDeEmpleado: in int; seguirTrabajando: out bool) {
        if (cantidadAtendidos == N) {
            seguirTrabajando = false;
        } else {
            cantidadAtendidos++;
            seguirTrabajando = true;
            empleadosLibres.push(numeroDeEmpleado);  // vuelvo al empleado a la cola de empleados libres
            if (esperando > 0) {  // si hay alguien esperando, aviso que    puede pasar
                esperando--;
                signal(clientesEsperando);
            } else {
                cantidadDeEmpleadosLibres++;  // aumento la cantidad de     empleados libres
            }
        }
    }
}

Monitor Escritorio[id:1..E] {
    ListaDeProductos listaDeProductosActual;
    Comprobante comprobanteActual;
    bool hayDatos = false;
    cond datos;
    cond atencionDeEmpleado;

    Procedure atencion(listaDeProductos: in ListaDeProductos; comprobante: out Comprobante) {
        listaDeProductosActual = listaDeProductos;  // guardo la lista de productos a procesar
        hayDatos = true;  // aviso que llego el cliente 
        signal(datos);  // aviso que ya están los datos
        wait(atencionDeEmpleado);  // espero a que el empleado termine
        comprobante = comprobanteActual;  // guardo el comprobante
        signal(datos);  // aviso que ya retiró el comprobante
    }

    Procedure obtenerLista(listaDeProductos: out ListaDeProductos) {
        if (!hayDatos) {  // si no hay datos, espero
            wait(datos);
        }
        listaDeProductos = listaDeProductosActual;
    }

    Procedure dejarComprobante(comprobante: in Comprobante) {
        comprobanteActual = comprobante;
        signal(atencionDeEmpleado);  // aviso que se puede retirar el comprobante
        wait(datos);  // espero que retire el comprobante
        hayDatos = false;  // aviso que el cliente se fue
    }
}

Process Cliente[id:1..N] {
    int empleadoAsignado;
    Comprobante comprobante;
    ListaDeProductos listaDeProductos;
    Corralon.llegada(empleadoAsignado);
    Escritorio[empleadoAsignado].atencion(listaDeProductos, comprobante);
}

Process Empleado[id:1..E] {
    ListaDeProductos listaDeProductos;
    bool seguirTrabajando = true;
    while (seguirTrabajando) {
        Corralon.proximo(id, seguirTrabajando);
        if (seguirTrabajando) {
            Escritorio[id].obtenerLista(listaDeProductos);
            Comprobante comprobante = generarComprobante(listaDeProductos);
            Escritorio[id].dejarComprobante(comprobante);
        }
    }
}
```

## Ejercicio 6

Existe una comisión de 50 alumnos que deben realizar tareas de a pares, las cuales son corregidas por un JTP. Cuando los alumnos llegan, forman una fila. Una vez que están todos en fila, el JTP les asigna un número de grupo a cada uno. Para ello, suponga que existe una función ```AsignarNroGrupo()``` que retorna un número “aleatorio” del 1 al 25. Cuando un alumno ha recibido su número de grupo, comienza a realizar su tarea. Al terminarla, el alumno le avisa al JTP y espera por su nota. Cuando los dos alumnos del grupo completaron la tarea, el JTP les asigna un puntaje (el primer grupo en terminar tendrá como nota 25, el segundo 24, y así sucesivamente hasta el último que tendrá nota 1). **Nota:** el JTP no guarda el número de grupo que le asigna a cada alumno.

### Respuesta

```c
Monitor Tarea {
    cola alumnos; cola numeroDeGruposDeAlumnosTeminados;
    cond avisoAlProfesor; cond avisoDeInicio[50]; cond esperaDeNotas[25];
    int numeroDeGrupoPorAlumno[50] = ([50] -1); int puntajePorGrupo[25] = ([25] 0); int alumnosTerminadosPorGrupo[25] = ([25] 0);


    Procedure llegadaAlumno(id: in int) {
        alumnos.push(id);  // me encolo en la cola de alumnos
        if (alumnos.size() == 50) {  // si soy el último alumno en llegar, aviso al profesor
            signal(avisoAlProfesor);
        }
    }

    Procedure esperarLlegadaAlumnos() {
        if (alumnos.size() < 50) { // si todavía no llegaron todos los alumnos, espero
            wait(avisoAlProfesor);
        }
    }

    Procedure asignarGrupo() {
        for (int i = 0; i < 50; i++) {
            int alumno = alumnos.pop();
            numeroDeGrupoPorAlumno[alumno] = AsignarNroGrupo();  // asigno un número de grupo al alumno
            signal(avisoDeInicio[alumno]);  // le aviso al alumno que puede comenzar
        }
    }

    Procedure recibirNumeroDeGrupo(id: in int; grupo: out int) {
        wait(avisoDeInicio[id]);  // espero a que el profesor me asigne un número de grupo
        grupo = numeroDeGrupoPorAlumno[id];
    }

    Procedure asignarNota(puntaje: in int) {
        if (numeroDeGruposDeAlumnosTeminados.empty()) {  // si no hay alumno que haya terminado, espero
            wait(avisoAlProfesor);
        }
        int grupo = numeroDeGruposDeAlumnosTeminados.pop();
        alumnosTerminadosPorGrupo[grupo]++;
        if (alumnosTerminadosPorGrupo[grupo] == 2) {  // si terminaron los dos alumnos del grupo, asigno la nota
            puntajePorGrupo[grupo] = puntaje;
        }
        signal_all(esperaDeNotas[grupo]);  // despierto a los alumnos del grupo
    }

    Procedure recibirNota(grupo: in int; nota: out int) {
        numeroDeGruposDeAlumnosTeminados.push(grupo);  // encolo el numero de grupo del alumno que terminó
        signal(avisoAlProfesor);  // aviso al profesor que terminó un alumno
        wait(esperaDeNotas[grupo]);  // espero la nota de mi grupo
        nota = puntajePorGrupo[grupo];
    }
}

Process Alumno[id:1..50] {
    int grupo; int nota;
    Tarea.llegadaAlumno(id);
    Tarea.recibirNumeroDeGrupo(id, grupo);
    // hacer tarea
    Tarea.recibirNota(grupo, nota);
}

Process JTP {
    int puntaje = 25;
    Tarea.esperarLlegadaAlumnos();
    Tarea.asignarGrupo();
    for (int i = 0; i < 50; i++) {
        Tarea.asignarNota(puntaje);
        puntaje--;
    }
}
```

## Ejercicio 7

Se debe simular una maratón con C corredores donde en la llegada hay UNA máquina expendedoras de agua con capacidad para 20 botellas. Además, existe un repositor encargado de reponer las botellas de la máquina. Cuando los C corredores han llegado al inicio comienza la carrera. Cuando un corredor termina la carrera se dirigen a la máquina expendedora, espera su turno (respetando el orden de llegada), saca una botella y se retira. Si encuentra la máquina sin botellas, le avisa al repositor para que cargue nuevamente la máquina con 20 botellas; espera a que se haga la recarga; saca una botella y se retira. **Nota:** mientras se reponen las botellas se debe permitir que otros corredores se encolen.

### Respuesta

```c
Monitor Maraton {
    cola corredores;
    cond avisoDeIncio; cond corredores;
    int esperando = 0;
    bool maquinaLibre = true;

    Procedure llegadaCorredor(id: in int) {
        corredores.push(id);  // me encolo en la cola de corredores
        if (corredores.size() == C) {  // si soy el último corredor en llegar, doy aviso de inicio de Maratón
            signal_all(avisoDeIncio);
        }
    }

    Procedure esperarLlegadaCorredores() {
        if (corredores.size() < C) {  // si no llegaron todos los corredores, espero
            wait(avisoDeIncio);
        }
    }

    Procedure accederALaMaquina() {
        if (!maquinaLibre) {  // si la máquina no está libre, espero por orden de llegada
            esperando++;
            wait(corredores);
        } else {
            maquinaLibre = false;
        }
    }

    Procedure dejarLaMaquina() {
        if (esperando > 0) {  // si hay alguien esperando, despierto al siguiente que está esperando
            esperando--;
            signal(corredores);
        } else {  // sino, la máquina queda libre
            maquinaLibre = true;
        }
    }
}

Monitor Maquina {
    int botellas = 20;
    cond esperaReponer; cond esperaMaquinaLlena;

    Procedure tomarAgua() {
        if (botellas == 0) {  // si no hay botellas, doy aviso de reposción y me encolo para tomar agua
            signal(esperaReponer);
            wait(esperaMaquinaLlena);
        } else {
            botellas--;
        }
    }

    Procedure esperaReponer() {
        if (botellas > 0) {  // si todavía la máquina tiene botellas, espero
            wait(esperaReponer);
        }
    }

    Procedure reponer() {
        botellas = 20;  
        signal(esperaMaquinaLlena);  // repongo y doy aviso a el primero que estaba esperando
    }
}

Process Corredor[id:1..C] {
    Maraton.llegadaCorredor(id);
    Maraton.esperarLlegadaCorredores();
    // corro la maratón
    Maraton.accederALaMaquina();
    Maquina.tomarAgua();
    Maraton.dejarLaMaquina();
}

Procces Repositor {
    while (true) {
        Maquina.esperaReponer();
        Maquina.reponer();
    }
}
```

## Ejercicio 8

En un entrenamiento de fútbol hay 20 jugadores que forman 4 equipos (cada jugador conoce el equipo al cual pertenece llamando a la función ```DarEquipo()```). Cuando un equipo está listo (han llegado los 5 jugadores que lo componen), debe enfrentarse a otro equipo que también esté listo (los dos primeros equipos en juntarse juegan en la cancha 1, y los otros dos equipos juegan en la cancha 2). Una vez que el equipo conoce la cancha en la que juega, sus jugadores se dirigen a ella. Cuando los 10 jugadores del partido llegaron a la cancha comienza el partido, juegan durante 50 minutos, y al terminar todos los jugadores del partido se retiran (no es necesario que se esperen para salir).

### Respuesta

```c
Monitor Equipo[id:1..4] {
    int jugadores = 0; int numeroDeCanchaAsignada;
    cond esperaJugadores;

    Procedure jugadorLlega(numeroDeCancha: out int) {
        jugadores++;
        if (jugadores < 5) {  // si no llegaron los 5 jugadores, espero
            wait(esperaJugadores);
        } else {
            Administrador.asignarCancha(numeroDeCanchaAsignada);  // le pido al administrador que me asigne una cancha
            signal_all(esperaJugadores);
        }
        numeroDeCancha = numeroDeCanchaAsignada;
    }
}

Monitor Administrador {
    int cantidadDeEquipos = 0;

    Procedure asignarCancha(numeroDeCancha: out int) {
        cantidadDeEquipos++;
        if (cantidadDeEquipos <= 2) {  // aigno cancha de acuerdo al número de equipos que llegaron
            numeroDeCancha = 1;
        } else {
            numeroDeCancha = 2;
        }
    }
}

Monitor Cancha[id:1..2] {
    int jugadoresEnCancha = 0;
    cond espera; cond inicio;

    Procedure llegada() {
        jugadoresEnCancha++;
        if (jugadoresEnCancha == 10) {  // si llegaron todos los jugadores, inicio el partido
            signal(inicio);
        }
        wait(espera);
    }

    Procedure iniciar() {
        if (jugadoresEnCancha < 10) {  // si no llegaron todos los jugadores, espero
            wait(inicio);
        }
    }

    Procedure terminar() {
        signal_all(espera);  // doy acho a todos los jugadores para que se vayan
    }
}

Procces Jugador[id:1..20] {
    int equipo = DarEquipo(); 
    int numeroDeCancha;
    Equipo[equipo].jugadorLlega(numeroDeCancha);  // obtengo la cancha a la que voy a ir
    Cancha[numeroDeCancha].llegada();
}

Procces Partido[id:1..2] {
    Cancha[id].iniciar();
    delay(50);  // se juega el picadito por la coca
    Cancha[id].terminar();
}
```

## Ejercicio 9

En un examen de la secundaria hay un preceptor y una profesora que deben tomar un examen escrito a 45 alumnos. El preceptor se encarga de darle el enunciado del examen a los alumnos cuando los 45 han llegado (es el mismo enunciado para todos). La profesora se encarga de ir corrigiendo los exámenes de acuerdo con el orden en que los alumnos van entregando. Cada alumno al llegar espera a que le den el enunciado, resuelve el examen, y al terminar lo deja para que la profesora lo corrija y le envíe la nota. **Nota:** maximizar la concurrencia; todos los procesos deben terminar su ejecución; suponga que la profesora tiene una función ```corregirExamen``` que recibe un examen y devuelve un entero con la nota. 

### Respuesta

```c
Monitor Examen {
    cola alumnos; cola examenesTerminados;
    cond avisoPreceptor; cond esperarEnunciado[45]; cond alumnosEsperandoCorrecion;
    int enunciados[45]; int alumnosEsperando = 0;
    bool profesoraLibre = true;

    Procedure llegadaAlumno(id: in int; enunciado: out Enunciado) {
        alumnos.push(id);
        if (alumnos.size() == 45) {  // si llegaron todos los alumnos, aviso al preceptor
            signal(avisoPreceptor);
        }
        wait(esperarEnunciado[id]);
        enunciado = enunciados[id];
    }

    Procedure esperarLlegadaAlumos() {
        if (allumnos.size() < 45) {  // si no llegaron todos los alumnos, espero
            wait(avisoPreceptor);
        }
    }

    Procedure darEnunciado() {
        for (int i = 0; i < 45; i++) {
            int id = alumnos.pop();
            enunciados[i] = entregarEnunciado();
            signal(esperarEnunciado[id]);
        }
    }

    Procedure esperarCorrecion() {
        if (!profesoraLibre) {  // si la profesora no está libre, espero
            alumnosEsperando++;
            wait(alumnosEsperandoCorrecion);
        } else {
            profesoraLibre = false;
        }
    }

    Procedure liberarProfesora() {
        if (alumnosEsperando > 0) {  // si hay alumnos esperando, aviso que puede corregir
            alumnosEsperando--;
            signal(alumnosEsperandoCorrecion);
        } else {
            profesoraLibre = true;
        }
    }
}

Monitor Escritorio {
    Enunciado enunciadoActual;
    int notaDelEnunciadoActual;
    bool hayEnunciado = false;
    cond enunciado; cond correcionProfesora;

    Procedure correcion(enunciado: in Enunciado; nota: out int) {
        enunciadoActual = enunciado;
        hayEnunciado = true;
        signal(enunciado);
        wait(correcionProfesora);
        nota = notaDelEnunciadoActual;
    }

    Procedure esperarEnunciado(enunciado: out Enunciado) {
        if (!hayEnunciado) {  // si no hay enunciado, espero
            wait(enunciado);
        }
        enunciado = enunciadoActual;
    }

    Procedure entegarNota(nota: in int) {
        notaDelEnunciadoActual = nota;
        signal(correcionProfesora);
        hayEnunciado = false;
    }
}

Process Alumno[id:1..45] {
    Enunciado enunciado;
    int nota;
    Examen.llegadaAlumno(id, enunciado);
    // hace el examen
    Examen.esperarCorrecion();
    Escritorio.correcion(enunciado, nota);
    Examen.liberarProfesora();
}

Process Preceptor {
    Examen.esperarLlegadaAlumos();
    Examen.darEnunciado(enunciado);
}

Process Profesora {
    Enunciado enunciado;
    int nota;
    for (int i = 0; i < 45; i++) {
        Escritorio.esperarEnunciado(enunciado);
        nota = corregirExamen(enunciado);
        Escritorio.entegarNota(nota);
    }
}
```

## Ejercicio 10

En un parque hay un juego para ser usada por N personas de a una a la vez y de acuerdo al orden en que llegan para solicitar su uso. Además, hay un empleado encargado de desinfectar el juego durante 10 minutos antes de que una persona lo use. Cada persona al llegar espera hasta que el empleado le avisa que puede usar el juego, lo usa por un tiempo y luego lo devuelve. **Nota:** suponga que la persona tiene una función ```Usar_juego``` que simula el uso del juego; y el empleado una función ```Desinfectar_Juego``` que simula su trabajo. Todos los procesos deben terminar su ejecución.

### Respuesta

```c
Monitor Juego {
    int personasEsperando = 0;
    bool juegoLibre = false;
    cond personasEsperandoJuego;

    Procedure accesoJuego() {
        if (!juegoLibre) {
            personasEsperando++;
            wait(personasEsperandoJuego);
        } else {
            juegoLibre = false;
        }
    }

    Procedure liberarJuego() {
        signal(juegoLiberado);
    }

    Procedure avisarSiguiente() {
        if (personasEsperando > 0) {
            personasEsperando--;
            signal(personasEsperandoJuego);
        } else {
            juegoLibre = true;
        }
        wait(juegoLiberado);
    }
}

Process Persona[id:1..N] {
    Juego.accesoJuego();
    Usar_juego();
    Juego.liberarJuego();
}

Process Empleado {
    for (int i = 0; i < N; i++) {
        Desinfectar_Juego();
        delay(10);
        Juego.avisarSiguiente();
    }
}
```