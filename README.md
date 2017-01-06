# ShowEach

[![Build Status](https://travis-ci.org/ti-s/ShowEach.jl.svg?branch=master)](https://travis-ci.org/ti-s/ShowEach.jl)

This package provides the `@showeach` macro which assists with poor man's debugging. In addition to `@show`ing the annotated expression, a tree of every subexpression is printed (unlike `@show`, printing literals is omitted). Thus, `@showeach` helps to understand what is going on in powerful one liners that occur frequently in Julia.

## Usage

Almost any valid Julia expression can be annotated with `@showeach`. For example,

```Julia
julia> begin
          x = 1
          y = 2
          z = 3
          g(x) = 2x
          f(x, y) = x*y
       end

julia> @showeach z*f(g(x), y)
┌─ z = 3
│     ┌─ x = 1
│  ┌─ g(x) = 2
│  ├─ y = 2
├─ f(g(x),y) = 4
z * f(g(x),y) = 12

julia> @showeach a*f(rand(z), g(y))[x]
┌─ a = [1,2,3]
│        ┌─ z = 3
│     ┌─ rand(z) = [0.516954,0.854899,0.636338]
│     │  ┌─ y = 2
│     ├─ g(y) = 4
│  ┌─ f(rand(z),g(y)) = [2.06781,3.4196,2.54535]
│  ├─ x = 1
├─ (f(rand(z),g(y)))[x] = 2.06781
a * (f(rand(z),g(y)))[x] = [2.06781,4.13563,6.20344]

julia> @showeach sum(i for i = x:z if isodd(i))
┌─ x = 1
├─ z = 3
│  ┌─ i = 1
├─ isodd(i) = true
│  ┌─ i = 2
├─ isodd(i) = false
│  ┌─ i = 3
├─ isodd(i) = true
├─ i = 1
├─ i = 3
sum((i for i = x:z if isodd(i))) = 4
```

Annotating a function definition prints all subexpressions whithin the function's body every time the function is used, e.g.,

```Julia
julia> @showeach h(x,y) = x*rand(y)

julia> @showeach z*h(x, y)
┌─ z = 3
│  ┌─ x = 1
│  ├─ y = 2
│  ├─ in function h(x,y):
│  │     ┌─ x = 1
│  │     │  ┌─ y = 2
│  │     ├─ rand(y) = [0.4288,0.781806]
│  │     x * rand(y) = [0.4288,0.781806]
├─ h(x,y) = [0.4288,0.781806]
z * h(x,y) = [1.2864,2.34542]
```

The output is suppressed after `n` expressions have been printed at the same level of a tree:

```Julia
julia> @showeach f(x) = 2x

julia> @showeach map(f, 1:100)
┌─ f = f (generic function with 1 method)
├─ in function f(x):
│     ┌─ x = 1
│     2x = 2
├─ in function f(x):
│     ┌─ x = 2
│     2x = 4
├─ in function f(x):
│     ┌─ x = 3
│     2x = 6
├─ in function f(x):
│     ┌─ x = 4
│     2x = 8
├─ in function f(x):
│     ┌─ x = 5
│     2x = 10
├─  ⋮
map(f,1:100) = [2,4,6  …  196,198,200]
```
However, this only works within a `@showeach` expression. Calling `map(f, 1:100)` without `@showeach` will result in a long output. Unfortunately, due to a Julia issue, `@showeach map(i->2i, 1:100)` does not work yet. Instead, use a named function as above.

The maximum number of expressions can be set with `set_loop_limit(n-1)`:

```Julia
julia> @showeach calc_pi(M) = 4 * sum(rand()^2 + rand()^2 < 1 for i = 1:M) / M

julia> set_loop_limit(3)

julia> calc_pi(10^5)
in function calc_pi(M):
         ┌─ M = 100000
         │        ┌─ rand() = 0.841332
         │     ┌─ rand() ^ 2 = 0.707839
         │     │  ┌─ rand() = 0.164777
         │     ├─ rand() ^ 2 = 0.0271516
         │  ┌─ rand() ^ 2 + rand() ^ 2 = 0.734991
         ├─ rand() ^ 2 + rand() ^ 2 < 1 = true
         │        ┌─ rand() = 0.977022
         │     ┌─ rand() ^ 2 = 0.954572
         │     │  ┌─ rand() = 0.70994
         │     ├─ rand() ^ 2 = 0.504014
         │  ┌─ rand() ^ 2 + rand() ^ 2 = 1.45859
         ├─ rand() ^ 2 + rand() ^ 2 < 1 = false
         │        ┌─ rand() = 0.622204
         │     ┌─ rand() ^ 2 = 0.387138
         │     │  ┌─ rand() = 0.349908
         │     ├─ rand() ^ 2 = 0.122436
         │  ┌─ rand() ^ 2 + rand() ^ 2 = 0.509574
         ├─ rand() ^ 2 + rand() ^ 2 < 1 = true
         ├─  ⋮
      ┌─ sum((rand() ^ 2 + rand() ^ 2 < 1 for i = 1:M)) = 78498
   ┌─ 4 * sum((rand() ^ 2 + rand() ^ 2 < 1 for i = 1:M)) = 313992
   ├─ M = 100000
   (4 * sum((rand() ^ 2 + rand() ^ 2 < 1 for i = 1:M))) / M = 3.13992
```

## Caveats
- `@showeach` does not produce a correct output with anonymous functions, `let` blocks, and other macros. Nevertheless, the return values of such expressions should be correct.
- If an expression throws an error, the indentation is *not* reset automatically and one has to call `reset_indent()` manually.
- The `loop_limit` suppresses any output even outside loops. This will be improved in the future.


## Development

This package is in an early stage of development and things can break any time. If you find a bug or simply have a question, just open an issue.
