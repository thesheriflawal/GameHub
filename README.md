# Connect Four Blockchain Game

A fully decentralized, multiplayer Connect Four game built on the Lisk Sepolia network using Solidity smart contracts and React frontend. Players can create rooms, join games, and play Connect Four with real-time blockchain state management.

## Contract Deployment

**Network:** Lisk Sepolia  
**Contract Address:** `0x924172b50159CC1C6857AF841b93364B5ffA8b24`  
**Deployer:** `0x5d813b3c40b0b0e012e5156fc41963C56E3bf1DD`  
**Transaction Hash:** `0x067330995c4f8ccb922218b954048e7d96380b96898c305c024ca2d05b7e6fae`  
**Deployment Date:** August 30, 2025

[View on Lisk Sepolia Explorer](https://sepolia-blockscout.lisk.com/address/0x924172b50159CC1C6857AF841b93364B5ffA8b24)

## Features

### Smart Contract Features

- **Room-based Gameplay** - Create and join game rooms with unique room IDs
- **Session Key Support** - Account abstraction support for gasless transactions
- **Turn-based Logic** - Enforced turn management with timeout mechanisms
- **Win Detection** - Automatic win/draw detection with winning cell tracking
- **Move History** - Complete move tracking for each game
- **Game State Management** - Comprehensive game status and player management
- **Security** - ReentrancyGuard and access control for safe gameplay

### Frontend Features

- **MetaMask Integration** - Connect wallet to play games
- **Real-time Updates** - Live game state updates via smart contract events
- **Responsive UI** - Built with Tailwind CSS for all device sizes
- **Game Lobbies** - Create or join rooms with shareable room codes
- **Move Timer** - 5-minute turn timer to prevent game stalling
- **Visual Feedback** - Animated game pieces and win highlighting
- **Error Handling** - User-friendly error messages and retry mechanisms

## Game Rules

1. **Objective**: Connect four pieces vertically, horizontally, or diagonally
2. **Players**: 2 players per game (Player 1: Red, Player 2: Yellow)
3. **Turns**: 5-minute time limit per move
4. **Timeout**: Game ends if player doesn't move within time limit
5. **Board**: 6 rows × 7 columns grid

## Smart Contract Architecture

### Core Components

- **Game Management**: Create, join, and manage game sessions
- **Move Validation**: Ensure valid moves and turn enforcement
- **Win Detection**: Automatic detection of winning conditions
- **Session Keys**: Support for meta-transactions and gasless gameplay
- **Event System**: Real-time game updates through blockchain events

### Key Functions

```solidity
function createGame(string calldata roomId) external returns (uint256)
function joinGame(string calldata roomId) external
function makeMove(uint256 gameId, uint8 column) external
function forfeitGame(uint256 gameId) external
function getGameState(uint256 gameId) external view returns (...)
```

### Events

- `GameCreated` - When a new game room is created
- `PlayerJoined` - When second player joins the room
- `MoveMade` - When a player makes a move
- `GameFinished` - When game ends (win/draw/timeout)
- `GameAbandoned` - When game is abandoned

## Installation & Setup

### Prerequisites

- Node.js (v16+)
- MetaMask browser extension
- Git

### Frontend Setup

1. **Clone the repository:**

```bash
git clone https://github.com/your-username/connect-four-blockchain.git
cd connect-four-blockchain
```

2. **Install dependencies:**

```bash
npm install
```

3. **Configure environment:**

```bash
cp .env.example .env.local
```

4. **Update contract configuration:**

```javascript
// In your config file
const CONTRACT_ADDRESS = "0x924172b50159CC1C6857AF841b93364B5ffA8b24";
const NETWORK_CONFIG = {
  chainId: 4202, // Lisk Sepolia
  chainName: "Lisk Sepolia Testnet",
  rpcUrls: ["https://rpc.sepolia-api.lisk.com"],
  blockExplorerUrls: ["https://sepolia-blockscout.lisk.com"],
};
```

5. **Start development server:**

```bash
npm run dev
```

### MetaMask Setup

1. **Add Lisk Sepolia Network:**

   - Network Name: `Lisk Sepolia Testnet`
   - RPC URL: `https://rpc.sepolia-api.lisk.com`
   - Chain ID: `4202`
   - Currency Symbol: `ETH`
   - Block Explorer: `https://sepolia-blockscout.lisk.com`

2. **Get test ETH:**
   - Use Lisk Sepolia faucet to get test tokens
   - Minimum 0.01 ETH needed for game transactions

## How to Play

### Creating a Game

1. **Connect Wallet** - Connect your MetaMask wallet
2. **Enter Username** - Choose your display name
3. **Create Room** - Click "Create Room" to generate a unique room ID
4. **Share Room ID** - Send the room code to your opponent
5. **Wait for Player** - Game starts when second player joins

### Joining a Game

1. **Connect Wallet** - Connect your MetaMask wallet
2. **Enter Username** - Choose your display name
3. **Enter Room ID** - Input the room code from your friend
4. **Join Game** - Click "Join Room" to enter the game
5. **Start Playing** - Game begins immediately

### Gameplay

1. **Make Moves** - Click on columns to drop your pieces
2. **Turn Timer** - You have 5 minutes per move
3. **Win Condition** - Connect 4 pieces in any direction
4. **Game End** - Winner is declared automatically

## Technical Architecture

### Frontend Stack

- **React** - Component-based UI framework
- **Next.js** - React framework with SSR support
- **Tailwind CSS** - Utility-first CSS framework
- **Ethers.js** - Ethereum library for blockchain interaction
- **Lucide React** - Icon library

### Smart Contract Stack

- **Solidity** - Smart contract programming language
- **OpenZeppelin** - Security and standard contract libraries
- **Hardhat** - Development environment and testing framework

### Network Infrastructure

- **Lisk Sepolia** - Layer 2 testnet for Ethereum
- **MetaMask** - Web3 wallet for transaction signing
- **Blockchain Events** - Real-time game state synchronization

## Gas Optimization

The smart contract includes several gas optimization features:

- **Efficient Storage** - Packed structs to minimize storage slots
- **Event-based Updates** - Minimal on-chain storage with rich events
- **Session Keys** - Gasless transactions through account abstraction
- **Batch Operations** - Combined operations to reduce transaction count

## Security Features

- **ReentrancyGuard** - Prevents reentrancy attacks
- **Access Control** - Ownable pattern for admin functions
- **Input Validation** - Comprehensive input sanitization
- **Time-based Security** - Move timeouts prevent griefing
- **State Validation** - Immutable game logic enforcement

## Development & Testing

### Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

### Contract Interaction

```javascript
// Example: Create a new game
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
const tx = await contract.createGame("ROOM123");
const receipt = await tx.wait();
```

## Troubleshooting

### Common Issues

1. **MetaMask Connection Issues**

   - Ensure you're on Lisk Sepolia network
   - Check that you have sufficient ETH for gas fees
   - Try disconnecting and reconnecting wallet

2. **Transaction Failures**

   - Verify contract address is correct
   - Check gas limit and gas price settings
   - Ensure game state allows the action

3. **Game State Issues**
   - Refresh page to sync with blockchain state
   - Check network connection
   - Verify you're in the correct game room

### Support

For technical issues or questions:

- Create an issue on GitHub
- Check the contract on block explorer
- Verify network connectivity

## Future Enhancements

- **Tournament Mode** - Multi-round tournaments with leaderboards
- **NFT Integration** - Collectible game pieces and achievements
- **Mobile App** - React Native mobile application
- **AI Opponent** - Single-player mode with AI
- **Replay System** - Game replay and analysis features
- **Custom Themes** - Personalized game board themes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on the Lisk ecosystem
- Uses OpenZeppelin security standards
- Inspired by classic Connect Four gameplay
- Community-driven development approach
