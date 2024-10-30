# Proyecto: OM y OC Tokens en Tron (TRC20)

Este proyecto implementa dos tokens en la blockchain de Tron: **OM** y **OC**. Ambos tokens tienen una funcionalidad específica y están diseñados para representar activos ecológicos y de sostenibilidad. Los contratos están escritos en Solidity y se basan en el estándar TRC20.

## Índice

1. [Descripción de los Tokens](#descripción-de-los-tokens)
2. [Propósito de los Tokens](#propósito-de-los-tokens)
3. [Contratos](#contratos)
4. [Especificaciones Técnicas](#especificaciones-técnicas)
5. [Instrucciones de Despliegue](#instrucciones-de-despliegue)
6. [Pruebas](#pruebas)

---

## Descripción de los Tokens

### ¿Qué es un Token?
Un token es una moneda virtual que representa un activo o una utilidad comercializable. Los tokens se almacenan en una billetera digital y permiten a los titulares usarlos para fines de inversión o como medio de intercambio en aplicaciones descentralizadas.

### Token OM
**OM Token** es una certificación digital de un metro cuadrado de bosque nativo. Al adquirir un token OM, el titular está ayudando a proteger y conservar un área específica de bosque para siempre.

### Token OC
**OC Token** representa una certificación de Bonos de Carbono. Los árboles del bosque absorben carbono de la atmósfera, y este token se emite como una certificación digital para reflejar la cantidad de carbono capturado por el área de bosque protegida.

## Propósito de los Tokens

- **OM Token (OM)**: Representa la propiedad de 1 m² de bosque nativo. Este token es **fungible** y puede ser intercambiado o transferido. Los titulares de OM tienen un derecho de propiedad simbólico sobre una porción del bosque.
- **OC Token (OC)**: Representa un **bono de carbono** generado por el bosque. Este token es otorgado como recompensa a los titulares de OM de forma mensual. Los OC son **inmutables** y no se pueden intercambiar o quemar.

| Token | Funcionalidad          | Descripción                             | Intercambiable | Actualizable |
|-------|-------------------------|-----------------------------------------|----------------|--------------|
| OM    | Propiedad de bosque    | 1 m² de bosque protegido               | Sí             | Sí           |
| OC    | Bono de Carbono        | Representa carbono absorbido            | No             | No           |

---

## Contratos

El proyecto contiene dos contratos principales escritos en Solidity.

### OCToken (OC Token)
Archivo: `OCToken.sol`

El contrato de OC es un token TRC20, con la capacidad de ser pausado y quemado. Representa los bonos de carbono y está diseñado para ser inmutable una vez emitido.

Funciones principales:
- **transfer**: Transfiere tokens OC entre direcciones, siempre que el contrato no esté pausado.
- **approve**: Permite a un usuario aprobar el gasto de una cantidad específica de OC por otra cuenta.
- **burn**: Permite a los titulares de tokens quemar OC de su balance, reduciendo así el total de tokens en circulación.

### OMToken (OM Token)
Archivo: `OMToken.sol`

Este contrato representa el token OM, que certifica la propiedad simbólica de 1 m² de bosque. A diferencia de OC, este token puede ser intercambiado entre usuarios y actualizado en caso de cambios en la gestión del bosque.

Funciones principales:
- **transfer**: Transfiere tokens OM entre usuarios.
- **approve**: Permite aprobar a una cuenta para gastar tokens en nombre del propietario.
- **increaseAllowance / decreaseAllowance**: Aumenta o reduce la cantidad que un usuario puede gastar en nombre de otro.
- **balanceOf**: Consulta el balance de un usuario.

---

## Especificaciones Técnicas

- **Decimales**: Ambos tokens tienen 6 decimales.
- **Función de Pausa**: Tanto OM como OC pueden ser pausados por el propietario del contrato para detener transacciones temporalmente.
- **Modularidad**: Los contratos tienen herencia de `Ownable` y `Pausable`, facilitando el control de acceso y la capacidad de pausa.
- **Quema de Tokens**: Solo el contrato OC permite la quema de tokens.

---

## Instrucciones de Despliegue

Para desplegar los contratos en la testnet **Nile** de Tron, sigue los siguientes pasos:

1. **Instala las Dependencias**:
   ```bash
   npm install
