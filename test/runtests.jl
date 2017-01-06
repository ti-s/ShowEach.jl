using ShowEach
using Base.Test

macro test_output(expr, output)
    quote
        origSTDOUT = STDOUT
        (rd, wr) = redirect_stdout()
        ShowEach.state.io = wr
        $(esc(expr))
        print(" ") # work around blocking of `readavailable` for empty pipe
        close(wr)
        expr_output = chop(String(readavailable(rd)))
        close(rd)
        redirect_stdout(origSTDOUT)
        ShowEach.state.io = origSTDOUT
        @test expr_output == $output
    end
end

# Some definitions for testing
type A{T} x::T end
a = [1,2,3]
x = 1
y = 2
z = 3
f(x, y) = x * y
g(z) = 2z
o = A(3)

set_loop_limit(20)

@test_output (@showeach 1) ""
@test_output (@showeach x) "x = 1\n"
@test_output (@showeach a += x) "x = 1\n"
@test_output (@showeach x + 1) """
┌─ x = 1
x + 1 = 2
"""
@test_output (@showeach a + 1) """
┌─ a = [2,3,4]
a + 1 = [3,4,5]
"""
@test_output (@showeach f(x, y)) """
┌─ x = 1
├─ y = 2
f(x,y) = 2
"""
@test_output (@showeach z*f(x,y)) """
┌─ z = 3
│  ┌─ x = 1
│  ├─ y = 2
├─ f(x,y) = 2
z * f(x,y) = 6
"""
@test_output (@showeach f(g(x), a[y])) """
   ┌─ x = 1
┌─ g(x) = 2
│  ┌─ a = [2,3,4]
│  ├─ y = 2
├─ a[y] = 3
f(g(x),a[y]) = 6
"""
@test_output (@showeach f.(a, [x,y,z])) """
┌─ a = [2,3,4]
├─ x = 1
├─ y = 2
├─ z = 3
f.(a,[x,y,z]) = [2,6,12]
"""
@test_output (@showeach o) """
o = A{Int64}(3)
"""
@test_output (@showeach g(o.x)) """
┌─ o.x = 3
g(o.x) = 6
"""
@test_output (@showeach g(A{Float64}(1).x)) """
┌─ A{Float64}(1).x = 1.0
g(A{Float64}(1).x) = 2.0
"""

