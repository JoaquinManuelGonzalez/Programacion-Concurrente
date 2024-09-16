# Práctica 2 - Semáforos 

## Ejercicio 1
Existen N personas que deben ser chequeadas por un detector de metales antes de poder ingresar al avión. 

- **a)** Analice el problema y defina qué procesos, recursos y semáforos/sincronizaciones serán necesarios convenientes para resolverlo.
- **b)** Implemente una solución que modele el acceso de las personas a un detector (es decir, si el detector está libre la persona lo puede utilizar; en caso contrario, debe esperar).
- **c)** Modifique su solución para el caso que haya tres detectores.
- **d)** Modifique la solución anterior para el caso en que cada persona pueda pasar más de una vez, siendo aleatoria esa cantidad de veces. 

### Respuestas

**a) y b)**

```c
sem detectorLibre = 1;

Process Persona[id: 0 ... N-1] {
    P(detectorLibre);
    // uso del detector
    V(detectorLibre);
}
```

**c)**

```c
sem detectorLibre = 3;

Process Persona[id: 0 ... N-1] {
        P(detectorLibre);
        // uso del detector
        V(detectorLibre);
}
```

**d)** Supongo que la función random devuelve un número aleatorio entre 1 y un número dado.

```c
sem detectorLibre = 3;

Process Persona[id: 0 ... N-1] {
    int cantidadPasadas = random(N);
    for (int i = 0; i < cantidadPasadas; i++) {
        P(detectorLibre);
        // uso del detector
        V(detectorLibre);
    }
}
```

## Ejercicio 2

Un sistema de control cuenta con 4 procesos que realizan chequeos en forma colaborativa. Para ello, reciben el historial de fallos del día anterior (por simplicidad, de tamaño N). De cada fallo, se conoce su número de identificación (ID) y su nivel de gravedad (0=bajo, 1=intermedio, 2=alto, 3=crítico). Resuelva considerando las siguientes situaciones:

- **a)** Se debe imprimir en pantalla los ID de todos los errores críticos (no importa el orden).
- **b)** Se debe calcular la cantidad de fallos por nivel de gravedad, debiendo quedar los resultados en un vector global.
- **c)** Ídem b) pero cada proceso debe ocuparse de contar los fallos de un nivel de gravedad determinado.

### Respuestas

**a)**

```c
ColaFallos fallos[N];
sem mutex = 1;
int cant = 0;

Process Proceso[id: 0 ... 3] {
    Fallo fallo;
    P(mutex);
    while (cant < N) {
        fallo = fallos.pop();
        cant++;
        V(mutex);
        if (fallo.getNivelDeGravedad() == 3) {
            print(fallo.getId());
        }
        P(mutex);
    }
    V(mutex);
}
```

**b)**

```c
ColaFallos fallos[N];
int vectorContador[4] = ([4] 0);
sem mutex = 1; sem semNivel[4] = ([4] 1);
int cant = 0;

Process Proceso[id: 0 ... 3] {
    Fallo fallo;
    P(mutex);
    while (cant < N) {
        fallo = fallos.pop();
        cant++;
        V(mutex);
        P(semNivel[fallo.getNivelDeGravedad()]);
        vectorContador[fallo.getNivelDeGravedad()]++;
        V(semNivel[fallo.getNivelDeGravedad()]);
        P(mutex);
    }
    V(mutex);
}
```

**c)**

```c
ColaFallos fallos[N];
int vectorContador[4] = ([4] 0);
sem mutex = 1;
int cant = 0;

Process Proceso[id: 0 ... 3] {
    Fallo fallo;
    P(mutex);
    while (cant < N) {
        fallo = fallos.pop();
        cant++;
        V(mutex);
        if (fallo.getNivelDeGravedad() == id) {
            vectorContador[fallo.getNivelDeGravedad()]++;
        } else {
            P(mutex);
            cant--;
            fallos.push(fallo);
            V(mutex);
        }   
        P(mutex);
    }
    V(mutex);
}
```

## Ejercicio 3

Un sistema operativo mantiene 5 instancias de un recurso almacenadas en una cola. Además, existen P procesos que necesitan usar una instancia del recurso. Para eso, deben sacar la instancia de la cola antes de usarla. Una vez usada, la instancia debe ser encolada nuevamente para su reúso.

### Respuesta

