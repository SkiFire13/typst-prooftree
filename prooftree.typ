#let prooftree(
  spacing: (
    horizontal: 1em,
    vertical: 0.5em,
    lateral: 0.5em,
  ),
  label: (
    // TODO: split offset into horizontal and vertical
    offset: -0.1em,
    side: left,
    padding: 0.2em,
  ),
  line-stroke: 0.5pt,
  ..rules
) = context {
  // Check parameters and compute normalized settings
  let settings = {
    // Check basic validity of `rules`.
    if rules.pos().len() == 0 {
      panic("The `rules` argument cannot be empty.")
    }


    // Check the types of the parameters.
    assert(
      type(spacing) == "dictionary",
      message: "The value `" + repr(spacing) + "` of the `spacing` argument was expected"
        + "to have type `dictionary` but instead had type `" + type(spacing) + "`."
    )
    assert(
      type(label) == "dictionary",
      message: "The value `" + repr(label) + "` of the `label` argument was expected"
        + "to have type `dictionary` but instead had type `" + type(label) + "`."
    )
    assert(
      type(line-stroke) == "length",
      message: "The value `" + repr(line-stroke) + "` of the `line-stroke` argument was expected"
        + "to have type `length` but instead had type `" + type(line-stroke) + "`."
    )

    // Check validity of `spacing`'s keys.
    for (key, value) in spacing {
      if key not in ("horizontal", "vertical", "lateral", "h", "v", "l") {
        panic("The key `" + key + "` in the `spacing` argument `" + repr(spacing) + "` was not expected.")
      }
      if type(value) != "length" {
        panic(
          "The value `" + repr(value) + "` of the key `" + key + "` in the `spacing` argument `" + repr(spacing)
          + "` was expected to have type `length` but instead had type `" + type(value) + "`."
        )
      }
    }

    // Check exclusivity of `spacing`'s keys.
    let mutually_exclusive(key1, key2, keys) = {
      assert(
        key1 not in keys or key2 not in keys,
        message: "The keys `" + key1 + "` and `" + key2 + "` in the `spacing` argument `"
          + repr(spacing) + "` are mutually exclusive."
      )
    }
    mutually_exclusive("horizontal", "h", spacing.keys())
    mutually_exclusive("vertical", "v", spacing.keys())
    mutually_exclusive("lateral", "l", spacing.keys())
    
    // Check validity of `label`'s keys.
    let expected = ("offset": "length", "side": "alignment", "padding": "length")
    for (key, value) in label {
      if key not in expected {
        panic("The key `" + key + "` in the `label` argument `" + repr(label) + "` was not expected.")
      }
      if type(value) != expected.at(key) {
        panic(
          "The value `" + repr(value) + "` of the key `" + key + "` in the `label` argument `" + repr(label)
          + "` was expected to have type `" + type.at(key) + "` but instead had type `" + type(value) + "`."
        )
      }
    }
    if "side" in label {
      assert(
        label.side == left or label.side == right,
        message: "The value for the key `side` in the argument `label` can only be either "
          + "`left` (default) or `right`, but instead was `" + repr(label.side) + "`."
      )
    }

    (
      spacing: (
        horizontal: spacing.at("horizontal", default: spacing.at("h", default: 1.5em)).to-absolute(),
        vertical: spacing.at("vertical", default: spacing.at("v", default: 0.5em)).to-absolute(),
        lateral: spacing.at("lateral", default: spacing.at("l", default: 0.5em)).to-absolute(),
      ),
      label: (
        offset: label.at("offset", default: -0.1em).to-absolute(),
        side: label.at("side", default: left),
        padding: label.at("padding", default: 0.2em).to-absolute(),
      ),
      line-stroke: line-stroke.to-absolute(),
    )
  }

  // Holds the current "pending" rules, i.e. those without a parent
  let stack = ()
  // Holds all the measures
  let layouts = ()

  // First pass: compute the layout of each rule given the one of its children
  for (i, rule) in rules.pos().enumerate() {
    let to_pop = rule.__prooftree_to_pop
    let measure_func = rule.__prooftree_measure_func

    assert(
      to_pop <= stack.len(),
      message: "The rule `" + repr(rule.__prooftree_raw) + "` was expecting at least "
        + str(to_pop) + " rules in the stack, but only " + str(stack.len()) + " were present."
    )

    // Remove the children from the stack
    let children = stack.slice(stack.len() - to_pop)
    stack = stack.slice(0, stack.len() - to_pop)

    // Compute the layout and push
    let layout = measure_func(i, settings, children)
    stack.push(layout)
    layouts.push(layout)
  }

  assert(
    stack.len() == 1,
    message: "Some rule remained unmatched: " + str(stack.len()) + " roots were found but only 1 was expected."
  )

  let last = stack.pop()

  let content = {
    let offsets = range(rules.pos().len()).map(_ => (0pt, 0pt))

    // Second pass: backward draw each rule and compute offset of children
    for (i, rule) in rules.pos().enumerate().rev() {
      let (dx, dy) = offsets.at(i)
      let layout = layouts.at(i)

      // Update the offsets of the children
      for (j, cdx, cdy) in layout.at("children_offsets", default: ()) {
        offsets.at(j) = (dx + cdx, dy + cdy)
      }

      // Draw at the correct offset
      let draw_func = rule.__prooftree_draw_func
      place(left + bottom, dx: dx, dy: -dy, draw_func(settings, layout))
    }
  }

  block(width: last.width, height: last.height, content)
}

