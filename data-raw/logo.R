# Build the flreefs hex logo: a Reef Ball with a common sea fan
# (Gorgonia ventalina) growing behind it. Writes man/figures/logo.png.

set.seed(1970)

# Sea fan: a planar, recursively branching colony spreading upward.
branch <- function(x, y, angle, len, depth) {
  x_end <- x + len * cos(angle)
  y_end <- y + len * sin(angle)
  seg <- data.frame(
    x = x, y = y, x_end = x_end, y_end = y_end, depth = depth
  )
  if (depth == 0) {
    return(seg)
  }
  spread <- stats::runif(2, 0.1, 0.3)
  rbind(
    seg,
    branch(x_end, y_end, angle + spread[1], len * 0.84, depth - 1),
    branch(x_end, y_end, angle - spread[2], len * 0.84, depth - 1)
  )
}

# A short stalk, then primary branches radiating out like a hand.
stalk <- data.frame(x = 0.2, y = 0.97, x_end = 0.2, y_end = 1.1, depth = 8)
fan <- do.call(rbind, c(
  list(stalk),
  lapply(seq(20, 160, length.out = 7) * pi / 180, function(a) {
    branch(0.2, 1.1, a, 0.27, 6)
  })
))

# Sea fans are a mesh, not a tree: join each fine branch end to its
# nearest neighbour.
tips <- fan[fan$depth <= 3, c("x_end", "y_end")]
d <- as.matrix(stats::dist(tips))
diag(d) <- Inf
nn <- apply(d, 1, which.min)
mesh <- data.frame(
  x = tips$x_end, y = tips$y_end,
  x_end = tips$x_end[nn], y_end = tips$y_end[nn]
)
mesh <- mesh[d[cbind(seq_along(nn), nn)] < 0.15, ]

# Reef Ball: front of a hemisphere, holes projected as ellipses.
dome_t <- seq(0, pi, length.out = 200)
dome <- data.frame(x = cos(dome_t), y = sin(dome_t))

hole <- function(lon, lat, r, id) {
  cx <- cos(lat) * sin(lon)
  cy <- sin(lat)
  cz <- cos(lat) * cos(lon)
  norm <- sqrt(cx^2 + cy^2)
  u_rad <- c(cx, cy) / norm
  u_perp <- c(-u_rad[2], u_rad[1])
  t <- seq(0, 2 * pi, length.out = 60)
  data.frame(
    x = cx + r * cos(t) * u_perp[1] + r * cz * sin(t) * u_rad[1],
    y = cy + r * cos(t) * u_perp[2] + r * cz * sin(t) * u_rad[2],
    id = id
  )
}

deg <- pi / 180
hole_grid <- rbind(
  data.frame(lon = c(-60, -20, 20, 60), lat = 16),
  data.frame(lon = c(-40, 0, 40), lat = 44),
  data.frame(lon = 0, lat = 72)
)
holes <- do.call(rbind, lapply(seq_len(nrow(hole_grid)), function(i) {
  hole(hole_grid$lon[i] * deg, hole_grid$lat[i] * deg, 0.14, i)
}))

# Sand: a low lens-shaped mound under the ball.
sand_t <- seq(-1.5, 1.5, length.out = 100)
sand_h <- sqrt(1 - (sand_t / 1.5)^2)
sand <- data.frame(
  x = c(sand_t, rev(sand_t)),
  y = c(0.07 * sand_h, rev(-0.2 * sand_h))
)

# Pointy-top hexagon sized to the standard 4.39 x 5.08 cm sticker.
hex_r <- 2.2
hex_cy <- 0.8
hex_t <- (90 + 60 * 0:5) * deg
hex <- function(r) {
  data.frame(x = r * cos(hex_t), y = hex_cy + r * sin(hex_t))
}

water <- "#0b3d5c"
sand_col <- "#e8dcc0"

p <- ggplot2::ggplot() +
  ggplot2::geom_polygon(
    data = hex(hex_r * 0.97), ggplot2::aes(x = x, y = y),
    fill = water, colour = sand_col, linewidth = 2.2
  ) +
  ggplot2::geom_segment(
    data = fan,
    ggplot2::aes(
      x = x, y = y, xend = x_end, yend = y_end, linewidth = depth
    ),
    colour = "#b05fc4", lineend = "round"
  ) +
  ggplot2::geom_segment(
    data = mesh,
    ggplot2::aes(x = x, y = y, xend = x_end, yend = y_end),
    colour = "#b05fc4", linewidth = 0.12
  ) +
  ggplot2::geom_polygon(
    data = sand, ggplot2::aes(x = x, y = y), fill = sand_col
  ) +
  ggplot2::geom_polygon(
    data = dome, ggplot2::aes(x = x, y = y), fill = "#bdb6a8"
  ) +
  ggplot2::geom_polygon(
    data = holes, ggplot2::aes(x = x, y = y, group = id), fill = water
  ) +
  ggplot2::annotate(
    "text",
    x = 0, y = -0.72, label = "flreefs",
    colour = "#ffffff", size = 5.5, fontface = "bold"
  ) +
  ggplot2::scale_linewidth(range = c(0.12, 0.9), guide = "none") +
  ggplot2::coord_fixed(
    xlim = c(-1, 1) * hex_r * sqrt(3) / 2,
    ylim = hex_cy + c(-1, 1) * hex_r,
    expand = FALSE
  ) +
  ggplot2::theme_void()

dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

ggplot2::ggsave(
  "man/figures/logo.png", p,
  width = 4.39, height = 5.08, units = "cm", dpi = 300, bg = "transparent"
)
