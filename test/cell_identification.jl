@testitem "Test begin finding" begin
    import PlutoSplitter

    @test PlutoSplitter.begin_occursin("#= begin statement =# f(10)", "statement") == true
    @test PlutoSplitter.begin_occursin("f(10)", "statement") == false
    # Begin should be in the beginning, ignoring whitespace
    @test PlutoSplitter.begin_occursin("   #= begin statement =# f(10)", "statement") == true
    @test_throws "not at the beginning of the cell" PlutoSplitter.begin_occursin("f(10) #= begin statement =#", "statement")
end

@testitem "Test end finding" begin
    import PlutoSplitter

    @test PlutoSplitter.end_occursin("f(10) #= end statement =#", "statement") == true
    @test PlutoSplitter.end_occursin("f(10)", "statement") == false
    # End should be in the end, ignoring whitespace
    @test PlutoSplitter.end_occursin("f(10)   #= end statement =#   ", "statement") == true
    @test_throws "not at the end of the cell" PlutoSplitter.end_occursin("#= end statement =# f(10)", "statement")
end