```c
Cola instanciasRecurso[5];
sem instanciasRecursoLibres = 5; sem accesoCola = 1;

Process Proceso[id: 0 ... P-1] {
    Recurso recurso;
    P(instanciasRecursoLibres);
    P(accesoCola);
    recurso = instanciasRecurso.pop();
    V(accesoCola);
    // uso del recurso
    P(accesoCola);
    instanciasRecurso.push(recurso);
    V(accesoCola);
    V(instanciasRecursoLibres);
}
```

## Ejercicio 4

Suponga que existe una BD que puede ser accedida por 6 usuarios como máximo al mismo tiempo. Además, los usuarios se clasifican como usuarios de prioridad alta y usuarios de prioridad baja. Por último, la BD tiene la siguiente restricción:
- No puede haber más de 4 usuarios con prioridad alta al mismo tiempo usando la BD.
- No puede haber más de 5 usuarios con prioridad baja al mismo tiempo usando la BD. Indique si la solución presentada es la más adecuada. Justifique la respuesta.

```c
Var
    total: sem := 6;
    alta: sem := 4;
    baja: sem := 5;

Process Usuario-Alta [I:1..L]:: { 
    P(total);
    P(alta);
    //usa la BD
    V(total);
    V(alta);
}

Process Usuario-Baja [I:1..K]:: { 
    P(total);
    P(baja);
    //usa la BD
    V(total);
    V(baja);
}
```

### Respuesta

El problema de la solución es que no se debería hacer ```P(total)``` antes que hacer ```P(alta)``` o ```P(baja)``` ya que esto puede bloquear la ejecución de otros procesos que necesiten usar la BD y que puedan hacerlo según las restricciones. Por ejemplo, supongamos que existen 5 procesos de prioridad alta y 5 procesos de prioridad baja, si se llegaran a ejecutar los 5 procesos de prioridad alta antes que los 5 de prioridad baja, se bloquearía la ejecución de los procesos de prioridad baja, ya que el 5to de prioridad alta disminuye con ```P(total)``` el valor de ```total``` cosa que estaría mal ya que según las restricciones no puede haber más de 4 usuarios de prioridad alta al mismo tiempo. Por lo tanto, la solución no es la más adecuada.

## Ejercicio 5

En una empresa de logística de paquetes existe una sala de contenedores donde se preparan las entregas. Cada contenedor puede almacenar un paquete y la sala cuenta con capacidad para N contenedores. Resuelva considerando las siguientes situaciones:

- **a)** La empresa cuenta con 2 empleados: un empleado Preparador que se ocupa de preparar los paquetes y dejarlos en los contenedores; un empelado Entregador que se ocupa de tomar los paquetes de los contenedores y realizar la entregas. Tanto el Preparador como el Entregador trabajan de a un paquete por vez.
- **b)** Modifique la solución a) para el caso en que haya P empleados Preparadores.
- **c)** Modifique la solución a) para el caso en que haya E empleados Entregadores.
- **d)** Modifique la solución a) para el caso en que haya P empleados Preparadores y E empleadores Entregadores.

### Respuestas

**a)**

```c
ColaPaquetes contenedores[N];
int posicionOcupada = 0; int posicionLibre = 0;
sem lugaresLibres = N; sem lugaresOcupados = 0;

Process Preparador {
    while (true) {
        Paquete paquete;
        // preparar paquete
        P(lugaresLibres);
        contenedores[posicionLibre] = paquete;
        posicionLibre = (posicionLibre + 1) MOD N;
        V(lugaresOcupados);
    }
}

Process Entregador {
    while (true) {
        Paquete paquete;
        P(lugaresOcupados);
        paquete = contenedores[posicionOcupada];
        posicionOcupada = (posicionOcupada + 1) MOD N;
        V(lugaresLibres);
        // entregar paquete
    }
}
```

**b)**

```c
ColaPaquetes contenedores[N];
int posicionOcupada = 0; int posicionLibre = 0;
sem lugaresLibres = N; sem lugaresOcupados = 0; sem accesoPreparador = 1;

Process Preparador[id: 0 ... P-1] {
    while (true) {
        Paquete paquete;
        // preparar paquete
        P(lugaresLibres);
        P(accesoPreparador);
        contenedores[posicionLibre] = paquete;
        posicionLibre = (posicionLibre + 1) MOD N;
        V(accesoPreparador);
        V(lugaresOcupados);
    }
}

Process Entregador {
    while (true) {
        Paquete paquete;
        P(lugaresOcupados);
        paquete = contenedores[posicionOcupada];
        posicionOcupada = (posicionOcupada + 1) MOD N;
        V(lugaresLibres);
        // entregar paquete
    }
}
```

**c)**

