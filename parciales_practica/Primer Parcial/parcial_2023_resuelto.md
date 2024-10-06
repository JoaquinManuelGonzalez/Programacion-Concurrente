# Parcial MC - 2023

## Ejercicio 1

Resolver con SEMÁFOROS los problemas siguientes:
**a)** En una estación de trenes, asisten P personas que deben realizar una carga de su tarjeta SUBE en la terminal disponible. La terminal es utilizada en forma exclusiva por cada persona de acuerdo con el orden de llegada. Implemente una solución utilizando sólo emplee procesos Persona. **Nota:** la función **UsarTerminal()** le permite cargar la SUBE en la terminal disponible.
**b)** Resuelva el mismo problema anterior pero ahora considerando que hay T terminales disponibles. Las personas realizan una única fila y la carga la realizan en la primera terminal que se libera. Recuerde que sólo debe emplear procesos Persona. **Nota:** la función **UsarTerminal(t)** le permite cargar la SUBE en la terminal t.

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

Resolver con MONITORES el siguiente problema: En una elección estudiantil, se utiliza una máquina para voto electrónico. Existen N Personas que votan y una Autoridad de Mesa que les da acceso a la máquina de acuerdo con el orden de llegada, aunque ancianos y embarazadas tienen prioridad sobre el resto. La máquina de voto sólo puede ser usada por una persona a la vez. **Nota:** la función **Votar()** permite usar la máquina.

### Resolución

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