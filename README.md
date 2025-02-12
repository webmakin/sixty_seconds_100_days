# Game Project

This project is a 2D game developed using the LÖVE framework, a popular framework for game development in Lua. Below is an explanation of the main components and functionality of the game.

## Main Components

### Libraries and Modules
- **JSON Handling**: Utilizes the `dkjson` library for parsing JSON data, specifically for loading collectible data.
- **Physics**: Uses the `windfield` library to create a physics world, handling collision detection and response.
- **Camera**: Manages the camera view with the `camera` library, allowing it to follow the player.
- **Animation**: Implements sprite animations using the `anim8` library.
- **Tile Maps**: Loads and renders tile maps with the `Simple Tiled Implementation (sti)` library.

### Game State and Initialization
- **Game State**: The game has two states: `1` for the main menu and `2` for the game in session.
- **Timer**: A countdown timer initialized to 60 seconds, displayed during gameplay.
- **Player Setup**: Initializes the player with a starting position, speed, and animations for different movement directions.

### Collision Classes
- The game world is set up with collision classes for different entities: `Player`, `Walls`, `Doors`, and `Collectibles`.

## Functions

- **`love.load()`**: Initializes the game, setting up the player, loading the first level, and preparing the game world.
- **`spawnWalls()`, `spawnDoors()`, `spawnCollectibles()`**: Create colliders for walls, doors, and collectibles based on the map data.
- **`destroyAll()`**: Destroys all colliders for walls, doors, and collectibles, used when loading a new level.
- **`loadMap(level)`**: Loads a specified level, setting up the map and resetting the player's position.
- **`love.update(dt)`**: Updates the game state each frame, handling player movement, collision detection, and camera positioning. Manages level transitions and the countdown timer.
- **`drawCollectibles()`**: Draws the collectible items on the screen.
- **`distanceBetween(x1, y1, x2, y2)`**: Utility function to calculate the distance between two points.
- **`love.draw()`**: Renders the game, including map layers, player animations, and UI elements like the timer or start prompt.

## Gameplay Mechanics

- **Player Movement**: The player can move in four directions using the arrow keys, with animations changing based on direction.
- **Level Transition**: The player can transition to the next level by colliding with doors.
- **Collectibles**: The player can collect items by colliding with them, removing the item from the game world.
- **Camera**: The camera follows the player, ensuring the player is always centered in the view, with constraints to prevent viewing outside the map boundaries.

## User Interface

- **Main Menu**: Displays a prompt to start the game.
- **In-Game Timer**: Displays the remaining time for the current level.

## Additional Files

- **`maps/OldMap.lua`**: Contains data for an older version of the game map.
- **`maps/testMap.lua`**: Contains data for the test map used in the game.

This README provides an overview of the game's structure and functionality, focusing on the main script and its components. 