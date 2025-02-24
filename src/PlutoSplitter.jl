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

function check_enabled(should_be_enabled, cell)
    if Pluto.is_disabled(cell) == should_be_enabled
        error("Cell $(cell.code) should be $(should_be_enabled ? "enabled" : "disabled").")
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

- `notebookfile`: File to split.
- `type`: Type of splitting to perform.
        Can be "check" to only perform some sanity checks, "statement" or "solution".
        
Keyword arguments:
- `output_filename`, Optional: The filename to save the processed notebook at, by default `type` is appended to the original filename. `output_filename` can also be a function with two arguments, which will be passed `notebookfile` and `type` and should return the new filename as a String.
"""
function split_notebook(notebookfile, type::String; output_filename::Union{String, Function, Nothing}=nothing)
    @assert type ∈ ["check", "statement", "solution"]

    statements = Int[]
    solutions = Int[]

    nb = Pluto.load_notebook(notebookfile; disable_writing_notebook_files=true)

    for (i, cell) in enumerate(nb.cells)
        tag = parse_split_tag(cell.code)
        if isnothing(tag)
            continue
        end
        check_fold(tag, cell)
        push!((tag.kind == "statement") ? statements : solutions, i)
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

    if isnothing(output_filename)
        basename, ext = splitext(notebookfile)
        output_filename = "$(basename)_$type$ext"
    elseif output_filename isa Function
        output_filename = output_filename(notebookfile, type)
    end

    Pluto.save_notebook(nb, output_filename)

    @info "Successfully split notebook to $(output_filename)."
end

end # module PlutoSplitter
