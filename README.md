# P4-16 FastReact with match-action tables

DISCLAIMER: only a partial implementation of the paper called "[FastReact: In-Network Control and Caching for Industrial Control Networks using ProgrammableData Planes](https://arxiv.org/pdf/1808.06799.pdf)".
We took a different approach, using match-action tables instead of registers.
This implementation is only proof of concept, for the practical application it needs to be further developed (see Notes)

## Setup

- only tested on Windows 10 Pro.

### Prerequisites
 - Windows 10
 - Windows Subsystem For Linux 2 (aka. WSL2) [install guide](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
 - Docker Desktop (on Windows) [download](https://www.docker.com/products/docker-desktop)

### Steps

1. Clone/download the [p4app](https://github.com/p4lang/p4app) GitHub repository `git clone https://github.com/p4lang/p4app`
2. Append that repository to the `PATH` environment variable to let your console find the p4app executable. You can do this by something like this: `export PATH="/path/to/the/p4app/:$PATH"`
3. Clone this repository containing our fastreact implementation `git clone https://github.com/steakhal/fastreact.p4app.git`
4. Execute `p4app run .` in this folder. The application will shortly set up the environment, including the switch and the network.
5. Open two separate WSL2 shells, for h1 and h2 nodes.
6. Make sure those shells also have the `p4app` in the `PATH` envvar.
7. Run `p4app exec m h1 bash` in the first and `p4app exec m h2 bash` in the second shell.
8. Navigate to the `/tmp` folder in both shells.
9. Run `python3 send.py` in the first and `python3 receive.py` in the second shell, whereas the first shell ships a packet towards the second. The last byte of the packet signs if the packet satisfied the switch-defined rule.

## Implementation logic

The user can define rules in conjunctive normal form:
```
((id00 op00 constant00)^(id01 op01 constant01)^(id02 op02 constant02)^(id03 op03 constant03))v
((id10 op10 constant10)^(id11 op11 constant11)^(id12 op12 constant12)^(id13 op13 constant13))v
((id20 op20 constant20)^(id21 op21 constant21)^(id22 op22 constant22)^(id23 op23 constant23))
```
where each triplet is consist of:
- a sensor identifier (`id`)
- a logical operation (`op`)
- and a constant value (`constant`)

Any triplet represent a literal, where we compare the sensor value to a constant (eg. S1 > 5, where S1 is the measured value by sensor 1)"
Any rows (consist of 4 triplets) represent a condition, any of the triplets evaluating true satisfies the condtion (eg. S1 > 5 ∨ S2 = 8)
The whole (3x4x3) integer values represent the rule, all of the conditions (represented by rows) needs to be fulfilled to satisfy the rule.
(triplet starting with 0 is invalid, represents empty literal and evaluates true always)
Take the example of `fastreact.config`, which is used for testing: `4 2 7 0 0 0 0 0 0 0 0 0   0 0 0 0 0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0 0 0 0 0`
these (3x4x3) integers represents the expression of `id4 <= 7`.

### Packet flow

Each non-sensor data packet forwarded to the requested destination as default.

If the packet carries a sensor value, the switch will try to look up a rule defined for the received packet's sensor ID.
If there is no rule bound to that sensor ID then the corresponding `result` byte will be created.
Otherwise, the corresponding rule will be evaluated.
During the evaluation of a rule, each `id` variable is resolved to the last cached value of the referenced sensor. (Note that at the beginning all sensor ID maps to zero since there was no previous measurement received by the switch)
The `result` will be populated accordingly, representing the `true` or `false` rule evaluation result.

The egress pipeline stage serves a single purpose, to populate the response headers using the acquired rule match information.

### Notes

The switch could perform different actions eg. sending the sensor data packet to the control plane etc.
The sensor packet is forwarded without the sensor data but with the `result` byte.
