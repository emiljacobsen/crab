# TODO

- Refactor: entities, arena, grid, draw; minimize main.lua
- Comments above functions
- Coords-to-triords in arena.lua
- Enemy collisions with player and walls and obstacles
- Make enemies move slightly after the player
- Load / save map from text file
- Map editor
- Add direction toggle
- System for UI elements (info / toggles / etc, automatically spaced)
- Line rendering instead of triangle rendering
- Track vertices that are on / off; mark the on ones
- Change movement? Only half the "hubs" are accessible.
- Draw ability compass
- Compass rotation
- Two simple abilities and put on compass

## DONE

- Draw a triangulated ~~square~~ hexagon
- Draw a crab representative
- Move crab with key presses
- Correct new direction after moving -- requires overhaul
- Warping
- Walls
- Obstacles
- Colour code adjacency dots
- Remove adjacency dots from walls and obstacles
- Mark the "current hexagon"
- Mouse controls
- Refactor: walls and obstacles go where? Maybe a new structures.lua?