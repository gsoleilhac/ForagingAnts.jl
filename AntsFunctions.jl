const _N,_NE,_E,_SE,_S,_SW,_W,_NW = (-1,0),(-1,1),(0,1),(1,1),(1,0),(1,-1),(0,-1),(-1,-1)
const offsets = SVector(_N,_NE,_E,_SE,_S,_SW,_W,_NW)
forward_offset(DIR) = begin
	DIR == _N && return SVector(_NW, _N, _NE)
	DIR == _NE && return SVector(_N, _NE, _E)
	DIR == _E && return SVector(_NE, _E, _SE)
	DIR == _SE && return SVector(_E, _SE, _S)
	DIR == _S && return SVector(_SE, _S, _SW)
	DIR == _SW && return SVector(_S, _SW, _W)
	DIR == _W && return SVector(_SW, _W, _NW)
	DIR == _NW && return SVector(_W, _NW, _N)
	return SVector((0,0),(0,0),(0,0))
end
mutable struct Ant
    x::Int
    y::Int
	orientation::Tuple{Int,Int}
	N::Int
    loaded::Bool
end
Base.show(io::IO, ant::Ant) = print("Ant($(ant.x), $(ant.y), $(ant.loaded)) ")
Ant() = Ant(1,1,rand(offsets),rand(2:7),false)

mutable struct AntData
	grid::Matrix{Int}
	home_pheromones::Matrix{Float64}
	food_pheromones::Matrix{Float64}
	MIN_PHERO::Float64
	MAX_PHERO::Float64
	N::Int
	is_paused::Bool
	skip_frames::Int
end

#Functions
drop_home_pheromones(ant, AD) = begin
	if is_on_base(ant, AD)
		AD.home_pheromones[ant.x, ant.y] = AD.MAX_PHERO
	else
		let home_pheromones = AD.home_pheromones
		MAX = maximum(x -> home_pheromones[x[1], x[2]], neighbor_locations(ant, AD))
		DES = MAX - 2
		D = DES - home_pheromones[ant.x, ant.y]
		D > 0 && (home_pheromones[ant.x, ant.y] += D)
		end
	end
	nothing
end
drop_food_pheromones(ant, AD) = begin
	if is_on_ressource(ant, AD)
		AD.food_pheromones[ant.x, ant.y] = AD.MAX_PHERO
	else
		let food_pheromones = AD.food_pheromones
		MAX = maximum(x -> food_pheromones[x[1], x[2]], neighbor_locations(ant, AD))
		DES = MAX - 2
		D = DES - food_pheromones[ant.x, ant.y]
		D > 0 && (food_pheromones[ant.x, ant.y] += D)
		# for (_x, _y) in neighbor_locations(ant, AD)
			# D = 0.001*DES - food_pheromones[_x, _x]
			# D > 0 && (food_pheromones[_x, _y] += D)
		# end
		end
	end
	nothing
end
neighbor_locations(ant, AD) = begin
	res = Tuple{Int,Int}[]
	for (dx, dy) in offsets
		_x, _y = ant.x + dx, ant.y + dy
		if 1 <= _x <= size(AD.grid, 1) && 1 <= _y <= size(AD.grid, 2) && AD.grid[_x,_y] != -1
			push!(res, (_x, _y))
		end
	end
	res
end
forward_locations(ant, AD) = begin
	res = Tuple{Int,Int}[]
	for (dx,dy) in forward_offset(ant.orientation)
		_x, _y = ant.x + dx, ant.y + dy
		if 1 <= _x <= size(AD.grid, 1) && 1 <= _y <= size(AD.grid, 2) && AD.grid[_x,_y] != -1
			push!(res, (_x, _y))
		end
	end
	res
end
is_on_ressource(ant, AD) = AD.grid[ant.x, ant.y] > 0
is_on_base(ant, AD) = AD.grid[ant.x, ant.y] == -2
has_food(ant) = ant.loaded
pickup_ressource(ant, AD) = begin AD.grid[ant.x,ant.y] -= 1 ; ant.loaded = true end
drop_ressource(ant, AD) = begin ant.loaded = false ; nothing end
forage(ant, AD) = has_food(ant) ? return_to_nest(ant, AD) : find_food(ant, AD)

location_max_pheromone(LocSet, pheromones) = begin
	imax = 1
	max = pheromones[LocSet[imax]...]
	for i = 2:length(LocSet)
		if pheromones[LocSet[i]...] > max
			max = pheromones[LocSet[i]...]
			imax = i
		end
	end
	return LocSet[imax]
end

select_location(LocSet, AD, N) = begin
	scores = map(x -> (AD.food_pheromones[x...])^N, LocSet)
	total = sum(scores)
	roulette = rand()*total
	i = 1
	sumroulette = scores[i]
	while sumroulette < roulette
		i+=1
		sumroulette += scores[i]
	end
	return LocSet[i]
end

function return_to_nest(ant, AD)
	if is_on_ressource(ant, AD)
		loc = location_max_pheromone(neighbor_locations(ant, AD), AD.home_pheromones)
		ant.orientation = (loc .- (ant.x, ant.y))
	end
	
	X = forward_locations(ant, AD)
	if isempty(X)
		X = neighbor_locations(ant, AD)
	end
	
	if !isempty(X)
		_x, _y = location_max_pheromone(X, AD.home_pheromones)
		drop_food_pheromones(ant, AD)
		ant.orientation = (_x-ant.x, _y-ant.y)
		ant.x, ant.y = _x, _y
		is_on_base(ant, AD) && drop_ressource(ant, AD)
	end
end

function find_food(ant, AD)
	if is_on_base(ant, AD)
		loc = location_max_pheromone(neighbor_locations(ant, AD), AD.food_pheromones)
		ant.orientation = (loc .- (ant.x, ant.y))
	end
	
	X = forward_locations(ant, AD)
	if isempty(X)
		X = neighbor_locations(ant, AD)
	end
	
	if !isempty(X)
		_x, _y = select_location(X, AD, ant.N)
		drop_home_pheromones(ant, AD)
		ant.orientation = (_x-ant.x, _y-ant.y)
		ant.x, ant.y = _x, _y
		is_on_ressource(ant, AD) && pickup_ressource(ant, AD)
	end
end