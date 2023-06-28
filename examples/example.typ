#import "../prooftree.typ": *

#show: content => style(styles => {
  let content = box(inset: 2em, content)
  let sizes = measure(content, styles)
  page(width: sizes.width, height: sizes.height, margin: 0pt, content)
})
#set text(font: "New Computer Modern", size: 12pt)

#prooftree(
  axiom("A"),
  rule("B"),
  axiom("C"),
  rule(n: 2, "D"),
  axiom("E"),
  axiom("F"),
  rule(n: 2, "G"),
  rule("H"),
  rule(n: 2, "I")
)