```c
ColaPaquetes contenedores[N];
int posicionOcupada = 0; int posicionLibre = 0;
sem lugaresLibres = N; sem lugaresOcupados = 0; sem accesoEntregador = 1;

Process Preparador {
    while (true) {
        Paquete paquete;
        // preparar paquete
        P(lugaresLibres);
        contenedores[posicionLibre] = paquete;
        posicionLibre = (posicionLibre + 1) MOD N;
        V(lugaresOcupados);
    }
}

Process Entregador[id: 0 ... E-1] {
    while (true) {
        Paquete paquete;
        P(lugaresOcupados);
        P(accesoEntregador);
        paquete = contenedores[posicionOcupada];
        posicionOcupada = (posicionOcupada + 1) MOD N;
        V(accesoEntregador);
        V(lugaresLibres);
        // entregar paquete
    }
}
```

**d)**

```c
ColaPaquetes contenedores[N];
int posicionOcupada = 0; int posicionLibre = 0;
sem lugaresLibres = N; sem lugaresOcupados = 0; sem accesoPreparador = 1; sem accesoEntregador = 1;

Process Preparador[id: 0 ... P-1] {
    while (true) {
        Paquete paquete;
        // preparar paquete
        P(lugaresLibres);
        P(accesoPreparador);
        contenedores[posicionLibre] = paquete;
        posicionLibre = (posicionLibre + 1) MOD N;
        V(accesoPreparador);
        V(lugaresOcupados);
    }
}

Process Entregador[id: 0 ... E-1] {
    while (true) {
        Paquete paquete;
        P(lugaresOcupados);
        P(accesoEntregador);
        paquete = contenedores[posicionOcupada];
        posicionOcupada = (posicionOcupada + 1) MOD N;
        V(accesoEntregador);
        V(lugaresLibres);
        // entregar paquete
    }
}
```

## Ejercicio 6

Existen N personas que deben imprimir un trabajo cada una. Resolver cada ítem usando semáforos:

- **a)** Implemente una solución suponiendo que existe una única impresora compartida por todas las personas, y las mismas la deben usar de a una persona a la vez, sin importar el orden. Existe una función Imprimir(documento) llamada por la persona que simula el uso de la impresora. Sólo se deben usar los procesos que representan a las Personas.
- **b)** Modifique la solución de (a) para el caso en que se deba respetar el orden de llegada.
- **c)** Modifique la solución de (a) para el caso en que se deba respetar estrictamente el orden dado por el identificador del proceso (la persona X no puede usar la impresora hasta que no haya terminado de usarla la persona X-1).
- **d)** Modifique la solución de (b) para el caso en que además hay un proceso Coordinador que le indica a cada persona que es su turno de usar la impresora.
- **e)** Modificar la solución (d) para el caso en que sean 5 impresoras. El coordinador le indica a la persona cuando puede usar una impresora, y cual debe usar.

### Respuestas

**a)**

```c
sem impresoraLibre = 1;

Process Persona[id: 0 ... N-1] {
    Documento documento;
    P(impresoraLibre);
    Imprimir(documento);
    V(impresoraLibre);
}
```

**b)**

```c
ColaOrdenDeLlegada cola[N];
bool libre = true;
sem mutex = 1; sem espera[N] = ([N] 0);

Process Persona[id: 0 ... N-1] {
    int siguiente;
    Documento documento;
    P(mutex);
    if (libre) {
        libre = false;
        V(mutex);
    } else {
        cola.push(id);
        V(mutex);
        P(espera[id]);
    }
    Imprimir(documento);
    P(mutex);
    if (cola.empty()) {
        libre = true;
    } else {
        sig = cola.pop();
        V(espera[sig]);
    }
    V(mutex);
}
```

**c)**

```c
sem espera[N] = ([N] 0);
int sig = 0;

Process Persona[id: 0 ... N-1] {
    Documento documento;
    if (id != sig) {
        P(espera[id]);
    }
    Imprimir(documento);
    sig++;
    V(espera[sig]);
}
```

**d)**

```c
ColaOrdenDeLlegada cola[N];
sem accesoCola = 1; sem listo = 0; sem pedidosImpresion = 0; sem espera[N] = ([N] 0);

Process Persona[id: 0 ... N-1] {
    Documento documento;
    P(accesoCola);
    cola.push(id);
    V(accesoCola);
    V(pedidosImpresion); // aviso que hay un pedido de impresión
    P(espera[id]); // espero aviso de que se puede usar la impresora
    Imprimir(documento);
    V(listo); // aviso que termine uso de la impresora
}

Process Coordinador {
    int sig;
    for (int i = 0; i < N; i++) {
        P(pedidosImpresion); // espero pedido de impresión
        P(accesoCola);
        sig = cola.pop();
        V(accesoCola);
        V(espera[sig]); // habilito el uso de la impresora
        P(listo); // espero aviso de que termino uso de la impresora
    }
}
```

