export readtsv

function readtsv(f, path)
    doc = []
    sent = []
    lines = open(readlines, path)
    for line in lines
        line = chomp(line)
        if length(line) == 0
            length(sent) > 0 && push!(doc, sent)
            sent = []
        else
            items = split(line, '\t')
            push!(sent, f(items))
        end
    end
    length(sent) > 0 && push!(doc, sent)
    doc
end
