#let prooftree(
  hspacing: 1.5em,
  pspacing: 0.5em,
  vspacing: 0.5em,
  label-offset: -0.1em,
  label-side: left,
  ..rules
) = {
  assert(
    label-side == left or label-side == right, 
    message: "The label side can only be left (default) or right"
  )

  style(styles => {
    let stack = ()
    let settings = (
      hspacing: hspacing,
      pspacing: pspacing,
      vspacing: vspacing,
      label-offset: label-offset,
      label-side: label-side,
    )

    for rule in rules.pos() {
      let to_pop = rule.__prooftree_to_pop
      let rule_func = rule.__prooftree_rule_func

      assert(to_pop <= stack.len(), message: "Not enough rules")

      let elem = rule_func(
        settings,
        styles,
        stack.slice(stack.len() - to_pop)
      )

      stack = stack.slice(0, stack.len() - to_pop)
      stack.push(elem)
    }

    assert(stack.len() == 1, message: "Not all rules were consumed")

    set align(start)
    set box(inset: 0pt, outset: 0pt)
    
    stack.pop().body
  })
}

#let rule(
  n: 1, 
  label: none, 
  label-left: none,
  label-right: none,
  root
) = (
  __prooftree_to_pop: n,
  __prooftree_rule_func: (settings, styles, children) => {
    let width(it) = measure(it, styles).width
    let height(it) = measure(it, styles).height
    let maxl(..lengths) = width(
      for length in lengths.pos() {
        line(length: length)
      }
    )
    let gtl(l1, l2) = maxl(l1, l2) != l2
    let minl(l1, l2) = if gtl(l1, l2) { l2 } else { l1 }
    
    let root = [ #h(settings.pspacing) #root #h(settings.pspacing) ]

    // Axiom case
    if n == 0 {
      let body = if label != none {
        // Labels stack on top of axioms
        stack(
          dir: ttb,
          spacing: 1.5 * vspacing,
          align(center, label),
          root
        )
      } else {
        root
      }

      return (
        body: body,
        label_wleft: 0pt,
        label_wright: 0pt,
        wleft: 0pt,
        wright: 0pt,
      )
    }

    // Map the children to a single block
    let branches = children.map(c => box(c.body)).join(h(settings.hspacing))

    // Calculate the offsets of the "inner" branches, i.e. ignoring branches' labels
    let wbranches_nolabel = width(branches) - children.first().label_wleft - children.last().label_wright
    let ibranches_offset = maxl(0pt, width(root) - wbranches_nolabel) / 2

    // Compute the start, end and length of the line to satisfy the "inner" branches
    let ib_line_start = ibranches_offset + children.first().wleft
    let ib_line_end = ibranches_offset + wbranches_nolabel - children.last().wright
    let ib_line_len = ib_line_end - ib_line_start

    // Pad the line length to satisfy the root too
    let line_len = maxl(ib_line_len, width(root))

    // Adjust the line start to account for the root padding
    let line_start = if gtl(ib_line_len, width(root)) {
      // No root padding
      ib_line_start
    } else if gtl(width(root), wbranches_nolabel) {
      // The "inner" branches are too tight
      0pt
    } else {
      // Weird, situation, we have `wbranches_nolabel > width(root) > ib_line_len`
      // The line should be adjusted so that it fits kinda in the middle
      // TODO: maybe this should also consider labels?
      let min_left = maxl(0pt, ib_line_end - line_len)
      let max_right = minl(maxl(wbranches_nolabel, width(root)), ib_line_start + line_len)
      (max_right + min_left) / 2 - line_len / 2
    }

    // Finish computing the offsets by considering the ignored left branches label
    let branches_offset = maxl(0pt, ibranches_offset - children.first().label_wleft)
    let line_start = line_start + (branches_offset + children.first().label_wleft - ibranches_offset)
    let root_offset = line_start + (line_len - width(root)) / 2

    // Compute body without the label.
    // This is needed later to calculate the sizes when placing the new labels.
    let body_nolabel = stack(
      dir: ttb,
      spacing: settings.vspacing,
      box(inset: (left: branches_offset), branches),
      line(start: (line_start, 0pt), length: line_len),
      box(inset: (left: root_offset), root),
    )

    // Decide which label to use
    let default_left_label = if settings.label-side == left { label } else { none }
    let default_right_label = if settings.label-side == right { label } else { none }
    let left_label = if label-left != none { label-left } else { default_left_label }
    let right_label = if label-right != none { label-right } else { default_right_label }

    // Pad the labels to separate them from the rule
    let left_label = box(inset: (right: 0.2em), left_label)
    let right_label = box(inset: (left: 0.2em), right_label)

    // Compute extra space the left label might need
    let new_left_space = maxl(0pt, width(left_label) - line_start)
    let left_label_width_offset = maxl(0pt, line_start - width(left_label))

    // Compute the width offset of the right label
    let right_label_width_offset = new_left_space + line_start + line_len

    // Compute the final width
    let final_width = maxl(
      right_label_width_offset + width(right_label), 
      new_left_space + width(body_nolabel)
    )

    // Place the label on top of the rest.
    // Note that this needs to fix the final dimensions in order to use `place`.
    let body = box(width: final_width, height: height(body_nolabel))[
      #set block(spacing: 0pt)
      #box(inset: (left: new_left_space), body_nolabel)
      #place(
        bottom + left,
        dx: left_label_width_offset,
        dy: settings.label-offset,
        box(height: 2 * (height(root) + settings.vspacing), align(horizon, left_label))
      )
      #place(
        bottom + left,
        dx: right_label_width_offset,
        dy: settings.label-offset,
        box(height: 2 * (height(root) + settings.vspacing), align(horizon, right_label))
      )
    ]

    // Compute the final sizes for the next rule
    let label_wleft = minl(
      new_left_space + branches_offset + children.first().label_wleft,
      left_label_width_offset + width(left_label)
    )
    let label_wright = minl(
      children.last().label_wright + (final_width - branches_offset - width(branches)),
      final_width - right_label_width_offset
    )
    let wleft = (new_left_space + root_offset) - label_wleft
    let wright = right_label_width_offset - (new_left_space + root_offset + width(root))

    (
      body: body,
      label_wleft: label_wleft,
      label_wright: label_wright,
      wleft: wleft,
      wright: wright,
    )
  }
)

#let axiom(label: none, body) = rule(n: 0, label: label, body)
