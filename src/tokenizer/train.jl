function train(t::Tokenizer, path)
  train_x, train_y = readdata(t, path)
  test_x = train_x
  test_y = map(y -> y.value, train_y)
  opt = SGD(0.0001)
  for epoch = 1:50
    println("epoch: $(epoch)")
    loss = fit(x -> t.nn(:x=>x), crossentropy, opt, train_x, train_y)
    println("loss: $(loss)")
    zs = map(x -> decode(t,x), test_x)
    acc = accuracy(test_y, zs)
    println("test acc.: $(acc)")
    println("")
  end
  println("training finish.")
end
