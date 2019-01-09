# <img src="Logo.svg" alt="Logo" height="76">

An app for exploring real-time audio performance on iOS devices.

<img src="Screenshot.png" alt="Screenshot" height="500">

# Requirements

* Xcode 10 and above
* iOS 12 and above
* iPhone 5s and above

# Visualizations and Controls

## Load

A graph of the amount of time taken to process each audio buffer as a percentage of the buffer duration. Drop-outs and intervals without audio processing are drawn in red.

The switch controls if the visualization is active. This can be used to freeze the graph in order to take a closer look. Drawing the visualization can sometimes impact the way audio threads are scheduled. Timing measurements are collected even when the visualization is disabled, so by briefly toggling the visualization off and on you can observe behavior without the confounding effect of drawing.

## Cores

A visualization of thread activity on each CPU core. Each row represents a core and each color represents an audio thread. On the iPhone 8, X, XS, and XR, the first four rows represent energy-efficient cores (Mistral/Tempest) and the last two rows represent high-performance cores (Monsoon/Vortex). The CoreAudio I/O thread is drawn in black.

## Energy

A graph of the estimated power consumption of the AudioPerLab process in watts. This can be used to compare the energy impact of different approaches for defeating core switching and frequency scaling (see the Minimum Load and Busy Threads sliders).

## Audio

### Buffer Size

The preferred buffer size. The actual buffer size is logged and may differ from the displayed value.

### Sine Waves

The number of sine waves to be processed by the audio threads.

### Burst Waves

Pressing ▶ triggers a short burst of a configurable number of sine waves.

## Threads

### Audio Threads

The total number of audio threads, including the CoreAudio I/O thread.

### Minimum Load

The minimum amount of time to spend processing as a percentage of the buffer duration. If real audio processing finishes before this time, then artificial processing is added via a low-energy yield instruction. No artificial processing is added if real processing exceeds this time. Artificial processing is added to all audio threads and is not shown in the load graph.

When the real audio load is low, adding artificial load tricks the OS into scheduling audio threads onto high-performance cores and increasing the clock-rate of those cores. This allows sudden load increases (e.g. the burst button) without drop-outs.

### Busy Threads

The number of busy background threads to create. Busy threads are low-priority threads that yield for 90% of the time and sleep for the rest.

For small buffer sizes (e.g. 128), adding a busy thread reduces the minimum load necessary in order for audio threads to be scheduled onto high-performance cores. The visualization has the same effect as a busy thread, so it must be disabled to observe this behavior.

### Driver Thread

The driver thread's mode.

#### Waits for Workers

The driver thread wakes up and waits for processing threads, but does not process sines itself. The total number of real-time threads (e.g., as shown in the Cores visualization) is one more than the "Process Threads" value (due to the driver thread).

The driver thread's automatically joined work interval is sometimes detrimental to performance. This mode can be used to avoid a work interval for all audio processing threads without calling a private API.

#### Processes Sines

The driver thread wakes up and waits for processing threads and processes sines as well. The total number of audio threads (e.g., as shown in the Cores visualization) is equal to the "Process Threads" value.

### Work Interval

When enabled, audio worker threads use a private API to join the [work interval](https://github.com/apple/darwin-xnu/blob/master/bsd/sys/work_interval.h) used by the CoreAudio I/O thread.

This appears to lower the amount of load necessary before the scheduler uses a high-performance core and reduces the amount of thread switching between cores.
