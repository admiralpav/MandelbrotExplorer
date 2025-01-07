println("Loading modules.")
import Pkg
Pkg.add("Images")
Pkg.add("FileIO")
using Images
using FileIO
function tinkerbell(a,b,c,d, itr) # ab earlier experiment, plots a tinkerbell map
	x = -0.72
	y = -0.64
	xar = Vector{Float64}()
	yar = Vector{Float64}()
	@time for i in 1:itr
		x_copy = x + 0
		x = x^2 - y^2 + a*x + b*y
		y = 2*x_copy*y + c*x_copy + d*y
		push!(xar, x)
		push!(yar, y)
	end
	display(scatter(xar,yar,markersize=0))
end

function progressbar(progress) # https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
	k = round(progress*100, digits=1) # displays a dynamic progress bar
	j = "\e[A[" * "="^Int(floor(progress*50)) * ">" * " "^Int((50-floor(progress*50))) * "] $k%"
	println(j)
end

function renderimg(data) # takes data from the generator functions
	global itr # and renders it in the terminal using ANSI
	g = 232:255 # 24 shade grayscale
	d = size(data)
	minval = minimum(data)
	maxval = max(maximum(data),minval+1)
	scaledmin = minval/itr
	scaledmax = maxval/itr
	s = ["\e[H"]
	for x in 1:d[1]
		for y in 1:d[2]
			val = data[x,y]/itr
			scaledval = (val-scaledmin)/(scaledmax-scaledmin)*(length(g)-1) # this scales the data so black is the
			element = g[Int64(round(scaledval))+1] # least iterations, and white is the most
			push!(s,"\e[38;5;$element"*"m██") # this uses an ANSI color code to change the color of two full block characters
		end # two full blocks is approximately a square on most screens
		push!(s,"\n")
	end
	itr = min((8*(minval))+100,10^6) # automatic iteration control
	print(join(s))
end # another way this could be done, with double the resolution per line, is to use 2 vertical half blocks,
# and by controlling the background and the foreground, you could acheive twice the vertical and horizontal resolution
# I chose this approach for simplicity
function mandelbrot(res, lim)
	global dat, x_center, y_center, zoom # import global settings
	x_axis = (x_center-zoom):(zoom/res):(x_center+zoom)
	y_axis = (y_center-zoom):(zoom/res):(y_center+zoom)
	dat = zeros(Int32, length(y_axis), length(x_axis)) # create output matrix
	p = 0 # this is just for the progress bar
	g = floor(length(x_axis)/1000)
	Threads.@threads for x in 1:length(x_axis)
		for y in 1:length(y_axis)
			k = 0
			c = complex(x_axis[x],y_axis[y]) # makes use of Julia's built-in complex type
			z = 0
			for i in 1:lim
				z = z^2 + c
				if abs(z) >= 2
					break
				end
				k += 1
			end
			dat[y,x] = k
		end
		p += 1
		if p % g == 0 # so we don't print the progress bar every time
			progressbar(p/length(x_axis))
		end # this removes a print bottleneck
	end
end

function burning_ship(res, lim) # exactly the same as the above function, but real and imaginary parts are made positive every iteration
	global dat, x_center, y_center, zoom
	x_axis = (x_center-zoom):(zoom/res):(x_center+zoom)
	y_axis = (y_center-zoom):(zoom/res):(y_center+zoom)
	dat = zeros(Int32, length(y_axis), length(x_axis))
	p = 0
	g = floor(length(x_axis)/1000)
	Threads.@threads for x in 1:length(x_axis)
		for y in 1:length(y_axis)
			k = 0
			c = complex(x_axis[x],y_axis[y])
			z = 0
			for i in 1:lim
				z = complex(abs(real(z)),abs(imag(z)))^2 + c
				if abs(z) >= 2
					break
				end
				k += 1
			end
			dat[y,x] = k
		end
		p += 1
		if p % g == 0
			progressbar(p/length(x_axis))
		end
	end
end
print("Mandelbrot [m] or Burning ship [b]> ")
fractaltype = readline()
fractal = fractaltype == "m" ? mandelbrot : burning_ship # using functions as an object
global x_center = -0.75
global y_center = 0
zoom = 1.25
itr = 150
# commands: wasd to move by 1/4 zoom in direction, i to zoom in, o to zoom out, q to quit, r to render a large image, zoom is x2 or x1/2
while true
	d = displaysize(stdout)
    res = Int64(ceil((minimum(d)-3)/2)) # get terminal size and scale preview to match
    fractal(res,itr) # generate the image
	renderimg(dat) # display it in terminal
    realzoom = (1.25/zoom) # temp variable
	print("\e[38;5;255m[wasd to move, i/o to zoom in/out, q to quit, r to render and save, h to home. Zoom is at $realzoom times]>")
	cmd = readline() # get user input
	if cmd == "i"
		global zoom /= 2
	elseif cmd == "o"
		global zoom *= 2
	elseif cmd == "q"
		break
	elseif cmd == "w"
		global y_center -= zoom/4
	elseif cmd == "s"
        global y_center += zoom/4
	elseif cmd == "d"
        global x_center += zoom/4
	elseif cmd == "a"
        global x_center -= zoom/4
	elseif cmd == "r" # render image and export
		print("Enter resolution> ")
		@time fractal(parse(Int64,readline()),itr*2) # time the render
		print("Enter save path> ")
        minval = minimum(dat)
        maxval = max(maximum(dat),minval+1)
        dat .-= minval # do the same kind of contrast scaling that renderimg does
		save(readline(),dat ./ (maxval-minval))	
	elseif cmd == "h"
		global x_center = -0.75
		global y_center = 0 # reset the viewer
		global zoom = 1.25
	end
end