myrand(x) = [0.159358,0.35803,0.791544]
@test_output (@showeach g.(myrand(3)[2])) """
   ┌─ myrand(3) = [0.159358,0.35803,0.791544]
┌─ (myrand(3))[2] = 0.35803
g.((myrand(3))[2]) = 0.71606
"""
@test_output (@showeach Dict(:a => 2, :b =>  3)[:a]) """
┌─ Dict(:a => 2,:b => 3) = Dict{Symbol,Int64} with 2 entries:
│                            :a => 2
│                            :b => 3
(Dict(:a => 2,:b => 3))[:a] = 2
"""
@test_output (@showeach sum(i for i = x:y if iseven(i))) """
┌─ x = 1
├─ y = 2
│  ┌─ i = 1
├─ iseven(i) = false
│  ┌─ i = 2
├─ iseven(i) = true
├─ i = 2
sum((i for i = x:y if iseven(i))) = 2
"""
@test_output (@showeach sum(i for i = x:y for j = i:z if iseven(i))) """
┌─ x = 1
├─ y = 2
├─ i = 1
├─ z = 3
│  ┌─ i = 1
├─ iseven(i) = false
│  ┌─ i = 1
├─ iseven(i) = false
│  ┌─ i = 1
├─ iseven(i) = false
├─ i = 2
├─ z = 3
│  ┌─ i = 2
├─ iseven(i) = true
│  ┌─ i = 2
├─ iseven(i) = true
├─ i = 2
├─ i = 2
sum((i for i = x:y for j = i:z if iseven(i))) = 4
"""
@test_output (@showeach A{Float64}) """
"""
@test_output (@showeach A{Float64}(1)) """
A{Float64}(1) = A{Float64}(1.0)
"""
@test_output (@showeach [i*j for i in x:y, j in eachindex(a)]) """
┌─ x = 1
├─ y = 2
│  ┌─ a = [2,3,4]
├─ eachindex(a) = Base.OneTo(3)
│  ┌─ i = 1
│  ├─ j = 1
├─ i * j = 1
│  ┌─ i = 2
│  ├─ j = 1
├─ i * j = 2
│  ┌─ i = 1
│  ├─ j = 2
├─ i * j = 2
│  ┌─ i = 2
│  ├─ j = 2
├─ i * j = 4
│  ┌─ i = 1
│  ├─ j = 3
├─ i * j = 3
│  ┌─ i = 2
│  ├─ j = 3
├─ i * j = 6
[i * j for i = x:y, j = eachindex(a)] = 2×3 Array{Int64,2}:
                                            1  2  3
                                            2  4  6
"""
@test_output (@showeach Float64[i*j for i in x:y, j in eachindex(a)]) """
┌─ x = 1
├─ y = 2
│  ┌─ a = [2,3,4]
├─ eachindex(a) = Base.OneTo(3)
│  ┌─ i = 1
│  ├─ j = 1
├─ i * j = 1
│  ┌─ i = 2
│  ├─ j = 1
├─ i * j = 2
│  ┌─ i = 1
│  ├─ j = 2
├─ i * j = 2
│  ┌─ i = 2
│  ├─ j = 2
├─ i * j = 4
│  ┌─ i = 1
│  ├─ j = 3
├─ i * j = 3
│  ┌─ i = 2
│  ├─ j = 3
├─ i * j = 6
Float64[i * j for i = x:y, j = eachindex(a)] = 2×3 Array{Float64,2}:
                                                   1.0  2.0  3.0
                                                   2.0  4.0  6.0
"""
@test_output (@showeach a[1] < x < b) """
┌─ x = 1
│  ┌─ a = [2,3,4]
├─ a[1] = 2
a[1] < x < b = false
"""
@test_output (@showeach f(x) = 2x) """
"""
@test_output f(2) """
in function f(x):
   ┌─ x = 2
   2x = 4
"""
@test_output (@showeach function h(x)
    a = 2x
    println("foo")
    a
end) """
"""
@test_output (h(x)) """
in function h(x):
   ┌─ x = 1
   2x = 2
foo
   println("foo") = nothing
   a = 2
"""
@test_output (@showeach f(x...) = x) """
"""
@test_output (@showeach f(a...)) """
┌─ a = [2,3,4]
├─ in function f(x...):
│     x = (2,3,4)
f(a...) = (2,3,4)
"""
@test_output (@showeach if x < 2 a else b end) """
┌─ x = 1
x < 2 = true
a = [2,3,4]
"""
# TODO: let blocks
@test_output (@showeach let x = 1
    y += 1
    x + y
end) """
"""
y = 3
@test_output (@showeach for i in x:y, j = a
            i*j
        end) """
┌─ x = 1
├─ y = 3
├─ a = [2,3,4]
│  ┌─ i = 1
│  ├─ j = 2
├─ i * j = 2
│  ┌─ i = 1
│  ├─ j = 3
├─ i * j = 3
│  ┌─ i = 1
│  ├─ j = 4
├─ i * j = 4
├─ a = [2,3,4]
│  ┌─ i = 2
│  ├─ j = 2
├─ i * j = 4
│  ┌─ i = 2
│  ├─ j = 3
├─ i * j = 6
│  ┌─ i = 2
│  ├─ j = 4
├─ i * j = 8
├─ a = [2,3,4]
│  ┌─ i = 3
│  ├─ j = 2
├─ i * j = 6
│  ┌─ i = 3
│  ├─ j = 3
├─ i * j = 9
│  ┌─ i = 3
│  ├─ j = 4
├─ i * j = 12
for ... end = nothing
"""
y = 2
@test_output (@showeach x < a[3] || error("Foo")) """
   ┌─ x = 1
   │  ┌─ a = [2,3,4]
   ├─ a[3] = 4
┌─ x < a[3] = true
x < a[3] || error("Foo") = true
"""
@test_output (@showeach x < a[3] && (x += 1)) """
   ┌─ x = 1
   │  ┌─ a = [2,3,4]
   ├─ a[3] = 4
┌─ x < a[3] = true
x < a[3] && (x += 1) = 2
"""
x = 1

@test_output (@showeach while x < z
    x += 1
end) """
   ┌─ x = 1
   ├─ z = 3
┌─ x < z = true
│  ┌─ x = 2
│  ├─ z = 3
├─ x < z = true
│  ┌─ x = 3
│  ├─ z = 3
├─ x < z = false
while ... end = nothing
"""
x = 1

