#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""

"""

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

data = pd.read_csv("~/.local/share/godot/app_userdata/LFS Telemetry/telemetry.csv", delimiter=",")


def setup_plot():
    ax = plt.gca()
    ax.set_xlabel("Time (s)")
    ax.legend()
    ax.minorticks_on()
    ax.grid(which="major")
    ax.grid(which="minor", alpha=0.2)
    ax.set_zorder(10)
    ax.patch.set_alpha(0)


def new_figure(figname, figsize):
    fig = plt.figure(figname, figsize)
    return fig


def plot_against_time(x_series, y_series, colors, labels):
    ax = plt.gca()
    for i in range(len(y_series)):
        ax.plot(x_series, y_series[i], color=colors[i], label=labels[i])
    ax.set_xlim([0, None])
    setup_plot()
    return ax


def plot_xy(x_series, y_series, colors, labels):
    ax = plt.gca()
    for i in range(len(y_series)):
        ax.plot(x_series, y_series[i], color=colors[i], label=labels[i])
    setup_plot()
    return ax


fig = new_figure(figname="Pos", figsize=[12, 6])
ax = plot_against_time(x_series=data["Time"],
                       y_series=[data["PosX"], data["PosY"], data["PosZ"]],
                       colors=["red", "green", "blue"], labels=["PosX", "PosY", "PosZ"])
ax.set_ylabel("Position (m)")
ax.set_title("Position")

fig = new_figure(figname="Vel", figsize=[12, 6])
ax = plot_against_time(x_series=data["Time"],
                       y_series=[data["VelX"], data["VelY"], data["VelZ"]],
                       colors=["red", "green", "blue"], labels=["VelX", "VelY", "VelZ"])
ax.set_ylabel("Velocity (m/s)")
ax.set_title("Velocity")
data["Speed"] = np.sqrt(data["VelX"]**2 + data["VelY"]**2 + data["VelZ"]**2) * 3.6
ax2 = ax.twinx()
ax2.plot(data["Time"], data["Speed"], label="Speed")

fig = new_figure(figname="Acc", figsize=[12, 6])
ax = plot_against_time(x_series=data["Time"],
                       y_series=[data["AccX"], data["AccY"], data["AccZ"]],
                       colors=["red", "green", "blue"], labels=["AccX", "AccY", "AccZ"])
ax.set_ylabel("Acceleration (m/s²)")
ax.set_title("Acceleration")

fig = new_figure(figname="Rot", figsize=[12, 6])
ax = plot_against_time(x_series=data["Time"],
                       y_series=[data["RotX"], data["RotY"], data["RotZ"]],
                       colors=["red", "green", "blue"], labels=["RotX", "RotY", "RotZ"])
ax.set_ylabel("Rotation (°)")
ax.set_title("Rotation")
setup_plot()

fig = new_figure(figname="AngVel", figsize=[12, 6])
ax = plot_against_time(x_series=data["Time"],
                       y_series=[data["AngVelX"], data["AngVelY"], data["AngVelZ"]],
                       colors=["red", "green", "blue"],
                       labels=["AngVelX", "AngVelY", "AngVelZ"])
ax.set_ylabel("Angular Velocity (°/s)")
ax.set_title("Angular Velocity")
setup_plot()

fig = new_figure(figname="TrackXY", figsize=[12, 6])
ax = plot_xy(x_series=data["PosX"], y_series=[data["PosY"]], colors=["red"], labels=["TrackXY"])
ax.set_aspect('equal', 'box')
ax.set_xlabel("PosX")
ax.set_ylabel("PosY")
ax.set_title("Path (XY)")

fig = new_figure(figname="TrackXZ", figsize=[12, 6])
ax = plot_xy(x_series=data["PosX"], y_series=[data["PosZ"]], colors=["red"], labels=["TrackXZ"])
ax.set_aspect('equal', 'box')
ax.set_xlabel("PosX")
ax.set_ylabel("PosZ")
ax.set_title("Path (XZ)")

fig = new_figure(figname="TrackYZ", figsize=[12, 6])
ax = plot_xy(x_series=data["PosY"], y_series=[data["PosZ"]], colors=["red"], labels=["TrackYZ"])
ax.set_aspect('equal', 'box')
ax.set_xlabel("PosY")
ax.set_ylabel("PosZ")
ax.set_title("Path (YZ)")

fig = new_figure(figname="3D Path", figsize=[12, 6])
ax = fig.add_subplot(projection="3d")
ax.scatter(data["PosX"], data["PosY"], data["PosZ"], c=data["Time"], cmap="plasma",
           label="3D Path", marker=".")
ax.set_title("3D Path")
ax.set_xlabel("X (m)")
ax.set_ylabel("Y (m)")
ax.set_zlabel("Z (m)")
ax.minorticks_on()
ax.grid(which="major")
ax.grid(which="minor", alpha=0.2)
x1, x2 = min(data["PosX"]), max(data["PosX"])
y1, y2 = min(data["PosY"]), max(data["PosY"])
z1, z2 = min(data["PosZ"]), max(data["PosZ"])
x0, y0, z0 = (x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2
max_range = max([x2 - x1, y2 - y1, z2 - z1]) / 2
ax.set_xlim(x0 - max_range, x0 + max_range)
ax.set_ylim(y0 - max_range, y0 + max_range)
ax.set_zlim(z0 - max_range, z0 + max_range)

fig = new_figure(figname="Track Path and Speed", figsize=[12, 6])
ax = plt.gca()
scatter = ax.scatter(data["PosX"], data["PosY"], c=data["Speed"], cmap="jet", label="Speed")
setup_plot()
ax.set_aspect('equal', 'box')
ax.set_xlabel("PosX")
ax.set_ylabel("PosY")
ax.set_title("Speed")
ax.legend(*scatter.legend_elements(), title="Speed")

fig = new_figure(figname="Input", figsize=[12, 6])
ax1 = plt.subplot(411)
ax1.set_title("Input")
ax1 = plot_against_time(data["Time"], [data["Throttle"], data["Brake"]], ["green", "red"],
                        ["Throttle", "Brake"])
ax1.set_ylabel("Throttle/Brake")
ax1.tick_params(labelbottom=False)
ax1.set_xlabel("")
ax2 = plt.subplot(412, sharex=ax1)
ax2 = plot_against_time(data["Time"], [data["TC"], data["ABS"]], ["green", "red"], ["TC", "ABS"])
ax2.set_ylabel("TC/ABS")
ax2.tick_params(labelbottom=False)
ax2.set_xlabel("")
ax3 = plt.subplot(413, sharex=ax1)
ax3 = plot_against_time(data["Time"], [data["Clutch"], data["HBrake"]], ["blue", "brown"],
                        ["Clutch", "HandBrake"])
ax3.set_ylabel("Clutch/HBrake")
ax3.tick_params(labelbottom=False)
ax3.set_xlabel("")
ax4 = plt.subplot(414, sharex=ax1)
ax4 = plot_against_time(data["Time"], [data["Steer"]], ["blue"], ["Steer"])
ax4.set_ylabel("Steering")

fig = new_figure(figname="RPM", figsize=[12, 6])
ax = plt.gca()
scatter = ax.scatter(data["Time"], data["RPM"], c=data["Gear"], cmap="jet", label="RPM")
setup_plot()
ax.set_ylabel("RPM")
ax.set_title("RPM")
ax.legend(*scatter.legend_elements(), title="Gear")
ax2 = ax.twinx()
ax2.plot(data["Time"], data["Speed"], label="Speed")
ax2.set_ylabel("Speed (km/h)")
ax2.set_ylim([0, None])

fig = new_figure(figname="Power and Torque", figsize=[12, 6])
ax = plt.gca()
ax.plot(data["Time"], data["RPM"], c="red", label="RPM")
setup_plot()
ax.set_ylabel("RPM", c="red")
ax.set_title("Power and Torque")
data["Power"] = data["RPM"] * data["Torque"] * 2 * np.pi / 60.0 / 1000.0
ax2 = ax.twinx()
ax2.plot(data["Time"], data["Power"] * data["Throttle"], c="green", label="Power")
ax2.plot(data["Time"], data["Power"], c="green", linestyle="--", label="Max Power", alpha=0.2)
ax2.set_ylabel("Power (kW)", c="green")
ax3 = ax.twinx()
ax3.plot(data["Time"], data["Torque"] * data["Throttle"], c="blue", label="Torque")
ax3.plot(data["Time"], data["Torque"], c="blue", linestyle="--", label="Max Torque", alpha=0.2)
ax3.set_ylabel("Torque (N.m)", c="blue")
ax3.spines.right.set_position(("axes", 1.08))

fig = new_figure(figname="Power/Torque Curve", figsize=[12, 6])
ax = plt.gca()
ax.plot(data["RPM"], data["Power"], c="red", label="Power")
setup_plot()
ax.set_xlabel("RPM")
ax.set_ylabel("Power (kW)", c="red")
ax.set_title("Power and Torque")
ax2 = ax.twinx()
ax2.plot(data["RPM"], data["Torque"], c="green", label="Torque")
ax2.set_ylabel("Torque (N.m)", c="green")

fig = new_figure(figname="Suspension", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLSusp"] * 1000, data["WRRSusp"] * 1000, data["WFLSusp"] * 1000,
              data["WFRSusp"] * 1000],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLSusp", "WRRSusp", "WFLSusp", "WFRSusp"])
ax.set_ylabel("Suspension Deflection (mm)")
ax.set_title("Suspension")

fig = new_figure(figname="Wheel Steer", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLSteer"] * 180 / np.pi, data["WRRSteer"] * 180 / np.pi,
              data["WFLSteer"] * 180 / np.pi, data["WFRSteer"] * 180 / np.pi],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLSteer", "WRRSteer", "WFLSteer", "WFRSteer"])
ax.set_ylabel("Wheel Steer (deg)")
ax.set_title("Wheel Steer")
setup_plot()

fig = new_figure(figname="Wheel LatForce", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLLat"] / 1000, data["WRRLat"] / 1000, data["WFLLat"] / 1000,
              data["WFRLat"] / 1000],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLLat", "WRRLat", "WFLLat", "WFRLat"])
ax.set_ylabel("Wheel LatForce (kN)")
ax.set_title("Wheel LatForce")
setup_plot()

fig = new_figure(figname="Wheel LonForce", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLLon"] / 1000, data["WRRLon"] / 1000, data["WFLLon"] / 1000,
              data["WFRLon"] / 1000],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLLon", "WRRLon", "WFLLon", "WFRLon"])
ax.set_ylabel("Wheel LonForce (kN)")
ax.set_title("Wheel LonForce")
setup_plot()

fig = new_figure(figname="Wheel Load", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLLoad"] / 1000, data["WRRLoad"] / 1000, data["WFLLoad"] / 1000,
              data["WFRLoad"] / 1000],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLLoad", "WRRLoad", "WFLLoad", "WFRLoad"])
ax.set_ylabel("Wheel Load (kN)")
ax.set_title("Wheel Load")
setup_plot()

fig = new_figure(figname="Wheel Velocity", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLVel"], data["WRRVel"], data["WFLVel"], data["WFRVel"]],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLVel", "WRRVel", "WFLVel", "WFRVel"])
ax.set_ylabel("Wheel Velocity (rad/s)")
ax.set_title("Wheel Velocity")
setup_plot()

fig = new_figure(figname="Wheel Lean", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLLean"] * 180 / np.pi, data["WRRLean"] * 180 / np.pi,
              data["WFLLean"] * 180 / np.pi, data["WFRLean"] * 180 / np.pi],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLLean", "WRRLean", "WFLLean", "WFRLean"])
ax.set_ylabel("Wheel Lean (deg)")
ax.set_title("Wheel Lean")
setup_plot()

fig = new_figure(figname="Air Temperature", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLTemp"], data["WRRTemp"], data["WFLTemp"], data["WFRTemp"]],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLTemp", "WRRTemp", "WFLTemp", "WFRTemp"])
ax.set_ylabel("Wheel Temperature (°C)")
ax.set_title("Wheel Temperature")
setup_plot()

fig = new_figure(figname="Wheel Contact", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLTouch"], data["WRRTouch"], data["WFLTouch"], data["WFRTouch"]],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLTouch", "WRRTouch", "WFLTouch", "WFRTouch"])
ax.set_ylabel("Wheel Contact")
ax.set_title("Wheel Contact")
setup_plot()

fig = new_figure(figname="Wheel Slip Fraction", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLSlipFrac"], data["WRRSlipFrac"], data["WFLSlipFrac"], data["WFRSlipFrac"]],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLSlipFrac", "WRRSlipFrac", "WFLSlipFrac", "WFRSlipFrac"])
ax.set_ylabel("Wheel Slip Fraction")
ax.set_title("Wheel Slip Fraction")
setup_plot()

fig = new_figure(figname="Wheel Slip Ratio", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLSlipRatio"], data["WRRSlipRatio"], data["WFLSlipRatio"],
              data["WFRSlipRatio"]],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLSlipRatio", "WRRSlipRatio", "WFLSlipRatio", "WFRSlipRatio"])
ax.set_ylabel("Wheel Slip Ratio")
ax.set_title("Wheel Slip Ratio")
setup_plot()

fig = new_figure(figname="Wheel Tangent Slip Angle", figsize=[12, 6])
ax = plot_against_time(
    x_series=data["Time"],
    y_series=[data["WRLTanSlip"], data["WRRTanSlip"], data["WFLTanSlip"], data["WFRTanSlip"]],
    colors=["red", "green", "blue", "yellow"],
    labels=["WRLTanSlip", "WRRTanSlip", "WFLTanSlip", "WFRTanSlip"])
ax.set_ylabel("Wheel Tangent Slip Angle")
ax.set_title("Wheel Tangent Slip Angle")
setup_plot()
