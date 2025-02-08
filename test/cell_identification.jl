@testitem "Test split finding" begin
    import PlutoSplitter: parse_split_tag, SplitTag

    # Test statement tag with various spacing
    @test parse_split_tag("### split: statement\n") == SplitTag("statement", false)
    @test parse_split_tag("###split:statement\n") == SplitTag("statement", false)
    # Test other tag types
    @test parse_split_tag("### split: solution\n") == SplitTag("solution", false)
    @test parse_split_tag("### split: statement,folded\n") == SplitTag("statement", true)
    @test parse_split_tag("### split: solution,folded\n") == SplitTag("solution", true)
    # Test common errors
    @test_throws "Unknown split: tag: unknown" parse_split_tag("### split: unknown\n")
    @test_throws "should be on the first line" parse_split_tag("f(10)\n### split: statement")
    @test_throws "should be on the first line" parse_split_tag("### split: statement")
    # trailing whitespace is currently not allowed
    @test_throws "Unknown split: tag: statement   " parse_split_tag("###   split: statement   \n")
end
