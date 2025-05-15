# UNOBDA 🎴

**UNOBDA** is a decentralized application (dApp) that brings the classic UNO card game to the Ethereum blockchain. Players can connect their wallets, join game sessions, and play UNO in a trustless environment, with game logic enforced by smart contracts.

## 🚀 Features

- **Multiplayer Gameplay**: Engage in UNO matches with other players in real-time.
- **Smart Contract Enforcement**: Game rules and logic are handled by Ethereum smart contracts, ensuring fairness and transparency.
- **Wallet Integration**: Seamless connection with Ethereum wallets like MetaMask for authentication and transactions.
- **Reward System**: Players can earn rewards based on game outcomes, with winnings distributed automatically via smart contracts.

## 🛠️ Tech Stack

- **Solidity**: Smart contracts for game logic.
- **Web3.js**: Interaction between the frontend and Ethereum blockchain.
- **HTML/CSS/JavaScript**: Frontend development.
- **Truffle**: Development framework for Ethereum.
- **Ganache**: Local Ethereum blockchain for testing.

## 📦 Installation

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/PranshuSaraswat/UNOBDA.git
   cd UNOBDA
   ```

2. **Install Dependencies**:

   ```bash
   npm install
   ```

3. **Compile Smart Contracts**:

   ```bash
   truffle compile
   ```

4. **Deploy Smart Contracts**:

   Ensure Ganache is running on your machine. Then, deploy the contracts:

   ```bash
   truffle migrate
   ```

## 🧪 Running the Application

1. **Start the Development Server**:

   ```bash
   npm start
   ```

2. **Access the Application**:

   Open your browser and navigate to `http://localhost:8080`.

3. **Connect Wallet**:

   - Install the MetaMask extension in your browser.
   - Connect MetaMask to your local Ganache network.
   - Import an account from Ganache into MetaMask using the private key.

## 🎮 How to Play

1. **Start a Game**:

   - Click on "Start Game" and pay the entry fee (minimum 0.01 ETH).

2. **Play UNO**:

   - Follow the on-screen prompts to play your cards according to UNO rules.

3. **Submit Win**:

   - If you win the game, click on "Submit Win" to claim your reward.

4. **Quit Game**:

   - If you choose to quit, click on "Quit Game" (note: a penalty applies).

5. **Check Game Status**:

   - View your current game status, including whether it's active, won, entry fee, and start time.

## 📁 Project Structure

- `contracts/`: Contains the Solidity smart contract (`SolitaireRewardGame.sol`).
- `migrations/`: Deployment scripts for Truffle.
- `build/`: Compiled contract artifacts.
- `index.html`: Frontend interface.
- `app.js`: JavaScript logic for frontend interactions.
- `package.json`: Project metadata and dependencies.
- `truffle-config.js`: Truffle configuration file.

## 📝 License

This project is licensed under the MIT License.
