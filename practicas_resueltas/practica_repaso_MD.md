# Práctica de Repaso - Memoria Distribuida

# Pasaje de Mensajes

## Ejercicio 1

En una oficina existen 100 empleados que envían documentos para imprimir en 5 impresoras compartidas. Los pedidos de impresión son procesados por orden de llegada y se asignan a la primera impresora que se encuentre libre:
- **a)** Implemente un programa que permita resolver el problema anterior usando PMA.
- **b)** Resuelva el mismo problema anterior pero ahora usando PMS.

### Respuestas

**a)**

```c
chan pedidoDeImpresion[5](Documento);
chan hayPeticion(int, Documento);
chan recibirCopia[100](Documento);
chan avisoImpresoraLibre(int);

Process Empleado [id: 1...100] {
    Documento documento;
    Documento copia;
    send hayPeticion(id, documento);
    receive recibirCopia[id](copia);
}

Process Coordinador {
    Documento documento;
    int idImpresora;
    int idEmpleado;
    while (true) {
        receive avisoImpresoraLibre(idImpresora);
        receive hayPeticion(idEmpleado, documento);
        send pedidoDeImpresion[idImpresora](idEmpleado, documento);
    }
}

Process Impresora [id: 1...5] {
    Documento documento;
    Documento copia;
    int idEmpleado;
    while (true) {
        send avisoImpresoraLibre(id);
        receive pedidoDeImpresion[id](idEmpleado, documento);
        copia = Imprimir(documento);
        send recibirCopia[idEmpleado](copia);
    }
}
```

**b)**

```c
Process Empleado [id: 1...100] {
    Documento original;
    Documento copia;
    Buffer!enviarDocumento(id, original);
    Impresora[*]?recibirCopia(copia);
}

Process Buffer {
    Buffer bufferPeticiones;
    Documento original;
    int idImpresora;
    int idEmpleado;
    do Empleado[*]?enviarDocumento(idEmpleado, original) →
        bufferPeticiones.push(idEmpleado, original);
    [] !bufferPeticiones.isEmpty(); Impresora[*]?avisoDisponible(idImpresora) →
        Impresora[idImpresora]!recibirPedido(bufferPeticiones.pop());
    od
}

Process Impresora [id: 1...5] {
    Documento original;
    Documento copia;
    int idEmpleado;
    while (true) {
        Buffer!avisoDisponible(id);
        Buffer?recibirPedido(idEmpleado, original);
        copia = Imprimir(original);
        Empleado[idEmpleado]!recibirCopia(copia);
    }
}
```

## Ejercicio 2

Resolver el siguiente problema con PMS. En la estación de trenes hay una terminal de SUBE que debe ser usada por P personas de acuerdo con el orden de llegada. Cuando la persona accede a la terminal, la usa y luego se retira para dejar al siguiente. **Nota:** cada Persona usa sólo una vez la terminal.

### Respuesta

```c
Process Persona [id: 1...P] {
    Estacion estacion;
    Buffer!solicitarEstacion(id);
    Buffer?habiltarEstacion(estacion);
    UsarEstacion(estacion);
    Buffer!liberarEstacion(estacion);
}

Process Buffer {
    Estacion estacion;
    Buffer bufferSolicitudes;
    int idPersona;
    bool estacionLibre = true;
    do Persona[*]?solicitarEstacion(idPersona) →
        if (estacionLibre) {
            estacionLibre = false;
            Empleado[idPersona]!habilitarEstacion(estacion);
        } else {
            bufferSolicitudes.push(idPersona);
        }
    [] Persona[*]?liberarEstacion(estacion) →
        if (!bufferSolicitudes.isEmpty()) {
            Empleado[bufferSolicitudes.pop()]!habilitarEstacion(estacion);
        } else {
            estacionLibre = true;
        }
    od
}
```

## Ejercicio 3

Resolver el siguiente problema con PMA. En un negocio de cobros digitales hay P personas que deben pasar por la única caja de cobros para realizar el pago de sus boletas. Las personas son atendidas de acuerdo con el orden de llegada, teniendo prioridad aquellos que deben pagar menos de 5 boletas de los que pagan más. Adicionalmente, las personas embarazadas tienen prioridad sobre los dos casos anteriores. Las personas entregan sus boletas al cajero y el dinero de pago; el cajero les devuelve el vuelto y los recibos de pago.

### Respuesta

