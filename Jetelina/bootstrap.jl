(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using Jetelina

# this const descri due to g5test
const UserApp = Jetelina

Jetelina.main()