#let axiom(label: none, body) = {
  // Check arguments
  {
    // Check the type of `label`.
    assert(
      type(label) in ("string", "content", "none"),
      message: "The type of the `label` argument `" + repr(label) + "` was expected to be "
      + "`none`, `string` or `content` but was instead `" + type(label) + "`."
    )
  }

  // TODO: allow the label to be aligned on left, right or center (default and current).

  (
    __prooftree_raw: body,
    __prooftree_to_pop: 0,
    __prooftree_measure_func: (i, settings, children) => {
      // Compute the size of the body
      let body_size = measure(body)
      let body_width = body_size.width.to-absolute()
      let body_height = body_size.height.to-absolute()

      // Compute width of the base (including space)
      let base_width = body_width + 2 * settings.spacing.lateral

      // Update layout if a label is present
      let (width, height) = (base_width, body_height)
      let base_side = 0pt
      let (label_left, label_bottom) = (0pt, 0pt)
      if label != none {
        // Compute the size of the label
        let label_size = measure(label)
        let label_width = label_size.width
        let label_height = label_size.height
        
        // Update width and offsets from the left
        width = calc.max(base_width, label_width)
        base_side = (width - base_width) / 2
        label_left = (width - label_width) / 2

        // Compute bottom offset and update height
        label_bottom = height + 1.5 * settings.spacing.vertical
        height = label_bottom + label_height
      }

      return (
        index: i,
        width: width,
        height: height,
        base_left: base_side,
        base_right: base_side,
        main_left: base_side,
        main_right: base_side,

        // Extra for draw
        body_left: base_side + settings.spacing.lateral,
        label_left: label_left,
        label_bottom: label_bottom,
      )
    },
    __prooftree_draw_func: (settings, l) => {
      // Draw body
      place(left + bottom, dx: l.body_left, body)
      
      // Draw label
      if label != none {
        place(left + bottom, dx: l.label_left, dy: -l.label_bottom, label)
      }
    }
  )
}

