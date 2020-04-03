import os
import time
import argparse

from pynvml import *

def call_nvml(func, *args):
    try:
        return func(*args)
    except NVMLError:
        return None

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Export nvidia metrics to text file.')
    parser.add_argument('--path', type=str,
                        help='Path where to write the metrics')

    args = parser.parse_args()

    path = os.path.join(args.path, "nvidia_metrics.prom")

    nvmlInit()
    device_count = int(nvmlDeviceGetCount())
    while True:
        with open(path, 'w') as f:
            f.write(
                "# HELP: nvidia_device_count number of devices on this instance.\n")
            f.write("# TYPE: nvidia_device_count counter.\n")
            f.write('nvidia_device_count {0}\n'.format(device_count))

            for i in range(device_count):

                handle = nvmlDeviceGetHandleByIndex(i)
                name = nvmlDeviceGetName(handle).decode("utf-8")

                # Utilisation %
                util = call_nvml(nvmlDeviceGetUtilizationRates, handle)
                if util is not None:
                    f.write("# HELP: nvidia_utilization Card utilization (in %).\n")
                    f.write("# TYPE: gauge.\n")
                    f.write('nvidia_utilization{{name="{0}", gpu="{1}", type="gpu"}} {2}\n'.format(
                        name, i, util.gpu))
                    f.write('nvidia_utilization{{name="{0}", gpu="{1}", type="memory"}} {2}\n'.format(
                        name, i, util.memory))

                # Fan utilisation %
                fan_speed = call_nvml(nvmlDeviceGetFanSpeed, handle)
                if fan_speed is not None:
                    f.write("# HELP: nvidia_fan_speed Fan speed (in %).\n")
                    f.write("# TYPE: nvidia_fan_speed gauge.\n")
                    f.write('nvidia_fan_speed{{name="{0}", gpu="{1}"}} {2}\n'.format(
                        name, i, fan_speed))

                # Power statistics
                power_draw = call_nvml(nvmlDeviceGetPowerUsage, handle)
                if power_draw is not None:
                    f.write("# HELP: nvidia_power_draw Power draw (in W) .\n")
                    f.write("# TYPE: nvidia_power_draw gauge.\n")
                    f.write('nvidia_power_draw{{name="{0}", gpu="{1}"}} {2}\n'.format(
                        name, i, power_draw))

                power_limit = call_nvml(nvmlDeviceGetEnforcedPowerLimit, handle)
                if power_limit is not None:
                    f.write("# HELP: nvidia_power_limit Power limit (in W) .\n")
                    f.write("# TYPE: nvidia_power_limit gauge.\n")
                    f.write('nvidia_power_limit{{name="{0}", gpu="{1}"}} {2}\n'.format(
                        name, i, power_limit))

                # Throttling
                power_throttling = call_nvml(nvmlDeviceGetViolationStatus, handle, NVML_PERF_POLICY_POWER)
                if power_throttling is not None:
                    f.write(
                        "# HELP: nvidia_power_throttling Throttling duration due to power constraints (in us) .\n")
                    f.write("# TYPE: nvidia_power_throttling counter.\n")
                    f.write('nvidia_power_throttling{{name="{0}", gpu="{1}"}} {2}\n'.format(
                        name, i, power_throttling.violationTime))

                thermal_throttling = call_nvml(nvmlDeviceGetViolationStatus, handle, NVML_PERF_POLICY_THERMAL)
                if thermal_throttling is not None:
                    f.write(
                        "# HELP: nvidia_thermal_throttling Throttling duration due to thermal constraints (in us) .\n")
                    f.write("# TYPE: nvidia_thermal_throttling counter.\n")
                    f.write('nvidia_thermal_throttling{{name="{0}", gpu="{1}"}} {2}\n'.format(
                        name, i, thermal_throttling.violationTime))

                pcie_tx_throughput = call_nvml(nvmlDeviceGetPcieThroughput, handle, NVML_PCIE_UTIL_TX_BYTES)
                pcie_rx_throughput = call_nvml(nvmlDeviceGetPcieThroughput, handle, NVML_PCIE_UTIL_RX_BYTES)
                if pcie_tx_throughput is not None and pcie_rx_throughput is not None:
                    f.write(
                        "# HELP: nvidia_pcie_throughput Total number of bytes rx/tx through PCIe.\n")
                    f.write("# TYPE: nvidia_pcie_throughput gauge.\n")
                    f.write('nvidia_pcie_throughput{{name="{0}", gpu="{1}", type="tx"}} {2}\n'.format(
                        name, i, pcie_tx_throughput))
                    f.write('nvidia_pcie_throughput{{name="{0}", gpu="{1}", type="rx"}} {2}\n'.format(
                        name, i, pcie_rx_throughput))

                # Temperature
                temp = call_nvml(nvmlDeviceGetTemperature, handle, NVML_TEMPERATURE_GPU)
                if temp is not None:
                    f.write("# HELP: nvidia_temperature GPU temperature (in C) .\n")
                    f.write("# TYPE: nvidia_temperature gauge.\n")
                    f.write('nvidia_temperature{{name="{0}", gpu="{1}"}} {2}\n'.format(
                        name, i, temp))
                f.flush()
        time.sleep(10)
    nvmlShutdown()
