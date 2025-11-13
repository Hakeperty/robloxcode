# Bike Racing Game - Roblox

A motorcycle racing game built for Roblox using Rojo for development.

## Project Structure

```
Studiocode/
├── src/                           # Source code (synced with Rojo)
│   ├── ServerScriptService/       # Server-side scripts
│   │   ├── GameManager.lua        # Main game management
│   │   └── BikeSpawner.lua        # Bike spawning logic
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/  # Client-side scripts
│   │       └── BikeController.lua # Bike control system
│   └── ReplicatedStorage/
│       └── Modules/               # Shared modules
│           └── GameConfig.lua     # Game configuration
├── models/                        # 3D models (import to Roblox Studio)
│   ├── bikegame.obj
│   ├── bikegame.mtl
│   └── Export.gltf
├── textures/                      # Texture files (import to Roblox Studio)
│   ├── *_diff.png                 # Diffuse/color maps
│   ├── *_nmap.png                 # Normal maps
│   └── *_spec.png                 # Specular maps
└── default.project.json           # Rojo project configuration

```

## Setup Instructions

### Prerequisites

1. **Install Rojo**
   ```powershell
   # Using aftman (recommended)
   aftman add rojo-rbx/rojo

   # Or download from: https://rojo.space/
   ```

2. **Install Rojo Plugin in Roblox Studio**
   - Download from: https://rojo.space/docs/v7/getting-started/installation/
   - Or install from the Roblox plugin marketplace

3. **Install Luau Language Server (Optional but recommended)**
   - Install the "Luau Language Server" extension in VS Code
   - Provides autocomplete and type checking for Roblox Lua

### Running the Project

1. **Start Rojo Server**
   ```powershell
   rojo serve
   ```
   This will start a server on `localhost:34872`

2. **Connect from Roblox Studio**
   - Open Roblox Studio
   - Click the Rojo plugin button in the toolbar
   - Click "Connect" and select the default port (34872)
   - Your code will sync automatically!

3. **Build a standalone place file (optional)**
   ```powershell
   rojo build -o BikeGame.rbxl
   ```

### Importing Assets

#### 3D Models
1. Open Roblox Studio
2. Go to **Home → Import 3D** 
3. Select files from the `models/` folder:
   - `Export.gltf` (primary model file)
   - Or `bikegame.obj` if GLTF doesn't work
4. Position models in Workspace

#### Textures
1. In Roblox Studio, select the model part
2. In Properties panel, find the **TextureID** property
3. Click the folder icon to import textures from `textures/` folder
4. Apply diffuse (_diff), normal (_nmap), and specular (_spec) maps as needed

## Game Features

### Current Implementation

- **Player Management**: Automatic leaderstats creation (Coins, Distance)
- **Bike System**: Basic bike spawning and mounting
- **Controls**: 
  - `E` - Mount/Dismount bike
  - `W/S` - Forward/Backward
  - `A/D` - Turn left/right

### Configuration

Edit `src/ReplicatedStorage/Modules/GameConfig.lua` to adjust:
- Bike speed, turn rate, jump power
- Economy settings (coins per meter, trick bonuses)
- Player settings (starting coins, respawn time)
- Map settings (gravity, day/night cycle)

## Development Workflow

1. Edit `.lua` files in your code editor (VS Code recommended)
2. Rojo automatically syncs changes to Roblox Studio
3. Test in Roblox Studio
4. Commit changes to version control

## Useful Commands

```powershell
# Start Rojo server
rojo serve

# Build a place file
rojo build -o BikeGame.rbxl

# Build a model file
rojo build -o BikeGame.rbxm

# Check Rojo version
rojo --version
```

## Next Steps

1. Import your models from `models/` folder into Workspace
2. Apply textures from `textures/` folder to model parts
3. Create spawn locations in Workspace (name the folder "SpawnLocations")
4. Adjust bike physics in `GameConfig.lua`
5. Test bike controls in Studio

## Troubleshooting

- **Rojo won't connect**: Make sure the Rojo server is running (`rojo serve`)
- **Scripts not appearing**: Check that `default.project.json` paths are correct
- **Models not loading**: Use the GLTF format first, fall back to OBJ if needed
- **Textures look wrong**: Ensure you're applying the correct map type (diffuse/normal/specular)

## Resources

- [Rojo Documentation](https://rojo.space/docs)
- [Roblox Developer Hub](https://create.roblox.com/docs)
- [Luau Language Guide](https://luau-lang.org/)