```c
chan solicitarCajeroEmbarazada(int, Boleta, double);
chan solicitarCajeroMenosBoletas(int, Boleta, double);
chan solicitarCajeroComun(int, Boleta, double);
chan recibirRecibos[P](double, Recibo);
chan hayPeticion();

Process Persona [id: 1...P] {
    bool embarazada = ...;
    Boleta boletas[...] = ...;
    Recibo recibos[...];
    double dinero = ...;
    double vuelto;
    if (embarazada) {
        send solicitarCajeroEmbarazada(id, boletas, dinero);
    } elif (recibos.size() < 5) {
        send solicitarCajeroMenosBoletas(id, boletas, dinero);
    } else {
        send solicitarCajeroComun(id, boletas, dinero);
    }
    send hayPeticion;
    receive recibirRecibos[id](vuelto, recibos);
}

Process Cajero {
    int idPersona;
    Boleta boletas[...];
    Recibo recibos[...];
    double dinero;
    double vuelto;
    for [int i = 0; i < P; i++] {
        receive hayPeticion;
        if (!empty(solicitarCajeroEmbarazada)) {
            receive solicitarCajeroEmbarazada(idPersona, boletas, dinero);
        } elif (!empty(solicitarCajeroMenosBoletas)) {
            receive solicitarCajeroMenosBoletas(idPersona, boletas, dinero);
        } else {
            receive solicitarCajeroComun(idPersona, boletas, dinero);
        }
        vuelto, recibos = Atender(boletas, dinero);
        send recibirRecibos[idPersona](vuelto, recibos);
    }
}
```

# ADA

## Ejercicio 1

Resolver el siguiente problema. La página web del Banco Central exhibe las diferentes cotizaciones del dólar oficial de 20 bancos del país, tanto para la compra como para la venta. Existe una tarea programada que se ocupa de actualizar la página en forma periódica y para ello consulta la cotización de cada uno de los 20 bancos. Cada banco dispone de una API, cuya única función es procesar las solicitudes de aplicaciones externas. La tarea programada consulta de a una API por vez, esperando a lo sumo 5 segundos por su respuesta. Si pasado ese tiempo no respondió, entonces se mostrará vacía la información de ese banco.

### Respuesta

```ADA
PROCEDURE Banco IS
    TASK Consulta;
    TASK BODY Consulta IS
        arrValorCompra: array (1..20) of String;
        arrValorVenta: array (1..20) of String;
        periodicidadDeConsulta: int;
        valorDolarCompra: String;
        valorDolarVenta: String;
    BEGIN
        periodicidadDeConsulta = ...;
        LOOP
            FOR i IN 1..20 LOOP
                SELECT
                    Banco(i).ConsultarValoresDolar(valorDolarCompra, valorDolarVenta);
                    arrValorCompra(i) = valorDolarCompra;
                    arrValorVenta(i) = valorDolarVenta;
                OR DELAY 5
                    arrValorCompra(i) = "";
                    arrValorVenta(i) = "";
                END SELECT;
            END LOOP;
            ActualizarPagina (arrValorCompra, arrValorVenta);
            DELAY periodicidadDeConsulta;
        END LOOP; 
    END Consulta;

    TASK TYPE Banco IS
        ENTRY ConsultarValoresDolar (valorCompra: OUT String; valorVenta: OUT String);
    END Banco;
    arrBancos: array (1..20) of Banco;
    TASK BODY Banco IS
        api: API;
        valorDolarCompra: String;
        valorDolarVenta: String;
    BEGIN
        LOOP
            valorDolarCompra = "$...";
            valorDolarVenta = "$...";
            ACCEPT ConsultarValoresDolar (valorCompra: OUT String; valorVenta: OUT String) DO
                valorCompra = valorDolarCompra;
                valorVenta = valorDolarVenta;
            END ConsultarValoresDolar;
        END LOOP;
    END Banco;

BEGIN
    null;
END Banco;
```

## Ejercicio 2

Resolver el siguiente problema. En un negocio de cobros digitales hay P personas que deben pasar por la única caja de cobros para realizar el pago de sus boletas. Las personas son atendidas de acuerdo con el orden de llegada, teniendo prioridad aquellos que deben pagar menos de 5 boletas de los que pagan más. Adicionalmente, las personas ancianas tienen prioridad sobre los dos casos anteriores. Las personas entregan sus boletas al cajero y el dinero de pago; el cajero les devuelve el vuelto y los recibos de pago.

### Respuesta

