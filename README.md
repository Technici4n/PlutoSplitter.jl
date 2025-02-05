# PlutoSplitter.jl
A simple Julia package to split Pluto notebooks that contain both a statement and a solution,
so that a statement and a solution notebook can be generated from the same source.

With this package, you can write a notebook that contains two cells, for example:
```jl
#= begin statement =#
# Fill in your code here, by replacing nothing
# with a function that adds 42 to x
f(x) = nothing
#= end statement =#
```
and
```jl
#= begin solution =#
f(x) = x + 42
#= end solution =#
```
(You will have to disable one of them to fit both in the notebook.)

Finally, you can generate a statement and a solution notebook as follows:
```jl
using PlutoSplitter

# Perform some checks without generating anything
split_notebook("path/to/your_notebook.jl", "check")

# Generate path/to/your_notebook_statement.jl
split_notebook("path/to/your_notebook.jl", "statement")

# Generate path/to/your_notebook_solution.jl
split_notebook("path/to/your_notebook.jl", "solution")
```
