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

1. **Get the Honda CBR1000RR Fireblade Model**
   - Download from Roblox: https://create.roblox.com/store/asset/10655506812/2008-Honda-CBR1000RR-Fireblade
   - In Roblox Studio, go to Toolbox > Inventory
   - Find "2008 Honda CBR1000RR Fireblade" and insert it
   - Move the model to `ReplicatedStorage > Vehicles` folder (create the Vehicles folder if needed)
   - The game is designed to work with this specific bike model

2. **Install Rojo**
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
   cd "c:\Users\harry\OneDrive\RBgame\Newfolder\Studiocode"
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

#### 🏍️ Realistic Motorcycle Physics
- **Authentic Honda CBR1000RR Fireblade simulation**
  - Real engine specifications (178 bhp, 999cc inline-4)
  - Accurate weight distribution and handling
  - True-to-life top speed (299 km/h / 186 mph)
  - Realistic 0-60 mph in 2.9 seconds
  - 6-speed transmission with authentic gear ratios

#### 🎮 Advanced Riding Dynamics
- **Professional Handling System**
  - 58-degree maximum lean angle
  - Responsive steering with speed-sensitive input
  - Realistic suspension simulation
  - Tire physics with grip and slip modeling
  - Weight transfer during acceleration/braking

#### 🚀 Riding Assists & Features
- **Traction Control System (TCS)** - Prevents wheel spin
- **Anti-lock Braking System (ABS)** - Optimal braking
- **Linked Brakes** - Front/rear brake coordination
- **Burnout Mode** - Hold brake + throttle for tire smoke
- **Wheelie Control** - Toggle anti-wheelie assist
- **Dual-Clutch Transmission (DCT)** - Auto or manual shifting

#### 🎨 Immersive Visual Effects
- **Dynamic Camera System**
  - First-person helmet camera with visor tints
  - Speed-based FOV changes
  - Lean angle camera tilting
  - Camera shake for realism
- **Particle Effects**
  - Tire smoke during burnouts
  - Brake dust
  - Exhaust fumes with heat distortion
  - Sparks from scraping
- **Speed Lines** - Visual speed indication at high velocity
- **Motion Blur** - Speed-based blur effects
- **Weather System** - Dynamic rain with droplets on visor

#### 🌦️ Dynamic Weather & Environment
- **Day/Night Cycle** - 8-minute day, 4-minute night
- **Weather System**
  - Dynamic rain intensity
  - Wind effects on handling
  - Surface wetness simulation
  - Storm with lightning flashes
- **Lighting Effects**
  - Automatic headlight (activates at dusk)
  - Brake lights with intensity boost
  - Realistic sun glare effects

#### 📊 Professional HUD
- **Speedometer** - Real-time speed display (KM/H or MPH)
- **Tachometer** - RPM gauge with redline warning
- **Gear Indicator** - Current gear display with color coding
- **Instrument Cluster** - Integrated helmet cam display
- **Performance Stats** - Speed, RPM, gear, traction status

#### 🎯 Game Mechanics
- **Economy System**
  - Earn coins for distance traveled
  - Speed bonus multipliers
  - Trick bonuses (wheelies, drifts, jumps)
  - Near-miss bonuses
  - Perfect shift rewards
- **Player Stats** - Coins and distance tracking via leaderstats

#### 🎚️ Controls
- **Keyboard**
  - `W/S` or `↑/↓` - Throttle/Brake
  - `A/D` or `←/→` - Steering
  - `E/Q` - Shift up/down (manual mode)
  - `Shift` - Handbrake
  - `M` - Toggle auto/manual transmission
  - `T` - Toggle traction control
  - `Y` - Toggle ABS
- **Mouse & Controller Support** - Full gamepad compatibility

### Configuration

#### Game Settings
Edit `src/ReplicatedStorage/Modules/GameConfig.lua` to customize:
- **Bike Performance** - Speed, acceleration, handling
- **Physics** - Weight, power, transmission ratios
- **Visual Effects** - Enable/disable speed lines, motion blur
- **Economy** - Coin earning rates and bonuses
- **Gameplay** - Assists, realism mode, traffic
- **UI Settings** - HUD colors, speed units, display options

#### Advanced Tuning
Edit `src/ReplicatedStorage/Modules/Tuner.lua` for detailed tuning:
- Engine torque curve and power output
- Suspension stiffness and damping
- Tire compound and friction
- Aerodynamics and drag coefficient
- Brake balance and force
- Steering geometry and responsiveness

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