**e)**

```c
ColaOrdenDeLlegada cola[N];
ColaImpresoras impresorasLibres[5] = (0, 1, 2, 3, 4);
int impresoraPorPersona[N] = ([N] -1);
sem accesoColaPedidos = 1; sem accesoColaImpresoras = 1; sem pedidosImpresion = 0; sem catidadImpresoras = 5; sem espera[N] = ([N] 0);

Process Persona[id: 0 ... N-1] {
    Documento documento;
    P(accesoColaPedidos);
    cola.push(id);
    V(accesoColaPedidos);
    V(pedidosImpresion); // aviso que hay un pedido de impresión
    P(espera[id]); // espero aviso de que se puede usar la impresora
    Imprimir(documento, impresoraPorPersona[id]); // imprime en la impresora asignada
    P(accesoColaImpresoras);
    impresorasLibres.push(impresoraPorPersona[id]);
    V(accesoColaImpresoras); // repongo la impresora usada
    V(catidadImpresoras); // aviso que hay una impresora libre
}

Process Coordinador {
    int sig; int impresora;
    for (int i = 0; i < N; i++) {
        P(pedidosImpresion); // espero pedido de impresión
        P(accesoColaPedidos);
        sig = cola.pop();
        V(accesoColaPedidos);
        P(cantidadImpresoras); // espero que haya impresoras libres
        P(accesoColaImpresoras);
        impresora = impresoras.pop();
        V(accesoColaImpresoras);
        impresoraPorPersona[sig] = impresora; // asigno impresora al siguiente
        V(espera[sig]); // habilito el uso de la impresora
    }
}
```

## Ejercicio 7

Suponga que se tiene un curso con 50 alumnos. Cada alumno debe realizar una tarea y existen 10 enunciados posibles. Una vez que todos los alumnos eligieron su tarea,comienzan a realizarla. Cada vez que un alumno termina su tarea, le avisa al profesor y se queda esperando el puntaje del grupo (depende de todos aquellos que comparten el mismo enunciado). Cuando un grupo terminó, el profesor les otorga un puntaje que representa el orden en que se terminó esa tarea de las 10 posibles.

**Nota:** Para elegir la tarea suponga que existe una función ```elegir()``` que le asigna una tarea a un alumno (esta función asignará 10 tareas diferentes entre 50 alumnos, es decir, que 5 alumnos tendrán la tarea 1, otros 5 la tarea 2 y así sucesivamente para las 10 tareas).

### Respuesta

```c
ColaTareas finalizados;
int alumnosConEnunciado = 0; int puntajePorTarea[10] = ([10] 0);
sem mutex = 1; sem barreraAlumnos = 0; sem avisarProfesor = 0; sem obtenerPuntaje[10] = ([10] 0);

Process Alumno[id: 0 ... 49] {
    int tarea; int nota;
    tarea = elegir()
    P(mutex);
    alumnosConEnunciado++;
    if (alumnosConEnunciado == 50) {  // si soy el último despierto a todos
        for (int i = 0; i < 50; i++) {
            V(barreraAlumnos);  // "activo" barrera
        }
    }
    V(mutex);
    P(barreraAlumnos);  // "saco" barrera
    // realizar tarea
    P(mutex);
    finallizados.push(tarea);  // guardo tarea cuando termino
    V(mutex);
    V(avisarProfesor);  // aviso a profesor que termine
    P(obtenerPuntaje[tarea]);  // espero obtener puntaje
    nota = puntajePorTarea[tarea];  // asigno la nota de mi grupo
}

Process Profesor {
    int puntajeADar = 10; int alumnosPorTarea[10] = ([10] 0); int tareaActual;
    for (int i = 0; i < 50; i++) {
        P(avisarProfesor);  // espero aviso de que termino un alumno
        P(mutex);
        tareaActual = finalizados.pop();  // saco tarea a analizar
        V(mutex);
        alumnosPorTarea[tareaActual]++;  // sumo un alumno que realizó esa tarea
        if (alumnosPorTarea[tareaActual] == 5) {  // si todos los alumnos terminaron esa tarea
            puntajePorTarea[tareaActual] = puntajeADar;  // le doy puntaje a ese grupo
            puntajeADar--;  // le resto puntaje al siguiente grupo
            for (int j = 0; j < 5; j++) {
                V(obtenerPuntaje[tareaActual]);  // aviso a los alumnos que terminaron esa tarea
            }
        }
    }
}
```

