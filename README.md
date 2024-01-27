# Live For Speed Telemetry Recording and Display
This tool allows recording OutSim and OutGauge data using InSim triggers in Live For Speed, for complete laps as well as arbitrary durations.
It aims to add features to display and analyze said telemetry data. At this time, a very rough Python script generates some sample charts.

## Usage
This tool relies primarily on OutSim, which only sends packets when in cockpit view or custom view, so make sure to use one of these. It is also highly recommended to set the `OutSim Opts` to `1ff` in the `cfg.txt` file to record all possible data.

## Work in progress
Currently, data recording and saving to file works, but there are no visualization tools yet (apart from a Python script which creates matplotlib charts).
