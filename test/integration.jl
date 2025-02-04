@testitem "Test full notebook" begin
    using PlutoSplitter
    import Pluto

    mktempdir() do tempdir
        nbfile = joinpath(tempdir, "notebook.jl")
        cp(joinpath(@__DIR__, "..", "examples", "simple.jl"), nbfile)
        split_notebook(nbfile, "check")

        @test readdir(tempdir) == ["notebook.jl"]

        split_notebook(nbfile, "statement")
        split_notebook(nbfile, "solution")
        @test readdir(tempdir) == ["notebook.jl", "notebook_solution.jl", "notebook_statement.jl"]

        statement_nb = Pluto.load_notebook(joinpath(tempdir, "notebook_statement.jl"))
        @test length(statement_nb.cells) == 2
        @test statement_nb.cell_order == [
            Base.UUID("d9e9f737-6c87-4935-8252-8d576c195ced"),
            Base.UUID("86cb479c-6bd1-4703-950e-544a877d9023")]
        @test Pluto.is_disabled(statement_nb.cells[1]) == false
        @test Pluto.is_disabled(statement_nb.cells[2]) == false
        @test statement_nb.cells[1].code == "f(x) = nothing"
        @test statement_nb.cells[2].code == "f(10)"

        solution_nb = Pluto.load_notebook(joinpath(tempdir, "notebook_solution.jl"))
        @test length(solution_nb.cells) == 2
        @test solution_nb.cell_order == [
            Base.UUID("02f2e7c5-2f0d-4fee-a7f3-27b088411aa6"),
            Base.UUID("86cb479c-6bd1-4703-950e-544a877d9023")]
        @test Pluto.is_disabled(solution_nb.cells[1]) == false
        @test Pluto.is_disabled(solution_nb.cells[2]) == false
        @test solution_nb.cells[1].code == "f(x) = x + 42"
        @test solution_nb.cells[2].code == "f(10)"
    end
end