#let rule(
  n: 1,
  label: none,
  root
) = {
  // Check arguments
  {
    // Check validity of the `n` parameter
    assert(
      type(n) == "integer",
      message: "The type of the `n` argument `" + repr(n) + "` was expected to be "
      + "`integer` but was instead `" + type(n) + "`."
    )

    // Check the type of `label`.
    assert(
      type(label) in ("string", "dictionary", "content", "none"),
      message: "The type of the `label` argument `" + repr(label) + "` was expected to be "
      + "`none`, `string`, `content` or `dictionary` but was instead `" + type(label) + "`."
    )
    // If the type of `label` was string then it's good, otherwise we need to check its keys.
    if type(label) == "dictionary" {
      for (key, value) in label {
        // TODO: maybe consider allowing `top`, `top-left` and `top-right` if `rule(n: 0)` gets changed.
        if key not in ("left", "right") {
          panic("The key `" + key + "` in the `label` argument `" + repr(label) + "` was not expected.")
        }
        if type(value) not in ("string", "content") {
          panic(
            "The value `" + repr(value) + "` of the key `" + key + "` in the `label` argument `" + repr(label)
            + "` was expected to have type `string` or `content` but instead had type `" + type(value) + "`."
          )
        }
      }
    }
  }

  (
    __prooftree_raw: root,
    __prooftree_to_pop: n,
    __prooftree_measure_func: (i, settings, children) => {
      let width(it) = measure(it).width.to-absolute()
      let height(it) = measure(it).height.to-absolute()

      let label = label
      if type(label) == "none" {
        label = (left: none, right: none)
      }
      if type(label) in ("string", "content") {
        label = (
          left: if settings.label.side == left { label } else { none },
          right: if settings.label.side == right { label } else { none }
        )
      }
      label = (
        left: label.at("left", default: none),
        right: label.at("right", default: none),
      )

      // Size of root
      let root_width = width(root)
      let root_height = height(root)

      // Width of base, which includes spacing as well
      let base_width = 2 * settings.spacing.lateral + root_width

      // Bottom offset of the line and children
      let line_bottom = root_height + settings.spacing.vertical
      let children_bottom = line_bottom + settings.spacing.vertical

      // Left/right offset of bases of extreme children
      let (child_base_left, child_base_right) = (0pt, 0pt)
      if n != 0 {
        child_base_left = children.first().base_left
        child_base_right = children.last().base_right
      }

      // Width and height of children, and width of their combined bases
      let children_width = children
        .map(c => c.width)
        .intersperse(settings.spacing.horizontal)
        .sum()
      let children_height = children.map(c => c.height).fold(0pt, calc.max)
      let children_base_width = children_width - child_base_left - child_base_right

      // Width of the line
      let line_width = calc.max(children_base_width, base_width)
      
      // Left/right offsets of lateral children main
      let (child_main_left, child_main_right) = (0pt, 0pt)
      if n != 0 {
        child_main_left = children.first().main_left
        child_main_right = children.last().main_right
      }

      // Offset of bases from line start (same for left/right)
      let base_from_line = (line_width - base_width) / 2
      let children_base_from_line = (line_width - children_base_width) / 2

      // Space for labels
      let (label_left_width, label_right_width) = (0pt, 0pt)
      let (label_left_height, label_right_height) = (0pt, 0pt)
      if label.left != none {
        label_left_width = width(label.left) + settings.label.padding
        label_left_height = height(label.left)
      }
      if label.right != none {
        label_right_width = width(label.right) + settings.label.padding
        label_right_height = height(label.right)
      }

      // Left/right offsets of line = max of labels and children main
      let line_left = calc.max(label_left_width, child_base_left - children_base_from_line)
      let line_right = calc.max(label_right_width, child_base_right - children_base_from_line)

      // Left/right offsets of base
      let base_left = line_left + base_from_line
      let base_right = line_right + base_from_line

      // Left/right offsets of children
      let children_left = line_left + children_base_from_line - child_base_left
      let children_right = line_right + children_base_from_line - child_base_right

      // Left/right offsets of main
      let main_left = calc.min(line_left, children_left + child_main_left)
      let main_right = calc.min(line_right, children_right + child_main_right)

      // Full width and height
      let width = line_left + line_width + line_right
      let height = children_bottom + children_height

      // Incrementally compute the relative offset of each child
      let children_offsets = ()
      for c in children {
        children_offsets.push((c.index, children_left, children_bottom))
        children_left += c.width + settings.spacing.horizontal
      }

      (
        index: i,
        width: width,
        height: height,
        base_left: base_left,
        base_right: base_right,
        main_left: main_left,
        main_right: main_right,
        children_offsets: children_offsets,

        // Extra for draw
        label: label,
        root_left: base_left + settings.spacing.lateral,
        line_left: line_left,
        line_bottom: line_bottom,
        line_width: line_width,
        label_left: line_left - label_left_width,
        label_right: line_left + line_width + settings.label.padding,
        label_left_bottom: root_height + settings.spacing.vertical + settings.line-stroke / 2 - label_left_height / 2 - settings.label.offset,
        label_right_bottom: root_height + settings.spacing.vertical + settings.line-stroke / 2 - label_right_height / 2 - settings.label.offset,
      )
    },
    __prooftree_draw_func: (settings, l) => {
      // Draw root content
      place(left + bottom, dx: l.root_left, root)
      
      // Draw line
      place(left + bottom, dx: l.line_left, dy: -l.line_bottom, line(length: l.line_width, stroke: settings.line-stroke))

      // Draw labels
      if l.label.left != none {
        place(left + bottom, dx: l.label_left, dy: -l.label_left_bottom, l.label.left)
      }
      if l.label.right != none {
        place(left + bottom, dx: l.label_right, dy: -l.label_right_bottom, l.label.right)
      }
    }
  )
}