## Ejercicio 8

Una fábrica de piezas metálicas debe producir T piezas por día. Para eso, cuenta con E empleados que se ocupan de producir las piezas de a una por vez. La fábrica empieza a producir una vez que todos los empleados llegaron. Mientras haya piezas por fabricar, los empleados tomarán una y la realizarán. Cada empleado puede tardar distinto tiempo en fabricar una pieza. Al finalizar el día, se debe conocer cual es el empleado que más piezas fabricó.

- **a)** Implemente una solución asumiendo que T > E.
- **b)** Implemente una solución que contemple cualquier valor de T y E.

### Respuesta

**b)** Hago directamente el código para tratar cuelquier valor de T y E.

```c
ColaPiezas piezas;
int empleadosEnFabrica = 0; int piezasTrabajadasPorEmpleado[E] = ([E], 0); int empleadoReconocido = -1;
sem barreraEmpleados = 0; sem mutex = 1; sem avisarEmpresa = 0; sem recibioReconocimiento = 0;

Process Empleado[id: 0 ... E-1] {
    Pieza pieza;
    P(mutex);
    empleadosEnFabrica ++;  // incremento número de empleados en fábrica
    if (empleadosEnFabrica == E) {  // si soy el último empleado "activo" la barrera
        for (int i = 0; i < E; i++) {
            V(barreraEmpleados);  // "activo" barrera
        }
    }
    V(mutex);
    P(barreraEmpleados);  // "saco" barrera
    P(mutex);
    while (!piezas.isEmpty()) {
        pieza = piezas.pop();  // saco pieza a trabajar
        V(mutex);
        // trabajo pieza
        piezasTrabajadasPorEmpleado[id]++;  // sumo pieza trabajada
        P(mutex);
    }
    V(mutex);
    P(mutex);
    empleadosEnFabrica--;  // decremento número de empleados en fábrica
    if (empleadosEnFabrica == 0) {  // si soy el último empleado "activo" la barrera
        for (int i = 0; i < E; i++) {
            V(barreraEmpleados);  // "activo" barrera
        }
        V(avisarEmpresa);  // aviso a empresa que terminaron todos
    }
    V(mutex);
    P(barreraEmpleados);  // "saco" barrera
    P(recibioReconocimiento);  // espero reconocimiento de empresa
    if (empleadoReconocido == id) {  // si soy el empleado que más piezas trabajó
        print("Soy el más capo");
    }
}

Process Empresa {
    int piezasMaximas = -1;
    P(avisarEmpresa);  // espero aviso de que terminaron todos
    for (int i = 0; i < E; i++) {
        if (piezasTrabajadasPorEmpleado[i] > piezasMaximas) {  // si el empleado trabajó más piezas que el anterior
            piezasMaximas = piezasTrabajadasPorEmpleado[i];  // actualizo piezas máximas
            empleadoReconocido = i;  // actualizo empleado reconocido
        }
    }
    for (int i = 0; i < E; i++) {
        V(recibioReconocimiento);  // aviso a empleados que ya hay uno reconocido
    }
}
```

## Ejercicio 9

Resolver el funcionamiento en una fábrica de ventanas con 7 empleados (4 carpinteros, 1 vidriero y 2 armadores) que trabajan de la siguiente manera:
- Los carpinteros continuamente hacen marcos (cada marco es armando por un único carpintero) y los deja en un depósito con capacidad de almacenar 30 marcos.
- El vidriero continuamente hace vidrios y los deja en otro depósito con capacidad para 50 vidrios.
- Los armadores continuamente toman un marco y un vidrio (en ese orden) de los depósitos correspondientes y arman la ventana (cada ventana es armada por un único armador).

### Respuesta

