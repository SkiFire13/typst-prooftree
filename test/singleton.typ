#import "../prooftree.typ": *

// This proof is so big it doesn't fit in a normal page => resize the page for it
#show: content => style(styles => {
  let content = box(inset: 2em, content)
  let sizes = measure(content, styles)
  page(width: sizes.width, height: sizes.height, margin: 0pt, content)
})

#set text(font: "New Computer Modern", size: 12pt)

#let N1 = $"N"_1$
#let Id = $"Id"$
#let id = "id"
#let type = $italic("type")$
#let cont = $italic("cont")$
#let El = "El"

#let w1w2_cont = (
  axiom($[#h(3pt)] cont$),
  rule(label: "F-S", $N1 type [#h(3pt)]$),
  rule(label: "F-C", $w_1 in N1 cont$),
  rule(label: "F-S", $N1 type [w_1 in N1]$),
  rule(label: "F-C", $w_1 in N1, w_2 in N1 cont$),
)

#let w1w2z_cont = (
  ..w1w2_cont,
  rule(label: "F-S", $N1 type [w_1 in N1, w_2 in N1]$),
  rule(label: "F-C", $w_1 in N1, w_2 in N1, z in N1 cont$),
)

#prooftree(
    ..w1w2_cont,
    rule(label: "var", $w_2 in N1 [w_1 in N1, w_2 in N1]$),

      ..w1w2z_cont,
      rule(label: "F-S", $N1 type [w_1 in N1, w_2 in N1, z in N1]$),
      ..w1w2z_cont,
      rule(label: "var", $w_1 in N1 [w_1 in N1, w_2 in N1, z in N1]$),
      ..w1w2z_cont,
      rule(label: "var", $z in N1 [w_1 in N1, w_2 in N1, z in N1]$),
    rule(n: 3, label: "F-Id", $Id(N1, w_1, z) type [w_1 in N1, w_2 in N1, z in N1]$),

      ..w1w2_cont,
      rule(label: "var", $w_1 in N1 [w_1 in N1, w_2 in N1]$),
      
        ..w1w2z_cont,
        rule(label: "F-S", $N1 type [w_1 in N1, w_2 in N1, z in N1]$),
        ..w1w2z_cont,
        rule(label: "var", $z in N1 [w_1 in N1, w_2 in N1, z in N1]$),
        ..w1w2z_cont,
        rule(label: "I-S", $* in N1 [w_1 in N1, w_2 in N1, z in N1]$),
      rule(n: 3, label: "F-Id", $Id(N1, z, *) type [w_1 in N1, w_2 in N1, z in N1]$),
      
      ..w1w2_cont,
      rule(label: "I-S", $* in N1 [w_1 in N1, w_2 in N1]$),
      rule(label: "I-Id", $id(*) in Id(N1, *, *) [w_1 in N1, w_2 in N1]$),

    rule(n: 3, label: "E-S", $El_N1(w_1, id(*)) in Id(N1, w_1, *) [w_1 in N1, w_2 in N1]$),

  rule(n: 3, label: "E-S", $El_N1(w_2, El_N1(w_1, id(*)) in Id(N1, w_1, w_2) [w_1 in N1, w_2 in N1]$),
)
