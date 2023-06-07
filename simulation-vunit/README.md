# Simulation

This folder contains files necessary to run an RTL simulation of the HyperRAM
implementation with Vunit simulator.

## Setting up Vunit

software prerequisites:
- python 3.6 or higher
- python module - [`vunit-hdl`](https://vunit.github.io/).
- `Modelsim`. **Note! Quartus and Lattice development tools are shipped with free version**

### Configuration Vunit in Ubuntu
- Add environment variables to your system as below (edit `bashrc`)
- `export VUNIT_MODELSIM_PATH="/tools/lscc/radiant/2022.1/modeltech/linuxloem/"` - path to Modelsim in your machine.
- `export VUNIT_SIMULATOR="modelsim"` - configure `Modlesim` as Vunit simulator. 

## Running simulation
Open `simulation-vunit` folder and type:
- `python run.py` - to run all available tests
- `python run.py --list` - list all available tests
- `python run.py tb_lib.hyperram_tb.bulk_write_bulk_read_operation` - run one specified test
- `python run.py --gui` - open and run tests in GUI.
