module PlutoSplitter

using Logging
import Pluto

SPLIT_REGEX_MULTILINE = r"^#\s*split:\s*(.*)$"m
SPLIT_REGEX = r"^#\s*split:\s*(.*)\n"

struct SplitTag
    kind::String
    folded::Bool
end

function parse_split_tag(code::String)
    m = match(SPLIT_REGEX, code)
    if isnothing(m)
        if occursin(SPLIT_REGEX_MULTILINE, code)
            error("split: tag should be on the first line of cell $code.")
        end
        return nothing
    end
    tag = m.captures[1]
    if tag == "statement"
        SplitTag("statement", false)
    elseif tag == "solution"
        SplitTag("solution", false)
    elseif tag == "statement,folded"
        SplitTag("statement", true)
    elseif tag == "solution,folded"
        SplitTag("solution", true)
    else
        error("Unknown split: tag: $tag in cell $code.")
    end
end

function strip_tag(code::String)
    replace(code, SPLIT_REGEX => "")
end

function check_fold(tag::SplitTag, cell)
    if tag.folded && !cell.code_folded
        error("Either cell $(cell.code) should be folded, or `,folded` should be removed from the split tag.")
    end
    if !tag.folded && cell.code_folded
        error("Either cell $(cell.code) should be unfolded, or `,folded` should be added to the split tag.")
    end
end

function delete_cell_at(notebook, i)
    id = notebook.cell_order[i]
    deleteat!(notebook.cell_order, i)
    delete!(notebook.cells_dict, id)
end

export split_notebook

"""
Split a notebook file.

- notebookfile: File to split.
- type: Type of splitting to perform.
        Can be "check" to only perform some sanity checks, "statement" or "solution".
"""
function split_notebook(notebookfile, type::String)
    @assert type ∈ ["check", "statement", "solution"]

    statements = Int[]
    solutions = Int[]

    nb = Pluto.load_notebook(notebookfile)
    was_statement = false
    for (i, cell) in enumerate(nb.cells)
        tag = parse_split_tag(cell.code)
        if isnothing(tag)
            if was_statement
                error("Expected statement or solution cell to follow statement cell $(cell.code).")
            else
                continue
            end
        end
        check_fold(tag, cell)
        was_statement = tag.kind == "statement"
        push!(was_statement ? statements : solutions, i)
        # TODO: check that exactly one set of cells is disabled?
    end
    if was_statement
        error("Last cell was a statement cell, expected a solution cell afterwards.")
    end

    if type == "check"
        @info "Notebook $(notebookfile) is a valid splittable notebooks. Statements: $(length(statements)). Solutions: $(length(solutions))."
        return
    end

    to_remove = type == "statement" ? solutions : statements
    to_enable = type == "statement" ? statements : solutions

    for i in to_enable
        Pluto.set_disabled(nb.cells[i], false)
        nb.cells[i].code = strip_tag(nb.cells[i].code)
    end

    for i in reverse(to_remove)
        delete_cell_at(nb, i)
    end

    basename, ext = splitext(notebookfile)
    splitnotebookfile = "$(basename)_$type$ext"
    Pluto.save_notebook(nb, splitnotebookfile)

    @info "Successfully split notebook to $(splitnotebookfile)."
end

end # module PlutoSplitter