```c
ContenedorMarcos depositoDeMarcos[30]; 
ContenedorVidrios depositoDeVidrios[50]; 
int posicionOcupadaMarcos = 0; int posicionLibreMarcos = 0; int posicionOcupadaVidrios = 0; int posicionLibreVidrios = 0;
sem lugaresLibresMarcos = 30; sem lugaresOcupadosMarcos = 0; sem accesoDepositoMarcos = 1; sem lugaresLibresVidrios = 50; sem lugaresOcupadosVidrios = 0; sem accesoArmadorMarcos = 1; sem accesoArmadorVidrio = 1;

Process Carpintero[id: 0 ... 3] {
    Marco marco;
    while (true) {
        // preparar marco
        P(lugaresLibresMarcos);
        P(accesoDepositoMarcos);
        depositoDeMarcos[posicionLibreMarcos] = marco;  // deposito marco
        posicionLibreMarcos = (posicionLibreMarcos + 1) MOD 30;  // modifico posición libre para el siguiente marco
        V(accesoDepositoMarcos);
        V(lugaresOcupadosMarcos);
    }
}

Process Vidriero {
    Vidrio vidrio;
    while (true) {
        // preparar vidrio
        P(lugaresLibresVidrios);
        depositoDeVidrios[posicionLibreVidrios] = vidrio;  // deposito vidrio
        posicionLibreVidrios = (posicionLibreVidrios + 1) MOD 50;  // modifico posición libre para el siguiente vidrio
        V(lugaresOcupadosVidrios);
    }
}

Process Armador[id: 0 ... 1] {
    Marco marco;
    Vidrio vidrio;
    Ventana ventana;
    while (true) {
        P(lugaresOcupadosMarcos);
        P(accesoArmadorMarcos);
        marco = depositoDeMarcos[posicionOcupadaMarcos];  // saco marco
        posicionOcupadaMarcos = (posicionOcupadaMarcos + 1) MOD 30;  // modifico posición ocupada para el siguiente marco
        V(accesoArmadorMarcos);
        V(lugaresLibresMarcos);
        P(lugaresOcupadosVidrios);
        P(accesoArmadorVidrio);
        vidrio = depositoDeVidrios[posicionOcupadaVidrios];  // saco vidrio
        posicionOcupadaVidrios = (posicionOcupadaVidrios + 1) MOD 50;  // modifico posición ocupada para el siguiente vidrio
        V(accesoArmadorVidrio);
        V(lugaresLibresVidrios);
        ventana = armarVentana(marco, vidrio);  // armo ventana
    }
}
```

## Ejercicio 10

A una cerealera van T camiones a descargarse trigo y M camiones a descargar maíz. Sólo hay lugar para que 7 camiones a la vez descarguen, pero no pueden ser más de 5 del mismo tipo de cereal.

- **a)** Implemente una solución que use un proceso extra que actúe como coordinador entre los camiones. El coordinador debe retirarse cuando todos los camiones han descargado.
- **b)** Implemente una solución que no use procesos adicionales (sólo camiones).

### Respuestas

**a)**

```c
int cantidadCamionesTrigo =0; int cantidadCamionesMaiz = 0; int camionesQueTerminaron = 0;
sem mutexAccesoTrigo = 1; sem mutexAccesoMaiz =1; sem maximoTotalCamiones = 7; sem pasaTrigo[T] = ([T], 0); sem pasaMaiz[M] = ([M],0); sem mutexTerminaron = 1; ; sem hayCamiones = 0; sem mutexCamionesTrigo = 1; sem mutexCamionesMaiz = 1;
colaTrigo camionesTrigo; colaMaiz camionesMaiz; 

Process CamionTrigo[id: 0 ... T - 1] {
    P(mutexCamionesTrigo);
    camionesTrigo.push(id);  // agrego camión a cola
    V(mutexCamionesTrigo);
    V(hayCamiones);  // aviso que hay camiones esperando
    P(pasaTrigo[id]);  // espero a que me den paso
    //Descarga
    P(mutexAccesoTrigo);
    cantidadCamionesTrigo--;  // disminuyo la cantidad de camiones trigo
    V(mutexAccesoTrigo);
    V(maximoTotalCamiones);
    P(mutexTerminaron);
    camionesQueTerminaron++;  // aumento la cantidad de camiones que terminaron
    V(mutexTerminaron);
}

Process CamionMaiz[id: O ... M - 1] {
    P(mutexCamionesMaiz);
    camionesMaiz.push(id);  // agrego camión a cola
    V(mutexCamionesMaiz);
    V(hayCamiones);  // aviso que hay camiones esperando
    P(pasaMaiz[id]);  // espero a que me den paso
    //Descarga
    P(mutexAccesoMaiz);
    cantidadCamionesTrigo--;  // disminuyo la cantidad de camiones maiz
    V(mutexAccesoMaiz);
    V(maximoTotalCamiones);
    P(mutexTerminaron);
    camionesQueTerminaron++;  // aumento la cantidad de camiones que terminaron
    V(mutexTerminaron);
}

Process Coordinador {
    P(mutexTerminaron); 
    while(camionesQueTerminaron < (M + T)){ // mientras no hayan terminado todos los camiones
        V(mutexTerminaron)
        P(hayCamiones); // espero a que haya camiones esperando
        P(mutexAccesoTrigo);  
        P(mutexCamionesTrigo);
        P(maximoTotalCamiones);
        if (cantidadCamionesTrigo <= 5 && !camionesTrigoIsEmpty()){  // si hay lugar para más camiones trigo y la cola de los de trigo no está vacía
            cantidadCamionesTrigo++;
            V(mutexAccesoTrigo);
            id = camionesTrigo.pop();
            V(mutexCamionesTrigo);
            V(pasaTrigo[id]);  // habilito paso al camión de trigo
        }
        V(mutexAccesoTrigo); 
        V(mutexCamionesTrigo);
        P(mutexAccesoMaiz);  
        P(mutexCamionesMaiz);
        if (cantidadCamionesMaiz <= 5 && !camionesMaizIsEmpty()){  // si hay lugar para más camiones maíz y la cola de los de trigo no está vacía
            cantidadCamionesMaiz++;
            V(mutexAccesoMaiz);
            id = camionesMaiz.pop();
            V(mutexCamionesMaiz);
            V(pasaMaiz[id]);  // habilito paso al camión de maíz
        }
        V(mutexAccesoTrigo); 
        V(mutexCamionesMaiz);
        P(mutexTerminaron);
    }
}
```

