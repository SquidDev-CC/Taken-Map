return {
	map = {
		-- Height of the world
		ceiling = 7,
		--- Width of the map
		width = 25,
		--- Height of the map
		height = 25,
	},

	--- Distance to offset player position checks:
	-- This prevents walking diagnoally (see @HDeffo)
	check_offset = 0.05,

	--- Display debug particles
	debug_particles = false,
}
