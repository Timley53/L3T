# L3Token

L3Token is an ERC20-compatible token built using OpenZeppelin libraries.  
It serves as a lightweight but extendable foundation for experimenting with ERC20 features and role-based access control.

---

## Features

- **ERC20 Standard**  
  Fully compliant with the ERC20 token interface.

- **Ownable (2-step ownership transfer)**  
  Ownership can be securely transferred using OpenZeppelin's `Ownable2Step`.

- **Role-Based Access Control**  
  Uses `AccessControl` for fine-grained permissions.

  - `DEFAULT_ADMIN_ROLE` – Deployer is granted this role at deployment.
  - `MINTER_ROLE` – Controls who can mint new tokens.

- **Minting**

  - Only addresses with the `MINTER_ROLE` can mint tokens.
  - Tested with role assignment and restriction cases.

- **Pausable**
  - Token transfers, minting, and burning can be paused/unpaused.
  - Only the contract **owner** can pause/unpause.
  - Useful for emergency stops.

---

## Recent Updates

### 🚀 New in Latest Commit

- Added **`MINTER_ROLE`** for controlled token minting.
- Added **`PAUSABLE_ROLE`** for emergency stops.
- Integrated **`Pausable`** module with `pause` and `unpause` functionality.
- Restricted pausing/unpausing to **only the contract owner**.
- Added **unit tests** for minting roles and pause/unpause functionality — all tests passed.

---

## Deployment

1. Install dependencies:

   ```bash
   forge build
   ```

2. Deploy locally (anvil):

```bash
  anvil
```

In new terminal:

````bash
    forge create script/L3Token.s.sol:L3TokenScript --private-key <YOUR_PRIVATE_KEY>
    ```

3. Deploy to a testnet (example: Sepolia):

```bash
forge script script/L3Token.s.sol:L3TokenScript \
--rpc-url $SEPOLIA_RPC_URL \
--private-key $PRIVATE_KEY
````

## Testing

Run all tests:

```bash
forge test
```

Run with verbose output:

```bash
forge test -vvvv
```

## Roadmap/Planned Features

- More ERC-20 compatible openzeppelin modules
- More granular role assignments

## Licence

MIT