**b)**
```c
sem camionesTotales = 7; sem maximosTrigo = 5; sem maximosMaiz = 5;

Process CamionTrigo[id: 0 ... T - 1] {
    P(maximosTrigo);
    P(camionesTotales);
    // descargar trigo
    V(camionesTotales);
    V(maximosTrigo);
}

Process CamionMaiz[id: 0 ... M - 1] {
    P(maximosMaiz);
    P(camionesTotales);
    // descargar maíz
    V(camionesTotales);
    V(maximosMaiz);
}
```

## Ejercicio 11

En un vacunatorio hay un empleado de salud para vacunar a 50 personas. El empleado de salud atiende a las personas de acuerdo con el orden de llegada y de a 5 personas a la vez. Es decir, que cuando está libre debe esperar a que haya al menos 5 personas esperando, luego vacuna a las 5 primeras personas, y al terminar las deja ir para esperar por otras 5. Cuando ha atendido a las 50 personas el empleado de salud se retira. 
**Nota:** todos los procesos deben terminar su ejecución; suponga que el empleado tienen una función VacunarPersona() que simula que el empleado está vacunando a UNA persona.

### Respuesta

```c
ColaPersonas personasAVacunar;
int cantidadPersonas = 0;
sem mutex = 1; sem esperaPersonaParaIrse[50] = ([50], 0); sem avisarEmpleado = 0;

Process EmpleadoSalud {
    ColaPersonas personasVacunadas;
    int personaActual;
    for (int i = 0; i < 10; i++) {  // si atiende de a 5 personas a la vez se necesitan 10 iteraciones
        P(avisarEmpleado);  // espero a que haya 5 personas para vacunar
        for (int j = 0; j < 5; j++) {
            P(mutex);
            personaActual = personasAVacunar.pop();
            V(mutex);
            VacunarPersona(personaActual);
            personasVacunadas.push(personaActual);
        }
        for (int k=0; k < 5; k++) {
            V(esperaPersonaParaIrse[personasVacunadas.pop()]);  // aviso a las personas vacunadas que se pueden ir
        }
    }
}

Process Persona[id: 0 ... 49] {
    P(mutex);
    personasAVacunar.push(id);  // agrego a la cola de personas a vacunar
    cantidadPersonas++;
    if (cantidadPersonas == 5) {  // si hay 5 personas en la cola de personas a vacunar entonces aviso al empleado
        cantidadPersonas = 0;
        V(avisarEmpleado);
    }
    V(mutex);
    P(esperaPersonaParaIrse[id]);  // espero a que el empleado me avise que puedo irme
}
```

## Ejercicio 12

Simular la atención en una Terminal de Micros que posee 3 puestos para hisopar a 150 pasajeros. En cada puesto hay una Enfermera que atiende a los pasajeros de acuerdo con el orden de llegada al mismo. Cuando llega un pasajero se dirige al Recepcionista, quien le indica qué puesto es el que tiene menos gente esperando. Luego se dirige al puesto y espera a que la enfermera correspondiente lo llame para hisoparlo. Finalmente, se retira.

