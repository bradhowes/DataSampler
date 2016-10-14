//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

protocol A {}

protocol B: A {}

protocol C: A {}

struct S1: B {}
struct S2: C {}

let a = A.self
let b = B.self
let c = C.self

let types: [Any.Type] = [a, b, c]

let s1 = S1()
let s2 = S2()

s1 is S1
s1 is B
s1 is A

s1 is type(of: a)


type(of: s1) == b
type(of: s1) == c
type(of: s1) == S1.self
type(of: s1) == S2.self

let z = Mirror(reflecting: s1)
z.subjectType

Mirror(reflecting: z.subjectType).children.count





