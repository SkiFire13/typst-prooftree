#import "../prooftree.typ": *

#set text(font: "New Computer Modern", size: 12pt)

#prooftree(
  label-side: right,
  axiom("A1"),
  rule(label-left: "F-B", "B11111"),
  rule(label: "F-B", "B11"),
)

#prooftree(
  axiom("A1"),
  rule(label: "F-B", "B11"),
  rule(label: "F-B", "B11"),

  axiom("A1"),
  rule(label: "F-B", "B11"),
  rule(label: "F-B", "B11111"),
  rule(label: "F-B", "B111111111"),
  
  axiom("A1"),
  rule(label: "F-B", "B11111"),
  rule(label: "F-B", "B11"),

  rule(n: 3, "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz")
)
