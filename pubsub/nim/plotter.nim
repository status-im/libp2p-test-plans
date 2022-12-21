import strutils
import ggplotnim

var
  time: seq[int]
  latency: seq[int]

for l in lines("/tmp/toto"):
  if "milliseconds" notin l: continue

  let splitted = l.split(" ")
  time.add(splitted[^3].parseInt)
  latency.add(splitted[^1].parseInt)

#var
#  time = @[0, 0, 0, 5, 5, 5, 9, 9]
#  latency = @[300, 500, 600, 100, 500, 600, 800, 900]

var df = toDf(time, latency)

let minTime = df["time", int].min

df = df
  .mutate(f{"time" ~ float(`time` - minTime) / 1000000000})
  .arrange("time").groupBy("time")
  .summarize(f{int: "amount" << int(size(col("latency")))},
        f{int -> int: "maxLatencies"  << max(col("latency"))},
        f{int -> int: "meanLatencies" << mean(col("latency"))},
        f{int -> int: "minLatencies"  << min(col("latency"))})

let
  maxLatency = df["maxLatencies", int].max
  maxTime = df["time", float].max
  maxAmount = df["amount", int].max
  factor = float(maxLatency) / float(maxAmount)

df = df.filter(f{`time` < maxTime - 3}).mutate(f{"scaled_amount" ~ `amount` * factor})

let sa = secAxis(name = "Reception count", trans = f{1.0 / factor})
ggplot(df, aes("time", "maxLatencies")) +
  geom_line(aes("time", y = "scaled_amount", color = "Amount")) +
  ylim(0, maxLatency) +
  legendPosition(0.8, -0.2) +
  scale_y_continuous(name = "Latency (ms)", secAxis = sa) +
  geom_line(aes("time", y = "maxLatencies", color = "Max")) +
  geom_line(aes("time", y = "meanLatencies", color = "Mean")) +
  geom_line(aes("time", y = "minLatencies", color = "Min")) +
  ggsave("test.svg", width = 640.0 * 2, height = 480 * 1.5)