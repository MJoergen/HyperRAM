import os
from pathlib import Path
from vunit import VUnit
from subprocess import call
from contextlib import suppress

VU = VUnit.from_argv(compile_builtins=False)
VU.add_vhdl_builtins()
VU.add_verilog_builtins()
VU.add_osvvm()
VU.add_verification_components()

print(VU.get_simulator_name())

# Get working directory
DIR_PATH = Path(__file__).parent

# Get source directory
SRC_PATH = (DIR_PATH / "../src/hyperram").resolve()

# Get testbench directory
TB_PATH = DIR_PATH / "test"

# Get hyperram device simulation model
HYPERRAM_SIMULATION_MODEL_PATH = (DIR_PATH / "../HyperRAM_Simulation_Model").resolve()

# Path(SRC_PATH) converts from string class to pathlib
lib = VU.add_library("src_lib")
lib.add_source_files(SRC_PATH / "*.vhd")

tb_lib = VU.add_library("tb_lib")
tb_lib.add_source_files(TB_PATH / "*.vhd")
tb_lib.add_source_files(HYPERRAM_SIMULATION_MODEL_PATH / "s27kl0642.v")


try:
    VU.main()
except SystemExit as exc:
    all_ok = exc.code == 0
