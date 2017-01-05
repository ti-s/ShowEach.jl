# ShowEach

[![Build Status](https://travis-ci.org/ti-s/ShowEach.jl.svg?branch=master)](https://travis-ci.org/ti-s/ShowEach.jl)

This package provides the `@showeach` macro which assists with poor man's debugging. In addition to `@show`ing the annotated expression, a tree of every subexpression is printed (unlike `@show`, printing literals is omitted). Thus, `@showeach` helps to understand what is going on in powerful one liners that occur frequently in Julia.

## Usage

Almost any valid Julia expression can be annotated with `@showeach`. For example,

```Julia
x = 1
y = 2
z = 3
g(x) = 2x
f(x, y) = x*y

@showeach z*f(g(x), y)
┌─ z = 3
│     ┌─ x = 1
│  ┌─ g(x) = 2
│  ├─ y = 2
├─ f(g(x),y) = 4
z * f(g(x),y) = 12

@showeach a*f(rand(z), g(y))[x]
┌─ a = [1,2,3]
│        ┌─ z = 3
│     ┌─ rand(z) = [0.516954,0.854899,0.636338]
│     │  ┌─ y = 2
│     ├─ g(y) = 4
│  ┌─ f(rand(z),g(y)) = [2.06781,3.4196,2.54535]
│  ├─ x = 1
├─ (f(rand(z),g(y)))[x] = 2.06781
a * (f(rand(z),g(y)))[x] = [2.06781,4.13563,6.20344]

@showeach sum(i for i = x:z if isodd(i))
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

Annotating a function definition prints every time the function is used, e.g.,

```Julia
@showeach h(x,y) = x*rand(y)

@showeach z*h(x, y)
┌─ z = 3
│  ┌─ x = 1
│  ├─ y = 2
│  ├─ in function h(x,y):
│  │     ┌─ x = 1
│  │     │  ┌─ y = 2
│  │     ├─ rand(y) = [0.4288,0.781806]
│  │     x * rand(y) = [0.4288,0.781806]
├─ h(x,y) = [0.4288,0.781806]
z * h(x,y) = [1.2864,2.34542]@showeach z*h(x, y)
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