```ADA
PROCEDURE Negocio IS
    TASK Cajero IS
        ENTRY pagarParaAncianos(boletas: IN Boleta; dinero: IN double; vuelto: OUT double; recibos: OUT Recibo);
        ENTRY pagarParaMenosCincoBoletas(boletas: IN Boleta; dinero: IN double; vuelto: OUT double; recibos: OUT Recibo);
        ENTRY pagarComun(boletas: IN Boleta; dinero: IN double; vuelto: OUT double; recibos: OUT Recibo);
    END Cajero;
    TASK BODY Cajero IS
    BEGIN
        LOOP
            SELECT
                ACCEPT pagarParaAncianos(boletas: IN Boleta; dinero: IN double; vuelto: OUT double; recibos: OUT Recibo) DO
                    vuelto, recibos = RealizarPago(boletas, dinero);
                END pagarParaAncianos;
            OR
                WHEN (pagarParaAncianos'COUNT == 0) → ACCEPT pagarParaMenosCincoBoletas(boletas: IN Boleta; dinero: IN double; vuelto: OUT double; recibos: OUT Recibo) DO
                    vuelto, recibos = RealizarPago(boletas, dinero);
                END pagarParaMenosCincoBoletas;
            OR
                WHEN (pagarParaAncianos'COUNT == 0) AND (pagarParaMenosCincoBoletas'COUNT == 0) → ACCEPT pagarComun(boletas: IN Boleta; dinero: IN double; vuelto: OUT double; recibos: OUT Recibo) DO
                    vuelto, recibos = RealizarPago(boletas, dinero);
                END pagarComun;
            END SELECT;
        END LOOP;
    END Cajero;

    TASK TYPE Persona;
    arrPersonas: array (1..P) of Persona;
    TASK BODY Persona IS
        anciano: Boolean;
        boletas: Boleta;
        recibos: Recibo;
        dinero: double;
        vuelto: double;
    BEGIN
        anciano = ...;
        boletas = ...;
        dinero = ...;
        IF (anciano) THEN
            Cajero.pagarParaAncianos(boletas, dinero, vuelto, recibos);
        ELSE IF (boletas.size() < 5) THEN
            Cajero.pagarParaMenosCincoBoletas(boletas, dinero, vuelto, recibos);
        ELSE
            Cajero.pagarComun(boletas, dinero,vuelto,recibos);
        END IF;
    END Persona;

BEGIN
    null;
END Negocio;
```

## Ejercicio 3

Resolver el siguiente problema. La oficina central de una empresa de venta de indumentaria debe calcular cuántas veces fue vendido cada uno de los artículos de su catálogo. La empresa se compone de 100 sucursales y cada una de ellas maneja su propia base de datos de ventas. La oficina central cuenta con una herramienta que funciona de la siguiente manera: ante la consulta realizada para un artículo determinado, la herramienta envía el identificador del artículo a las sucursales, para que cada una calcule cuántas veces fue vendido en ella. Al final del procesamiento, la herramienta debe conocer cuántas veces fue vendido en total, considerando todas las sucursales. Cuando ha terminado de procesar un artículo comienza con el siguiente (suponga que la herramienta tiene una función generarArtículo() que retorna el siguiente ID a consultar). **Nota:** maximizar la concurrencia. Existe una función ObtenerVentas(ID) que retorna la cantidad de veces que fue vendido el artículo con identificador ID en la base de la sucursal que la llama.

### Respuesta

```ADA
PROCEDURE OficinaCentral IS
    TASK Herramienta IS
        ENTRY listoParaProcesar(id: OUT int);
        ENTRY recibirCantidadVendida(cantidadVendida: IN int);
        ENTRY terminoCiclo;
    END Herramienta;
    TASK BODY Herramienta IS
        totalProducto: int;
        idProducto: int;
    BEGIN
        LOOP
            totalProducto = 0;
            idProducto = generarArticulo();
            FOR i IN (1..200) LOOP
                SELECT
                    ACCEPT listoParaProcesar (id: OUT int) DO
                        id = idProducto;
                    END listoParaProcesar;
                OR
                    ACCEPT recibirCantidadVendida(cantidadVendida: INT int) DO
                        totalProducto = totalProducto + cantidadVendida;
                    END recibirCantidadVendida;
                END SELECT;
            END LOOP;
            PUTS ("El artículo " + idArticulo + " fue vendido: " + totalProducto + " veces.");
            FOR i IN (1..100) LOOP
                ACCEPT terminoCiclo;
            END LOOP;
        END LOOP;
    END Herramienta;

    TASK TYPE Sucursal;
    arrSucursales = array (1..100) of Sucursal;
    TASK BODY Sucursal IS
        db: Database;
        idArticulo: int;
    BEGIN
        LOOP
            Herramienta.listoParaProcesar (idArticulo);
            Herramienta.recibirCantidadVendida (db.ObtenerVentas(idArticulo));
            Herramienta.terminoCiclo;
        END LOOP;
    END Sucursal;

BEGIN
    null;
END OficinaCentral;
```