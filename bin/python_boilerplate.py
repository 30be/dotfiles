import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import subprocess
import io


def plot():
    buffer = io.BytesIO()
    plt.savefig(buffer, format="png")
    subprocess.Popen(["timg", "-"], stdin=subprocess.PIPE).communicate(
        buffer.getvalue()
    )
