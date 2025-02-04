module PlutoSplitter

import Pluto

function begin_occursin(code::String, kind::String)
    code_stripped = strip(code)
    if !occursin(Regex("#=\\s*begin\\s*$(kind)\\s*=#"), code_stripped)
        return false
    end
    if !occursin(Regex("^#=\\s*begin\\s*$(kind)\\s*=#"), code_stripped)
        error("Cell with contents $(code) contains a begin $kind tag, but not at the beginning of the cell!")
    end
    return true
end
function end_occursin(code::String, kind::String)
    code_stripped = strip(code)
    if !occursin(Regex("#=\\s*end\\s*$(kind)\\s*=#"), code_stripped)
        return false
    end
    if !occursin(Regex("#=\\s*end\\s*$(kind)\\s*=#\$"), code_stripped)
        error("Cell with contents $(code) contains an end $kind tag, but not at the end of the cell!")
    end
    return true
end

function strip_tags(code::String, kind::String)
    code_stripped = strip(code)
    code_stripped = replace(code_stripped, Regex("#=\\s*begin\\s*$(kind)\\s*=#") => "")
    code_stripped = replace(code_stripped, Regex("#=\\s*end\\s*$(kind)\\s*=#") => "")
    return strip(code_stripped)
end

function is_splittable(code::String, kind::String)
    is_begin = begin_occursin(code, kind)
    is_end = end_occursin(code, kind)
    if is_begin == is_end
        return is_begin
    end
    error("Cell with contents $(code) contains only a begin $kind or end $kind tag.")
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
    for i in 1:length(nb.cells)
        if was_statement
            if is_splittable(nb.cells[i].code, "solution")
                if nb.cells[i].code_folded
                    error("Solution cell $(nb.cells[i].code) is folded, but it should not be.")
                end
                push!(solutions, i)

                statement_enabled = !nb.cells[i-1].metadata["disabled"]
                solution_enabled = !nb.cells[i].metadata["disabled"]
                if statement_enabled == solution_enabled
                    error("Statement cell $(nb.cells[i-1].code) and solution cell $(nb.cells[i].code)"
                        * " have the same enabled status. Exactly one should be enabled.")
                end
            else
                error("Expected statement cell $(nb.cells[i-1].code) to be"
                    * " immediately followed by a solution cell,"
                    * " but it was followed by $(nb.cells[i].code)")
            end
            was_statement = false
        elseif is_splittable(nb.cells[i].code, "statement")
            if nb.cells[i].code_folded
                error("Statement cell $(nb.cells[i].code) is folded, but it should not be.")
            end
            push!(statements, i)
            was_statement = true
        elseif is_splittable(nb.cells[i].code, "solution")
            error("Expected solution cell $(nb.cells[i].code) to be"
                * " immediately preceded by a statement cell,"
                * " but it was preceded by $(nb.cells[i-1].code)")
        end
    end
    if was_statement
        error("Last cell was a statement cell, expected a solution cell afterwards.")
    end

    type == "check" && return

    to_remove = type == "statement" ? solutions : statements
    to_enable = type == "statement" ? statements : solutions

    for i in to_enable
        Pluto.set_disabled(nb.cells[i], false)
        nb.cells[i].code = strip_tags(nb.cells[i].code, type)
    end

    for i in reverse(to_remove)
        delete_cell_at(nb, i)
    end

    basename, ext = splitext(notebookfile)
    Pluto.save_notebook(nb, "$(basename)_$type$ext")
end

end # module PlutoSplitter
