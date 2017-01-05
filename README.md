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

julia> @showeach calc_pi(M) = 4 * sum(rand()^2 + rand()^2 < 1 for i = 1:M) / M

julia> calc_pi(5)
in function calc_pi(M):
         ┌─ M = 5
         │        ┌─ rand() = 0.0610889
         │     ┌─ rand() ^ 2 = 0.00373186
         │     │  ┌─ rand() = 0.899361
         │     ├─ rand() ^ 2 = 0.80885
         │  ┌─ rand() ^ 2 + rand() ^ 2 = 0.812582
         ├─ rand() ^ 2 + rand() ^ 2 < 1 = true
         │        ┌─ rand() = 0.818576
         │     ┌─ rand() ^ 2 = 0.670067
         │     │  ┌─ rand() = 0.161536
         │     ├─ rand() ^ 2 = 0.026094
         │  ┌─ rand() ^ 2 + rand() ^ 2 = 0.696161
         ├─ rand() ^ 2 + rand() ^ 2 < 1 = true
         │        ┌─ rand() = 0.869511
         │     ┌─ rand() ^ 2 = 0.756049
         │     │  ┌─ rand() = 0.773002
         │     ├─ rand() ^ 2 = 0.597532
         │  ┌─ rand() ^ 2 + rand() ^ 2 = 1.35358
         ├─ rand() ^ 2 + rand() ^ 2 < 1 = false
         │        ┌─ rand() = 0.110435
         │     ┌─ rand() ^ 2 = 0.0121959
         │     │  ┌─ rand() = 0.2395
         │     ├─ rand() ^ 2 = 0.0573603
         │  ┌─ rand() ^ 2 + rand() ^ 2 = 0.0695561
         ├─ rand() ^ 2 + rand() ^ 2 < 1 = true
         │        ┌─ rand() = 0.103921
         │     ┌─ rand() ^ 2 = 0.0107996
         │     │  ┌─ rand() = 0.831314
         │     ├─ rand() ^ 2 = 0.691083
         │  ┌─ rand() ^ 2 + rand() ^ 2 = 0.701883
         ├─ rand() ^ 2 + rand() ^ 2 < 1 = true
      ┌─ sum((rand() ^ 2 + rand() ^ 2 < 1 for i = 1:M)) = 4
   ┌─ 4 * sum((rand() ^ 2 + rand() ^ 2 < 1 for i = 1:M)) = 16
   ├─ M = 5
   (4 * sum((rand() ^ 2 + rand() ^ 2 < 1 for i = 1:M))) / M = 3.2
```

## Development

This package is in a very early stage of development and things can break any time. If you find a bug or simply have a question, just open an issue.
