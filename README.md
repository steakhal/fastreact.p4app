# P4-16 FastReact with match-action tables

DISCLAIMER: only a partial implementation of the paper called "[FastReact: In-Network Control and Caching for Industrial Control Networks using ProgrammableData Planes](https://arxiv.org/pdf/1808.06799.pdf)".
We took a different approach, using match-action tables instead of registers.
This implementation certainly needs some polishment.
## Setup

I've only tested this on Windows 10 Pro.

### Prerequiesets
 - Windows 10
 - Windows Subsystem For Linux 2 (aka. WSL2) [install guide](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
 - Docker Desktop (on Windows) [download](https://www.docker.com/products/docker-desktop)

### Steps

1. Clone/download the [p4app](https://github.com/p4lang/p4app) GitHub repository.
2. Append that repository to the `PATH` environment variable to let your consol find the p4app executable. You can do this by something like this: `export PATH="/path/to/the/p4app/:$PATH"`
3. Clone this repository containing our fastreact implementation.
4. Execute `p4app run .` from that folder.

You can probably see something going on, setting up the switch, and the network, using mininet.

5. Open two other WSL2 shells, one for the shell for the h1 node and the other for the h2 node.
6. Make sure those shells also have the `p4app` in the `PATH` envvar.
7. Run the `p4app exec m h1 bash` command from one and the `p4app exec m h2 bash` in the other opened shell.
8. Navigate to the `/tmp` folder in both shells.
9. Run the `python3 send.py` in one, and the `python3 receive.py` in the other shell.

You will probably see some packet communication.
The last byte of the message represents the result of the rule matching logic on the switch.

## Implementation logic

The user can define rules in the following form:
```
((id00 op00 constant00)^(id01 op01 constant01)^(id02 op02 constant02)^(id03 op03 constant03))v
((id10 op10 constant10)^(id11 op11 constant11)^(id12 op12 constant12)^(id13 op13 constant13))v
((id20 op20 constant20)^(id21 op21 constant21)^(id22 op22 constant22)^(id23 op23 constant23))
```
Each `id` is a sensor identifier, `op` a logical operation (except zero, which represents invalid operation) and a `constant` which we compare against.
These (3x4x3) integer values represent a rule. As an example `4 2 7 0 0 0 0 0 0 0 0 0   0 0 0 0 0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0 0 0 0 0` represents the expression `id4 <= 7`.
This rule is used in testing, where the rule table is populated by the `fastreact.config` file.

### Packet flow

Each non-sensor data packet simply forwarded to the requested destination.
Although sensor packets handled differently.

The switch will try to lookup a rule defined for the received packet's sensor ID.
If there is no rule bound to that sensor ID then the corresponding `result` byte will be created.
Otherwise, the corresponding rule will be evaluated.

During the evaluation of a rule, each variable referenced is resolved to the last cached sensor value. Note that at the beginning all sensor ID maps to zero since there was no previous measurement received by the switch.
The `result` will be populated accordingly, representing the `true` or `false` rule evaluation result.

The egress pipeline stage serves a single purpose, to populate the response headers using the acquired rule match information.

### Notes

This is a proof of concept implementation.
The switch could do different actions eg. sending the sensor data packet to the control plane etc.
For now we decided to simply forward the sensor packet without the sensor data - appending the rule evaluation result for debugging purposes.
