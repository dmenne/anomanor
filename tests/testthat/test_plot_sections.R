Sys.setenv("R_CONFIG_ACTIVE" = "test")
g = globals()
withr::defer(cleanup_test_data())

expected_names =
  c('duration','length','p min','p max','above base','t1','t2','pos1','pos2')


pos_data = structure(list(time = rep(395.1, 257), pos = c(-6.88,
-6.77, -6.65, -6.54, -6.43, -6.32, -6.21, -6.1, -5.99, -5.88,
-5.77, -5.66, -5.55, -5.43, -5.32, -5.21, -5.1, -4.99, -4.88,
-4.77, -4.66, -4.55, -4.44, 0.11, 0.22, 0.33, 0.44, 0.55, 0.67,
0.78, 0.89, 1, 1.11, 1.22, 1.33, 1.44, 1.55, 1.66, 1.77, 1.89,
2, 2.11, 2.22, 2.33, 2.44, 2.55, 2.66, 2.77, 2.88, 2.99, 3.11,
3.22, 3.33, 3.44, 3.55, 3.66, 3.77, 3.88, 3.99, 4.1, 4.21, 4.33,
4.44, 4.55, 4.66, 4.77, 4.88, 4.99, 5.1, 5.21, 5.32, 5.43, 5.55,
5.66, 5.77, 5.88, 5.99, 6.1, 6.21, 6.32, 6.43, 6.54, 6.65, 6.77,
6.88, 6.99, 7.1, 7.21, 7.32, 7.43, 7.54, 7.65, 7.76, 7.87, 7.99,
8.1, 8.21, 8.32, 8.43, 8.54, 8.65, 8.76, 8.87, 8.98, 9.09, 9.21,
9.32, 9.43, 9.54, 9.76, 9.87, 9.98, 10.09, 10.2, 10.31, 10.43,
10.54, 10.65, 10.76, 10.87, 10.98, 11.09, 11.2, 11.31, 11.42,
11.53, 11.65, 11.76, 11.87, 11.98, 12.09, 12.2, 12.31, 12.42,
12.53, 12.64, 12.75, 12.87, 12.98, 13.09, 13.2, 13.31, 13.42,
13.53, 13.64, 13.75, 13.86, 13.97, 14.09, 14.2, 14.31, 14.42,
14.53, 14.64, 14.75, 14.86, 14.97, 15.08, 15.19, 15.3, 15.42,
15.53, 15.64, 15.75, 15.86, 15.97, 16.08, 16.19, 16.3, 16.41,
16.52, 16.64, 16.75, 16.86, 16.97, 17.08, 17.19, 17.3, 17.41,
17.52, 17.63, 17.74, 17.86, 17.97, 18.08, 18.19, 18.3, 18.41,
18.52, 18.63, 18.74, 18.85, 18.96, 19.08, 19.19, 19.3, 19.41,
19.52, 19.63, 19.74, 19.85, 19.96, 20.07, 20.18, 20.3, 20.41,
20.52, 20.63, 20.74, 20.85, 20.96, 21.07, 21.18, 21.29, 21.4,
21.52, 21.63, 21.74, 21.85, 21.96, 22.07, 22.18, 22.29, 22.4,
22.51, 22.62, 22.74, 22.85, 22.96, 23.07, 23.18, 23.29, 23.4,
23.51, 23.62, 23.73, 23.84, 23.96, 24.07, 24.18, 24.29, 24.4,
24.51, 24.62, 24.73, 24.84, 24.95, 25.06, 25.18, 25.29, 25.4,
25.51, 25.62, 25.73, 25.84, 25.95, 26.06), press = c(50.1, 50.1,
50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1,
50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 50.1, 8.9,
8.7, 8.6, 8.4, 8.3, 8.1, 8, 7.9, 7.8, 7.6, 7.5, 7.4, 7.3, 7.2,
7.1, 7, 7, 6.9, 6.8, 6.7, 6.7, 6.6, 6.5, 6.5, 6.4, 6.4, 6.3,
6.3, 6.2, 6.2, 6.2, 6.2, 6.1, 6.1, 6.1, 6.1, 6.1, 6.1, 6.1, 6.1,
6.1, 6.1, 6.1, 6.1, 6.1, 6.1, 6.2, 6.2, 6.2, 6.3, 6.3, 6.3, 6.4,
6.4, 6.4, 6.5, 6.5, 6.6, 6.6, 6.7, 6.8, 6.8, 6.9, 6.9, 7, 7.1,
7.1, 7.2, 7.3, 7.4, 7.4, 7.5, 7.6, 7.7, 7.8, 7.8, 7.9, 8, 8.1,
8.2, 8.3, 8.3, 8.4, 8.5, 8.6, 8.7, 8.9, 9, 9, 9.1, 9.2, 9.3,
9.4, 9.5, 9.6, 9.6, 9.7, 9.8, 9.9, 10, 10.1, 10.1, 10.2, 10.3,
10.4, 10.4, 10.5, 10.6, 10.6, 10.7, 10.8, 10.8, 10.9, 10.9, 11,
11.1, 11.1, 11.1, 11.2, 11.2, 11.3, 11.3, 11.3, 11.4, 11.4, 11.4,
11.5, 11.5, 11.5, 11.5, 11.5, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6,
11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6,
11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6,
11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.6,
11.6, 11.6, 11.6, 11.6, 11.6, 11.6, 11.7, 11.7, 11.7, 11.7, 11.7,
11.8, 11.8, 11.8, 11.9, 11.9, 11.9, 12, 12, 12.1, 12.1, 12.2,
12.2, 12.3, 12.3, 12.4, 12.4, 12.5, 12.5, 12.6, 12.7, 12.7, 12.8,
12.9, 13, 13, 13.1, 13.2, 13.3, 13.4, 13.5, 13.5, 13.6, 13.7,
13.8, 13.9, 14, 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.9,
15, 15.1, 15.2, 15.3, 15.4, 15.6, 15.7, 15.8, 15.9), where = c("balloon",
"balloon", "balloon", "balloon", "balloon", "balloon", "balloon",
"balloon", "balloon", "balloon", "balloon", "balloon", "balloon",
"balloon", "balloon", "balloon", "balloon", "balloon", "balloon",
"balloon", "balloon", "balloon", "balloon", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor")), row.names = c(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L,
10L, 11L, 12L, 13L, 14L, 15L, 16L, 17L, 18L, 19L, 20L, 21L, 22L,
23L, 64L, 65L, 66L, 67L, 68L, 69L, 70L, 71L, 72L, 73L, 74L, 75L,
76L, 77L, 78L, 79L, 80L, 81L, 82L, 83L, 84L, 85L, 86L, 87L, 88L,
89L, 90L, 91L, 92L, 93L, 94L, 95L, 96L, 97L, 98L, 99L, 100L,
101L, 102L, 103L, 104L, 105L, 106L, 107L, 108L, 109L, 110L, 111L,
112L, 113L, 114L, 115L, 116L, 117L, 118L, 119L, 120L, 121L, 122L,
123L, 124L, 125L, 126L, 127L, 128L, 129L, 130L, 131L, 132L, 133L,
134L, 135L, 136L, 137L, 138L, 139L, 140L, 141L, 142L, 143L, 144L,
145L, 146L, 147L, 148L, 149L, 150L, 151L, 152L, 153L, 154L, 155L,
156L, 157L, 158L, 159L, 160L, 161L, 162L, 163L, 164L, 165L, 166L,
167L, 168L, 169L, 170L, 171L, 172L, 173L, 174L, 175L, 176L, 177L,
178L, 179L, 180L, 181L, 182L, 183L, 184L, 185L, 186L, 187L, 188L,
189L, 190L, 191L, 192L, 193L, 194L, 195L, 196L, 197L, 198L, 199L,
200L, 201L, 202L, 203L, 204L, 205L, 206L, 207L, 208L, 209L, 210L,
211L, 212L, 213L, 214L, 215L, 216L, 217L, 218L, 219L, 220L, 221L,
222L, 223L, 224L, 225L, 226L, 227L, 228L, 229L, 230L, 231L, 232L,
233L, 234L, 235L, 236L, 237L, 238L, 239L, 240L, 241L, 242L, 243L,
244L, 245L, 246L, 247L, 248L, 249L, 250L, 251L, 252L, 253L, 254L,
255L, 256L, 257L, 258L, 259L, 260L, 261L, 262L, 263L, 264L, 265L,
266L, 267L, 268L, 269L, 270L, 271L, 272L, 273L, 274L, 275L, 276L,
277L, 278L, 279L, 280L, 281L, 282L, 283L, 284L, 285L, 286L, 287L,
288L, 289L, 290L, 291L, 292L, 293L, 294L, 295L, 296L, 297L), class = "data.frame", balloon_press = 50.1)

time_data = structure(list(time = c(58.9, 59.1, 59.2, 59.4, 59.5, 59.6, 59.8,
59.9, 60.1, 60.2, 60.3, 60.5, 60.6, 60.8, 60.9, 61, 61.2, 61.3,
61.5, 61.6, 61.7, 61.9, 62, 62.2, 62.3, 62.4, 62.6, 62.7, 62.9,
63, 63.3, 63.4, 63.6, 63.7, 63.8, 64, 64.1, 64.3, 64.4, 64.5,
64.7, 64.8, 65, 65.1, 65.2, 65.4, 65.5, 65.7, 65.8, 65.9, 66.1,
66.2, 66.4, 66.5, 66.6, 66.8, 66.9, 67.1, 67.2), pos = c(32.27,
32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27,
32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27,
32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27,
32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27,
32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27,
32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27, 32.27,
32.27, 32.27, 32.27, 32.27), press = c(69.4, 69.3, 68.6, 67.7,
67.5, 68.4, 69, 68.3, 67.7, 68.6, 71, 74.1, 75.7, 74.5, 74.1,
78.2, 86.1, 96.2, 108.4, 122, 134.2, 142.5, 146.7, 147.9, 149.8,
154.8, 157.8, 153.9, 145.1, 134.7, 114.5, 107.2, 102.7, 97, 86.7,
75.9, 69.3, 66, 63.9, 62.1, 60, 57.9, 56.1, 54.5, 52.8, 51.2,
49.9, 49, 49, 49.6, 50.3, 51, 51.7, 52.7, 54.1, 55.5, 56.4, 56.9,
57.2), where = c("sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor", "sensor", "sensor",
"sensor", "sensor", "sensor", "sensor", "sensor")), row.names = c(NA,
59L), class = "data.frame", balloon_press = 2.4)

test_that("Plot vertical cross section returns table", {
  pdf(NULL)
  pos_tab = plot_position(pos_data, 100)
  dev.off()
  expect_s3_class(pos_tab, "data.frame")
  expect_equal(pos_tab$name, expected_names)
  expect_equal(colnames(pos_tab), c("name", "value", "unit"))
})


test_that("Vertical cross section plot", {
  pp = function() plot_position(pos_data, 100)
  vdiffr::expect_doppelganger("Vertical cross section", pp)
})

test_that("Horizontal cross section plot", {
  pp = function() plot_time(time_data, 200)
  vdiffr::expect_doppelganger("Horizontal cross section 200", pp)
  pp = function() plot_time(time_data, 300)
  vdiffr::expect_doppelganger("Horizontal cross section 300", pp)
})

test_that("Plot horizontal cross section returns table", {
  pdf(NULL)
  time_tab = plot_time(time_data, 200)
  dev.off()
  expect_s3_class(time_tab, "data.frame")
  expect_equal(time_tab$name, expected_names)
  expect_equal(colnames(time_tab), c("name", "value", "unit"))
})

