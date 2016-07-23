
function sparsefeatures(s::State)
    b0 = tokenat(s, s.right)
    b1 = tokenat(s, s.right + 1)
    b2 = tokenat(s, s.right + 2)
    b3 = tokenat(s, s.right + 3)
    s0 = tokenat(s, s.top)
    s0l = tokenat(s, s.lchild)
    s0l2 = tokenat(s, :lsibl, :lchild)
    s0r = tokenat(s, s.rchild)
    s0r2 = tokenat(s, :rsibl, :rchild)
    s02l = tokenat(s, :lchild, :lchild)
    s12r = tokenat(s, :rchild, :rchild)
    s1 = tokenat(s, :left)
    s1l = tokenat(s, :left, :lchild)
    s1l2 = tokenat(s, :left, :lsibl, :lchild)
    s1r = tokenat(s, :left, :rchild)
    s1r2 = tokenat(s, :left, :rsibl, :rchild)
    s12l = tokenat(s, :left, :lchild, :lchild)
    s12r = tokenat(s, :left, :rchild, :rchild)
    s2 = tokenat(s, :left, :left)
    s3 = tokenat(s, :left, :left, :left)
    
    # labels
    s0rc_label = labelat(s, s.rchild)
    s0rc1_label = labelat(s, :rsibl, :rchild)
    s0lc_label
    s0lc1_label
    s02l_label
    s02r_label
    s1rc_label
    s1rc1_label
    s1lc_label
    s1lc1_label
    s12l_label
    s12r_label
end

s3 = @TokenAt left.left.left
s3 = begin
    s.left == nothing && return rootwoord
    s.left.left == nothing && return tokenat(s, s.left)
    s.left.left.left == nothing && return tokenat(s, s.left.left)
    return tokenat(s, s.left.left.left)
end
    