@test_output (@showeach g(x)) """
┌─ x = 1
g(x) = 2
"""
@test_output (@showeach f(x,y)) """
┌─ x = 1
├─ y = 2
f(x,y) = 2
"""
@test_output (@showeach f(g(y), g(x))) """
   ┌─ y = 2
┌─ g(y) = 4
│  ┌─ x = 1
├─ g(x) = 2
f(g(y),g(x)) = 8
"""
@test_output (@showeach f(f(x), f(y))) """
   ┌─ x = 1
   ├─ in function f(x):
   │     ┌─ x = 1
   │     2x = 2
┌─ f(x) = 2
│  ┌─ y = 2
│  ├─ in function f(x):
│  │     ┌─ x = 2
│  │     2x = 4
├─ f(y) = 4
f(f(x),f(y)) = 8
"""
@test_output (@showeach function p(x, y)
           println("foo")
           ret = x*y
           println("bar")
           ret
       end) """
"""
a = [1,2,3]
@test_output (@showeach begin
       println("enter block")
       a*p(x,y)
       println("in block")
       z*p(x,y)
       println("end block")
   end) """
enter block
println("enter block") = nothing
┌─ a = [1,2,3]
│  ┌─ x = 1
│  ├─ y = 2
│  ├─ in function p(x,y):
foo
│  │     println("foo") = nothing
│  │     ┌─ x = 1
│  │     ├─ y = 2
│  │     x * y = 2
bar
│  │     println("bar") = nothing
│  │     ret = 2
├─ p(x,y) = 2
a * p(x,y) = [2,4,6]
in block
println("in block") = nothing
┌─ z = 3
│  ┌─ x = 1
│  ├─ y = 2
│  ├─ in function p(x,y):
foo
│  │     println("foo") = nothing
│  │     ┌─ x = 1
│  │     ├─ y = 2
│  │     x * y = 2
bar
│  │     println("bar") = nothing
│  │     ret = 2
├─ p(x,y) = 2
z * p(x,y) = 6
end block
println("end block") = nothing
"""

gather_stdout(true)
@test_output (@showeach begin
       println("enter block")
       a*p(x,y)
       println("in block")
       z*p(x,y)
       println("end block")
   end) """
println("enter block") = nothing
┌─ a = [1,2,3]
│  ┌─ x = 1
│  ├─ y = 2
│  ├─ in function p(x,y):
│  │     println("foo") = nothing
│  │     ┌─ x = 1
│  │     ├─ y = 2
│  │     x * y = 2
│  │     println("bar") = nothing
│  │     ret = 2
├─ p(x,y) = 2
a * p(x,y) = [2,4,6]
println("in block") = nothing
┌─ z = 3
│  ┌─ x = 1
│  ├─ y = 2
│  ├─ in function p(x,y):
│  │     println("foo") = nothing
│  │     ┌─ x = 1
│  │     ├─ y = 2
│  │     x * y = 2
│  │     println("bar") = nothing
│  │     ret = 2
├─ p(x,y) = 2
z * p(x,y) = 6
println("end block") = nothing
gathered STDOUT:
enter block
foo
bar
in block
foo
bar
end block
"""

set_loop_limit(6)
@test_output (@showeach p(x) = 2x) """
"""
@test_output (@showeach map(p, 1:100)) """
┌─ p = p (generic function with 2 methods)
├─ in function p(x):
│     ┌─ x = 1
│     2x = 2
├─ in function p(x):
│     ┌─ x = 2
│     2x = 4
├─ in function p(x):
│     ┌─ x = 3
│     2x = 6
├─ in function p(x):
│     ┌─ x = 4
│     2x = 8
├─ in function p(x):
│     ┌─ x = 5
│     2x = 10
├─  ⋮
map(p,1:100) = [2,4,6  …  196,198,200]
"""
@test_output (@showeach sum(i for i = 1:10 if isodd(i))) """
   ┌─ i = 1
┌─ isodd(i) = true
│  ┌─ i = 2
├─ isodd(i) = false
│  ┌─ i = 3
├─ isodd(i) = true
├─ i = 1
│  ┌─ i = 4
├─ isodd(i) = false
│  ┌─ i = 5
├─ isodd(i) = true
├─ i = 3
├─  ⋮
sum((i for i = 1:10 if isodd(i))) = 25
"""
