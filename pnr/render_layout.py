"""Render a LibreLane run's routing and power grid to a PNG, in KLayout batch mode.

Usage:
    klayout -b -r render_layout.py -rd run=<run directory> -rd png=<out.png>

The GDS and the PDK's KLayout layer properties come from the run's resolved
configuration, the same ones LibreLane's own KLayout steps used. Only metal 2
through 5 are shown: the cells and metal 1 cover the whole die at this scale
and hide the routing.
"""

import json
from pathlib import Path

import pya

# SkyWater 130 GDS layer and datatype of metal 2 through 5, drawing purpose
SHOWN_LAYERS = {(69, 20), (70, 20), (71, 20), (72, 20)}
IMAGE_SIDE_PIXELS = 1400

run_dir, png_path = Path(run), png  # noqa: F821, KLayout defines these from -rd
resolved_config = json.loads((run_dir / "resolved.json").read_text())
gds_path = run_dir / "final" / "gds" / f"{resolved_config['DESIGN_NAME']}.gds"

layout_view = pya.LayoutView()
layout_view.load_layout(str(gds_path), 0)
layout_view.max_hier()
layout_view.load_layer_props(resolved_config["KLAYOUT_PROPERTIES"])
layer_iterator = layout_view.begin_layers()
while not layer_iterator.at_end():
    layer_properties = layer_iterator.current()
    layer_properties.visible = (
        layer_properties.source_layer,
        layer_properties.source_datatype,
    ) in SHOWN_LAYERS
    layout_view.set_layer_properties(layer_iterator, layer_properties)
    layer_iterator.next()
layout_view.set_config("background-color", "#ffffff")
layout_view.zoom_fit()
layout_view.save_image(png_path, IMAGE_SIDE_PIXELS, IMAGE_SIDE_PIXELS)