- **a)** Implemente una solución considerando los procesos Pasajeros, Enfermera y Recepcionista.
- **b)** Modifique la solución anterior para que sólo haya procesos Pasajeros y Enfermera, siendo los pasajeros quienes determinan por su cuenta qué puesto tiene menos personas esperando.

**Nota:** suponga que existe una función Hisopar() que simula la atención del pasajero por parte de la enfermera correspondiente

### Respuestas

**a)** Asumo que hay un método ```PuestoConMenosPasajeros()``` que devuelve el numero del puesto con menos pasajeros.

```c
ColaPasajeros general; ColaPasajeros puestos[3];
sem mutexGeneral = 1; sem accesoPuestos[3] = ([3], 1); sem esperaGeneral = 0; sem esperaPuestos[3] = ([3], 0); sem esperaSalir[150] = ([150], 0);

Process Pasajero[id: 0 ... 149] {
    P(mutexGeneral);
    general.push(id);  // me encolo para que me atienda recepción
    V(mutexGeneral);
    V(esperaGeneral);  // aviso a recepción que hay un pasajero esperando
    P(esperaSalir[id]);  // espero a que me avisen que puedo irme
}

Process Recepcionista {
    int pasajeroActual; int puestoDesignado;
    for (int i = 0; i < 150; i++) {
        P(esperaGeneral);  // espero a que haya un pasajero esperando
        P(mutexGeneral);
        pasajeroActual = general.pop();
        V(mutexGeneral);
        puestoDesignado = PuestoConMenosPasajeros();  // obtengo el puesto con menos pasajeros
        P(accesoPuestos[puestoDesignado]);
        puestos[puestoDesignado].push(pasajeroActual);  // agrego a la cola de pasajeros del puesto designado
        V(accesoPuestos[puestoDesignado]);
        V(esperaPuestos[puestoDesignado]);  // aviso que hay un pasajero esperando
    }
    for i = 0; i < 3; i++) {
        V(esperaPuestos[i]);  // aviso a las enfermeras que ya no hay más pasajeros
    }
}

Process Enfermera[id: 0 ... 2] {
    int pasajeroActual;
    P(esperaPuestos[id]);  // espero a que haya un pasajero esperando en mi puesto
    P(accesoPuestos[id]);
    while (!puestos[id].isEmpty()) {
        pasajeroActual = puestos[id].pop();
        V(accesoPuestos[id]);
        Hisopar(pasajeroActual);  // hisopo al pasajero
        V(esperaSalir[pasajeroActual]);  // aviso a pasajero que puede irse
        P(esperaPuestos[id]);  // espero a que haya un pasajero esperando en mi puesto
        P(accesoPuestos[id]);
    }
    V(accesoPuestos[id]);
}
```

**b)**

```c
ColaaPasajeros puestos[3];
sem chequearPuesto = 1; sem accesoPuestos[3] = ([3], 1); sem esperaPuestos[3] = ([3], 0); sem esperaSalir[150] = ([150], 0);
int personasRepartidas = 0;

Process Pasajero[id: 0 ... 149] {
    int puestoDesignado;
    P(chequearPuesto);
    puestoDesignado = PuestoConMenosPasajeros();  // obtengo el puesto con menos pasajeros
    P(accesoPuestos[puestoDesignado]);
    puestos[puestoDesignado].push(id);  // me agrego a la cola de pasajeros del puesto designado
    V(accesoPuestos[puestoDesignado]);
    V(esperaPuestos[puestoDesignado]);  // aviso que hay un pasajero esperando
    personasRepartidas++;  // aumento la cantidad de personas repartidas
    if (personasRepartidas == 150) {
        for i = 0; i < 3; i++) {
            V(esperaPuestos[i]);  // aviso a las enfermeras que ya no hay más pasajeros
        }
    }
    V(chequearPuesto);
    P(esperaSalir[id]);  // espero a que me avisen que puedo irme
}

Process Enfermera[id: 0 ... 2] {
    int pasajeroActual;
    P(esperaPuestos[id]);  // espero a que haya un pasajero esperando en mi puesto
    P(accesoPuestos[id]);
    while (!puestos[id].isEmpty()) {
        pasajeroActual = puestos[id].pop();
        V(accesoPuestos[id]);
        Hisopar(pasajeroActual);  // hisopo al pasajero
        V(esperaSalir[pasajeroActual]);  // aviso a pasajero que puede irse
        P(esperaPuestos[id]);  // espero a que haya un pasajero esperando en mi puesto
        P(accesoPuestos[id]);
    }
    V(accesoPuestos[id]);
}
```