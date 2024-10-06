# Práctica de Repaso - Memoria Compartida

# Semáforos

## Ejercicio 1

Resolver los problemas siguientes:
- **a)** En una estación de trenes, asisten P personas que deben realizar una carga de su tarjeta SUBE en la terminal disponible. La terminal es utilizada en forma exclusiva por cada persona de acuerdo con el orden de llegada. Implemente una solución utilizando únicamente procesos Persona. **Nota:** la función UsarTerminal() le permite cargar la SUBE en la terminal disponible. 
- **b)** Resuelva el mismo problema anterior pero ahora considerando que hay T terminales disponibles. Las personas realizan una única fila y la carga la realizan en la primera terminal que se libera. Recuerde que sólo debe emplear procesos Persona. Nota: la función UsarTerminal(t) le permite cargar la SUBE en la terminal t

### Respuestas

**a)**

```c
ColaOrdenLlegada cola;
bool libre = true;
sem mutex = 1; sem espera[P] = ([P] 0);

Process Persona[a:1..P] {
    int siguiente;
    P(mutex);
    if (libre) {  // si la terminal está libre, la uso
        libre = false;
        V(mutex);
    } else {  // sino, espero en la cola
        cola.push(id);
        V(mutex);
        P(espera[id]);
    }
    UsarTerminal();  // uso la terminal
    P(mutex);
    if (cola.isEmpty()) {  // si no hay nadie esperando, libero la terminal
        libre = true; 
    } else {  // sino, aviso a la persona siguiente
        siguiente = cola.pop();
        V(espera[siguiente]);
    }
    V(mutex);
}
```

**b)**

```c
ColaOrdenLlegada cola;
Terminales terminalesLibres; Terminales terminalPorPersona[P];
sem espera[P] = ([P] 0); sem mutexTerminales = 1; sem mutexCola = 1;

Process Persona[a:1..P] {
    int siguiente;
    P(mutexTerminales);
    if (!terminalesLibres.isEmpty()) {  // si hay terminales libres, asigno una
        terminalPorPersona[id] = terminalesLibres.pop();
        V(mutexTerminales);
    } else {  // sino, espero en la cola
        V(mutexTerminales);
        P(mutexCola);
        cola.push(id);
        V(mutexCola);
        P(espera[id]);
    }
    UsarTerminal(terminalPorPersona[id]);  // uso la terminal
    P(mutexTerminales);
    P(mutexCola);
    if (cola.isEmpty()) {  // si no hay nadie esperando, libero la terminal
        V(mutexCola);
        terminalesLibres.push(terminalPorPersona[id]);
        V(mutexTerminales);
    } else {  // se la asigno al siguiente
        V(mutexTerminales);
        siguiente = cola.pop();
        V(mutexCola);
        terminalPorPersona[siguiente] = terminalPorPersona[id];
        V(espera[siguiente]);
    }
}
```

## Ejercicio 2

Implemente una solución para el siguiente problema. Un sistema debe validar un conjunto de 10000 transacciones que se encuentran disponibles en una estructura de datos. Para ello, el sistema dispone de 7 workers, los cuales trabajan colaborativamente validando de a 1 transacción por vez cada uno. Cada validación puede tomar un tiempo diferente y para realizarla los workers disponen de la función Validar(t), la cual retorna como resultado un número entero entre 0 al 9. Al finalizar el procesamiento, el último worker en terminar debe informar la cantidad de transacciones por cada resultado de la función de validación. **Nota:** maximizar la concurrencia. 

### Respuesta

```c
int vectorContador[9] = ([9] 0);
Transacciones transacciones;
sem mutexTransacciones = 1; sem mutexContador[9] = ([9] 1); sem mutexWorker = 1;
int workersTerminados = 0;

Process Worker[a:1..7] {
    Transaccion transaccion;
    int resultado;
    P(mutexTransacciones);
    while (!transacciones.isEmpty()) {  // si hay transacciones, las proceso
        transaccion = transacciones.pop();
        V(mutexTransacciones);
        resultado = Validar(transaccion);
        P(mutexContador[resultado]);
        vectorContador[resultado]++;  // sumo 1 al contador del resultado
        V(mutexContador[resultado]);
        P(mutexTransacciones);
    }
    V(mutexTransacciones);
    P(mutexWorker);
    workersTerminados++;  // aumento la cantidad de workers terminados
    if (workersTerminados == 7) {  // si todos terminaron, imprimo el resultado
        for (int i = 0; i < 9; i++) {
            print(vectorContador[i]);
        }
    }
    V(mutexWorker);
}
```

## Ejercicio 3

Implemente una solución para el siguiente problema. Se debe simular el uso de una máquina expendedora de gaseosas con capacidad para 100 latas por parte de U usuarios. Además, existe un repositor encargado de reponer las latas de la máquina. Los usuarios usan la máquina según el orden de llegada. Cuando les toca usarla, sacan una lata y luego se retiran. En el caso de que la máquina se quede sin latas, entonces le debe avisar al repositor para que cargue nuevamente la máquina en forma completa. Luego de la recarga, saca una botella y se retira. **Nota:** maximizar la concurrencia; mientras se reponen las latas se debe permitir que otros usuarios puedan agregarse a la fila.

### Respuesta

