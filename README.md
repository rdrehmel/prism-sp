# PRISM SP

This is the main repository for the Stream Processor (SP), a part of the larger PRISM project that focusses on processing data streams and interrupt request handling in the context of operating systems.
SP combines a Taiga processor core with custom coprocessor logic that interfaces to a GEM peripheral found on Xilinx Zynq UltraScale+ MPSoC chips.
The Taiga core sources were forked after commit _e8cd051c40817a88fa825f4ae7069c18ca057126_.
Because of the specific use case of the Stream Processor and the maturity of the Taiga core sources, it is expected that I will only merge important fixes from the Taiga core into the SP while the SP is under development.

The Taiga core was developed by Eric Matthews et al. at the Simon Fraser University.
See https://gitlab.com/sfu-rcl/Taiga, a repository which hosts the Taiga processor core.
Also see https://gitlab.com/sfu-rcl/taiga-project, a larger wrapper repository which imports the Taiga core, a preconfigured RISC-V toolchain/libraries and supplies scripts to build them.

For simplicity, all new SP code uses the same license (Apache 2.0) as the Taiga core.
