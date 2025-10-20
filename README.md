
# KipuBankV3 🏦

### Versión: 3.0  
**Autor:** Jorge Andrés Jácome  
**Licencia:** MIT  
**Compilador:** Solidity ^0.8.24  
**Red de despliegue:** Sepolia Testnet  
**Contrato desplegado en:** `0x2c34A7aC74f6DfD4379a2Eeaa5d47321ae8De306`  

## 📖 Descripción General

**KipuBankV3** es la evolución avanzada del contrato bancario descentralizado **KipuBankV2**, diseñada para el mundo real DeFi. Este contrato acepta depósitos en **ETH, USDC y cualquier token ERC-20 soportado por Uniswap V4**, y convierte automáticamente estos activos a **USDC** usando el **Universal Router** de Uniswap. 

Su objetivo es proporcionar una bóveda segura y extensible, con integración a oráculos, control de acceso y swaps automáticos.

## 🎯 Objetivos del Proyecto

- Aceptar **cualquier token compatible con Uniswap V4**.
- Integrar **UniversalRouter** para realizar swaps on-chain.
- Convertir automáticamente a **USDC** al depositar.
- Respetar el límite de capacidad del banco (Bank Cap) en USD.
- Preservar la lógica de depósitos, retiros y roles administrativos de KipuBankV2.
- Usar **Chainlink** para obtener precios ETH/USD.

---

## 🧩 Características Principales

| Categoría | Descripción |
|------------|-------------|
| 🧠 **UniversalRouter** | Realiza swaps automáticos de tokens → USDC usando el router de Uniswap. |
| 💵 **Depósitos Generalizados** | Permite depositar ETH, USDC o cualquier token ERC20 soportado por Uniswap. |
| 🏦 **Bank Cap** | El valor total de USDC almacenado no puede superar un límite predefinido. |
| 🔒 **Seguridad** | Protección contra reentrancia, validaciones estrictas, uso de SafeERC20. |
| 🪙 **Chainlink Oracles** | Se integra con Chainlink para consultar precio ETH/USD en tiempo real. |
| 🎛 **Control de Acceso** | RBAC con OpenZeppelin: `DEFAULT_ADMIN_ROLE` y `BANK_MANAGER_ROLE`. |

---

## 🚀 Despliegue del Contrato

### Paso 1: Ejecutar el script de despliegue

```bash
forge script script/DeployKipuBankV3.s.sol:DeployKipuBankV3 \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

> Asegúrate de tener fondos en Sepolia y haber configurado correctamente tus variables de entorno.

---

### Paso 2: Verificación del contrato en Etherscan

```bash
forge verify-contract \
  --chain-id 11155111 \
  --num-of-optimizations 200 \
  --compiler-version v0.8.24+commit.e11b9ed9 \
  --watch \
  --constructor-args $(cast abi-encode "constructor(address,address,address,uint256,uint256)" \
      0x2c34A7aC74f6DfD4379a2Eeaa5d47321ae8De306 \
      0x65aFADD39029741B3b8f0756952C74678c9cEC93 \
      0x694AA1769357215DE4FAC081bf1f309aDC325306 \
      1000000000000 \
      100000000000) \
  0x1d396bF48ca83B2D5672b8Bb9A330a4AaCd07864 \
  src/KipuBankV3.sol:KipuBankV3 \
  $ETHERSCAN_API_KEY
```

---

## 📦 Componentes Desplegados

| Contrato              | Dirección |
|-----------------------|-----------|
| **KipuBankV3**        | `0x2c34A7aC74f6DfD4379a2Eeaa5d47321ae8De306` |
| **MockUniversalRouter** | `0x1d396bF48ca83B2D5672b8Bb9A330a4AaCd07864` |

---

## 🔍 Funciones Clave del Contrato

| Función | Descripción |
|--------|-------------|
| `depositETH()` | Permite depositar ETH. Se convierte automáticamente a USDC. |
| `depositArbitraryToken(address token, uint256 amount)` | Permite depositar cualquier token ERC-20. Se convierte a USDC usando UniversalRouter. |
| `withdraw(uint256 amount)` | Permite retirar USDC si se tiene suficiente saldo. |
| `getVaultBalance(address user)` | Devuelve el saldo USDC del usuario. |
| `getLatestETHPrice()` | Retorna el último precio de ETH/USD desde Chainlink. |

---

## 🧠 Decisiones de Diseño y Trade-offs

- Se integró **UniversalRouter** pero se usó un mock (`MockUniversalRouter`) para evitar complejidades y errores por submódulos fallidos durante `forge install`.
- Aunque se intentó integrar completamente `Permit2`, `PoolKey`, `Currency`, y `Actions` de Uniswap, estos se excluyeron por conflictos de dependencias o errores estructurales. Se mantiene la estructura preparada para integrarlos más adelante.
- Se priorizó el cumplimiento funcional sobre la integración profunda con Uniswap V4 internals.

---

## ✅ Tests

Se implementaron pruebas básicas con **Forge**:

```bash
forge test -vv
```

Incluyen:

- Validación de despliegue correcto.
- Evento `DepositMade` emitido al depositar ETH.
- Validación de lógica de `withdraw`.

---

## 🧾 Licencia

MIT License.  
© 2025 — KipuBankV3 by Jorge Andrés Jácome.