```c
bool maquinaLibre = true;
ColaOrdenLlegada cola;
sem mutexCola = 1; sem espera[U] = ([U] 0); sem avisoRepositor = 0; sem esperaReposicion = 0;
Latas latas;

Process Usuario[a:1..U] {
    Lata lata;
    int siguiente;
    P(mutexCola);
    if (maquinaLibre) {  // si la máquina está libre, la uso
        maquinaLibre = false;
        V(mutexCola);
    } else {
        cola.push(id);
        V(mutexCola);
        P(espera[id]);
    }
    if (latas.isEmpty()) {  // si no hay latas, aviso al repositor
        V(avisoRepositor);
        P(esperaReposicion);
    }
    lata = latas.pop();
    P(mutexCola);
    if (cola.isEmpty()) {  // si no hay nadie esperando, libero la máquina
        maquinaLibre = true;
        V(mutexCola);
    } else {
        siguiente = cola.pop();
        V(mutexCola);
        V(espera[siguiente]);
    }
}

Process Repositor {
    for (int i = 0; i < (U / 100); i++) {
        P(avisoRepositor);
        latas.push(100);
        V(esperaReposicion);
    }
}
```

# Monitores

## Ejercicio 1

Resolver el siguiente problema. En una elección estudiantil, se utiliza una máquina para voto electrónico. Existen N Personas que votan y una Autoridad de Mesa que les da acceso a la máquina de acuerdo con el orden de llegada, aunque ancianos y embarazadas tienen prioridad sobre el resto. La máquina de voto sólo puede ser usada por una persona a la vez. **Nota:** la función Votar() permite usar la máquina.

### Respuesta

```c
Monitor Votacion {
    ColaPersonas personasSinPrioridad; ColaPersonas personasConPrioridad;
    cond avisoAutoridad; cond esperoUso[N]; cond terminoUso;
    int personasEsperando = 0;

    Procedure SolicitarMaquina(id: in int, tienePrioridad: in bool) {
        personasEsperando++;
        if (tienePrioridad) {  // si tiene prioridad, lo encolo en la cola de prioridad
            personasConPrioridad.push(id);
        } else {
            personasSinPrioridad.push(id);
        }
        signal(avisoAutoridad);  // aviso a la autoridad
        wait(esperoUso[id]);  // espero a que me den la máquina
    }

    Procedure DarMaquina() {
        int persona;
        if (personasEsperando == 0) {  // si no hay nadie esperando, no hago nada
            wait(avisoAutoridad);
        }
        personasEsperando--;
        if (!personasConPrioridad.isEmpty()) {
            persona = personasConPrioridad.pop();
        } else {
            persona = personasSinPrioridad.pop();
        }
        signal(esperoUso[persona]);
        wait(terminoUso);
    }

    Procedure DevolverMaquina() {
        signal(terminoUso);
    }
}

Process Persona[id:1..N] {
    bool tienePrioridad = ...;
    Votacion.SolicitarMaquina(id, tienePrioridad);
    Votacion.Votar();
    Votacion.DevolverMaquina();
}

Process AutoridadMesa {
    for (int i = 0; i < N; i++) {
        Votacion.DarMaquina();
    }
}
```

## Ejercicio 2

Resolver el siguiente problema. En una empresa trabajan 20 vendedores ambulantes que forman 5 equipos de 4 personas cada uno (cada vendedor conoce previamente a qué equipo pertenece). Cada equipo se encarga de vender un producto diferente. Las personas de un equipo se deben juntar antes de comenzar a trabajar. Luego cada integrante del equipo trabaja independientemente del resto vendiendo ejemplares del producto correspondiente. Al terminar cada integrante del grupo debe conocer la cantidad de ejemplares vendidos por el grupo. **Nota:** maximizar la concurrencia.

### Respuesta

```c
Monitor Equipos[id:1..5] {
    int cantidadVendida = 0; int vendedores = 0;
    cond avisoVendedores;

    Procedure Llegada() {
        vendedores++;
        if (vendedores == 4) {  // si llegaron todos los vendedores, los pongo a trabajar
            signal_all(avisoVendedores);
        } else {
            wait(avisoVendedores);
        }
    }

    Procedure ConsultarCantidadVendida(cantidad: in int) {
        cantidadVendida += cantidad;
        vendedores--;
        if (vendedores == 0) {  // si soy el último, aviso a los demás
            signal_all(avisoVendedores);
        } else {
            wait(avisoVendedores);
        }
        print("Cantidad vendida: " + cantidadVendida);
    }
}

Process Vendedor[id:1..20] {
    int numeroDeEquipo = ...;
    int cantidadVendida = ...;
    Equipos[numeroDeEquipo].Llegada();
    // trabaja
    Equipos[numeroDeEquipo].ConsultarCantidadVendida(cantidadVendida);
}
```

## Ejercicio 3

Resolver el siguiente problema. En una montaña hay 30 escaladores que en una parte de la subida deben utilizar un único paso de a uno a la vez y de acuerdo con el orden de llegada al mismo. **Nota:** sólo se pueden utilizar procesos que representen a los escaladores; cada escalador usa sólo una vez el paso.

### Respuesta

```c
Monitor Paso {
    int siguiente = -1; 
    bool pasoLibre = true;
    cond espera[30];
    ColaEscaladores escaladores;

    Procedure UsarPaso() {
        if (!pasoLibre) {
            escaladores.push(id);
            wait(espera[id]);
        } else {
            pasoLibre = false;
        }
    }

    Procedure Liberar() {
        if (escaladores.isEmpty()) {
            pasoLibre = true;
        } else {
            siguiente = escaladores.pop();
            signal(espera[siguiente]);
        }
    }
}

Process Escalador[id:1..30] {
    Paso.UsarPaso();
    // pasar
    Paso.Liberar();
}
```